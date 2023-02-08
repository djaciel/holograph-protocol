// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../abstract/Initializable.sol";

import {ERC721AUpgradeable} from "./lib/erc721a-upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "./lib/erc721a-upgradeable/IERC721AUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "./lib/openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {AccessControlUpgradeable} from "./lib/openzeppelin-contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "./lib/openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {MerkleProofUpgradeable} from "./lib/openzeppelin-contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

import {DropInitializer} from "../struct/DropInitializer.sol";

import {IHolographFeeManager} from "./interfaces/IHolographFeeManager.sol";
import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";
import {IOperatorFilterRegistry} from "./interfaces/IOperatorFilterRegistry.sol";
import {IHolographERC721Drop} from "./interfaces/IHolographERC721Drop.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";

import {OwnableSkeleton} from "./utils/OwnableSkeleton.sol";
import {FundsReceiver} from "./utils/FundsReceiver.sol";
import {PublicMulticall} from "./utils/PublicMulticall.sol";
import {ERC721DropStorageV1} from "./storage/ERC721DropStorageV1.sol";

/**
 * @notice HOLOGRAPH NFT contract for Drops and Editions
 *
 * @dev For drops: assumes 1. linear mint order, 2. max number of mints needs to be less than max_uint64
 *
 */
contract HolographERC721Drop is
  Initializable,
  ERC721AUpgradeable,
  IERC2981Upgradeable,
  ReentrancyGuardUpgradeable,
  AccessControlUpgradeable,
  IHolographERC721Drop,
  PublicMulticall,
  OwnableSkeleton,
  FundsReceiver,
  ERC721DropStorageV1
{
  /// @dev keep track of initialization state (Initializable)
  bool private _initialized;
  bool private _initializing;

  /// @dev This is the max mint batch size for the optimized ERC721A mint contract
  uint256 constant MAX_MINT_BATCH_SIZE = 8;

  /// @dev Gas limit to send funds
  uint256 constant FUNDS_SEND_GAS_LIMIT = 210_000;

  /// @notice Access control roles
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");
  bytes32 public constant SALES_MANAGER_ROLE = keccak256("SALES_MANAGER");

  /// @dev HOLOGRAPH transfer helper address for auto-approval
  address public holographERC721TransferHelper;

  /// @dev Holograph Fee Manager address
  IHolographFeeManager public holographFeeManager;

  /// @notice Max royalty BPS
  uint16 constant MAX_ROYALTY_BPS = 50_00;

  address public marketFilterAddress;

  IOperatorFilterRegistry public operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  /// @notice Only allow for users with admin access
  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      revert Access_OnlyAdmin();
    }

    _;
  }

  /// @notice Only a given role has access or admin
  /// @param role role to check for alongside the admin role
  modifier onlyRoleOrAdmin(bytes32 role) {
    if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) && !hasRole(role, _msgSender())) {
      revert Access_MissingRoleOrAdmin(role);
    }

    _;
  }

  /// @notice Allows user to mint tokens at a quantity
  modifier canMintTokens(uint256 quantity) {
    if (quantity + _totalMinted() > config.editionSize) {
      revert Mint_SoldOut();
    }

    _;
  }

  function _presaleActive() internal view returns (bool) {
    return salesConfig.presaleStart <= block.timestamp && salesConfig.presaleEnd > block.timestamp;
  }

  function _publicSaleActive() internal view returns (bool) {
    return salesConfig.publicSaleStart <= block.timestamp && salesConfig.publicSaleEnd > block.timestamp;
  }

  /// @notice Presale active
  modifier onlyPresaleActive() {
    if (!_presaleActive()) {
      revert Presale_Inactive();
    }

    _;
  }

  /// @notice Public sale active
  modifier onlyPublicSaleActive() {
    if (!_publicSaleActive()) {
      revert Sale_Inactive();
    }

    _;
  }

  constructor() {}

  /// @dev Initialize a new drop contract
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");

    // TODO: OZ Initializable pattern (review)
    _initialized = false;
    _initializing = true;

    DropInitializer memory initializer = abi.decode(initPayload, (DropInitializer));
    holographFeeManager = IHolographFeeManager(initializer.holographFeeManager);
    holographERC721TransferHelper = initializer.holographERC721TransferHelper;
    marketFilterAddress = initializer.marketFilterAddress;

    // Setup ERC721A
    // Call to ERC721AUpgradeable init has been replaced with the following
    // __ERC721A_init(initializer.contractName, initializer.contractSymbol);
    _name = initializer.contractName;
    _symbol = initializer.contractSymbol;
    _currentIndex = _startTokenId();

    // Setup AccessControl
    // TODO: OZ Initializable pattern. AccessControl does not set anything in _init_ (review)
    // Setup access control
    // __AccessControl_init();
    // Setup the owner role
    _setupRole(DEFAULT_ADMIN_ROLE, initializer.initialOwner);
    // Set ownership to original sender of contract call
    _setOwner(initializer.initialOwner);

    if (initializer.setupCalls.length > 0) {
      // Setup temporary role
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      // Execute setupCalls
      multicall(initializer.setupCalls);
      // Remove temporary role
      _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // TODO: OZ Initializable pattern. Need to initialize to _NOT_ENTERED (review)
    // Setup re-entracy guard
    // __ReentrancyGuard_init();

    if (config.royaltyBPS > MAX_ROYALTY_BPS) {
      revert Setup_RoyaltyPercentageTooHigh(MAX_ROYALTY_BPS);
    }

    // Setup config variables
    config.editionSize = initializer.editionSize;
    config.metadataRenderer = IMetadataRenderer(initializer.metadataRenderer);
    config.royaltyBPS = initializer.royaltyBPS;
    config.fundsRecipient = initializer.fundsRecipient;

    // TODO: Need to make sure to initialize the metadata renderer
    IMetadataRenderer(initializer.metadataRenderer).initializeWithData(initializer.metadataRendererInit);

    // TODO: OZ Initializable pattern (review)
    _initializing = false;
    _initialized = true;

    // Holograph initialization
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
  function _lastMintedTokenId() internal view returns (uint256) {
    return _currentIndex - 1;
  }

  /// @notice Start token ID for minting (1-100 vs 0-99)
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @dev Getter for admin role associated with the contract to handle metadata
  /// @return boolean if address is admin
  function isAdmin(address user) external view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, user);
  }

  //        ,-.
  //        `-'
  //        /|\
  //         |             ,----------.
  //        / \            |ERC721Drop|
  //      Caller           `----+-----'
  //        |       burn()      |
  //        | ------------------>
  //        |                   |
  //        |                   |----.
  //        |                   |    | burn token
  //        |                   |<---'
  //      Caller           ,----+-----.
  //        ,-.            |ERC721Drop|
  //        `-'            `----------'
  //        /|\
  //         |
  //        / \
  /// @param tokenId Token ID to burn
  /// @notice User burn function for token id
  function burn(uint256 tokenId) public {
    _burn(tokenId, true);
  }

  /// @dev Get royalty information for token
  /// @param _salePrice Sale price for the token
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    if (config.fundsRecipient == address(0)) {
      return (config.fundsRecipient, 0);
    }
    return (config.fundsRecipient, (_salePrice * config.royaltyBPS) / 10_000);
  }

  /// @notice Sale details
  /// @return IHolographERC721Drop.SaleDetails sale information details
  function saleDetails() external view returns (IHolographERC721Drop.SaleDetails memory) {
    return
      IHolographERC721Drop.SaleDetails({
        publicSaleActive: _publicSaleActive(),
        presaleActive: _presaleActive(),
        publicSalePrice: salesConfig.publicSalePrice,
        publicSaleStart: salesConfig.publicSaleStart,
        publicSaleEnd: salesConfig.publicSaleEnd,
        presaleStart: salesConfig.presaleStart,
        presaleEnd: salesConfig.presaleEnd,
        presaleMerkleRoot: salesConfig.presaleMerkleRoot,
        totalMinted: _totalMinted(),
        maxSupply: config.editionSize,
        maxSalePurchasePerAddress: salesConfig.maxSalePurchasePerAddress
      });
  }

  /// @dev Number of NFTs the user has minted per address
  /// @param minter to get counts for
  function mintedPerAddress(address minter)
    external
    view
    override
    returns (IHolographERC721Drop.AddressMintDetails memory)
  {
    return
      IHolographERC721Drop.AddressMintDetails({
        presaleMints: presaleMintsByAddress[minter],
        publicMints: _numberMinted(minter) - presaleMintsByAddress[minter],
        totalMints: _numberMinted(minter)
      });
  }

  /// @dev Setup auto-approval for marketplace access to sell NFT
  ///      Still requires approval for module
  /// @param nftOwner owner of the nft
  /// @param operator operator wishing to transfer/burn/etc the NFTs
  function isApprovedForAll(address nftOwner, address operator)
    public
    view
    override(ERC721AUpgradeable)
    returns (bool)
  {
    if (operator == holographERC721TransferHelper) {
      return true;
    }
    return super.isApprovedForAll(nftOwner, operator);
  }

  /// @dev Gets the holograph fee for amount of withdraw
  /// @param amount amount of funds to get fee for
  function holographFeeForAmount(uint256 amount) public returns (address payable, uint256) {
    (address payable recipient, uint256 bps) = holographFeeManager.getWithdrawFeesBps(address(this));
    return (recipient, (amount * bps) / 10_000);
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***     PUBLIC MINTING FUNCTIONS       ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                       ,----------.
  //                       / \                      |ERC721Drop|
  //                     Caller                     `----+-----'
  //                       |          purchase()         |
  //                       | ---------------------------->
  //                       |                             |
  //                       |                             |
  //          ___________________________________________________________
  //          ! ALT  /  drop has no tokens left for caller to mint?      !
  //          !_____/      |                             |               !
  //          !            |    revert Mint_SoldOut()    |               !
  //          !            | <----------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                             |
  //                       |                             |
  //          ___________________________________________________________
  //          ! ALT  /  public sale isn't active?        |               !
  //          !_____/      |                             |               !
  //          !            |    revert Sale_Inactive()   |               !
  //          !            | <----------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                             |
  //                       |                             |
  //          ___________________________________________________________
  //          ! ALT  /  inadequate funds sent?           |               !
  //          !_____/      |                             |               !
  //          !            | revert Purchase_WrongPrice()|               !
  //          !            | <----------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                             |
  //                       |                             |----.
  //                       |                             |    | mint tokens
  //                       |                             |<---'
  //                       |                             |
  //                       |                             |----.
  //                       |                             |    | emit IHolographERC721Drop.Sale()
  //                       |                             |<---'
  //                       |                             |
  //                       | return first minted token ID|
  //                       | <----------------------------
  //                     Caller                     ,----+-----.
  //                       ,-.                      |ERC721Drop|
  //                       `-'                      `----------'
  //                       /|\
  //                        |
  //                       / \
  /**
      @dev This allows the user to purchase/mint a edition
           at the given price in the contract.
     */
  function purchase(uint256 quantity)
    external
    payable
    nonReentrant
    canMintTokens(quantity)
    onlyPublicSaleActive
    returns (uint256)
  {
    uint256 salePrice = salesConfig.publicSalePrice;

    if (msg.value != salePrice * quantity) {
      revert Purchase_WrongPrice(salePrice * quantity);
    }

    // If max purchase per address == 0 there is no limit.
    // Any other number, the per address mint limit is that.
    if (
      salesConfig.maxSalePurchasePerAddress != 0 &&
      _numberMinted(_msgSender()) + quantity - presaleMintsByAddress[_msgSender()] >
      salesConfig.maxSalePurchasePerAddress
    ) {
      revert Purchase_TooManyForAddress();
    }

    _mintNFTs(_msgSender(), quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IHolographERC721Drop.Sale({
      to: _msgSender(),
      quantity: quantity,
      pricePerToken: salePrice,
      firstPurchasedTokenId: firstMintedTokenId
    });
    return firstMintedTokenId;
  }

  /// @notice Function to mint NFTs
  /// @dev (important: Does not enforce max supply limit, enforce that limit earlier)
  /// @dev This batches in size of 8 as per recommended by ERC721A creators
  /// @param to address to mint NFTs to
  /// @param quantity number of NFTs to mint
  function _mintNFTs(address to, uint256 quantity) internal {
    do {
      uint256 toMint = quantity > MAX_MINT_BATCH_SIZE ? MAX_MINT_BATCH_SIZE : quantity;
      _mint({to: to, quantity: toMint});
      quantity -= toMint;
    } while (quantity > 0);
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |         purchasePresale()         |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  drop has no tokens left for caller to mint?            !
  //          !_____/      |                                   |               !
  //          !            |       revert Mint_SoldOut()       |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  presale sale isn't active?             |               !
  //          !_____/      |                                   |               !
  //          !            |     revert Presale_Inactive()     |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  merkle proof unapproved for caller?    |               !
  //          !_____/      |                                   |               !
  //          !            | revert Presale_MerkleNotApproved()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  inadequate funds sent?                 |               !
  //          !_____/      |                                   |               !
  //          !            |    revert Purchase_WrongPrice()   |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | mint tokens
  //                       |                                   |<---'
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | emit IHolographERC721Drop.Sale()
  //                       |                                   |<---'
  //                       |                                   |
  //                       |    return first minted token ID   |
  //                       | <----------------------------------
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @notice Merkle-tree based presale purchase function
  /// @param quantity quantity to purchase
  /// @param maxQuantity max quantity that can be purchased via merkle proof #
  /// @param pricePerToken price that each token is purchased at
  /// @param merkleProof proof for presale mint
  function purchasePresale(
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  ) external payable nonReentrant canMintTokens(quantity) onlyPresaleActive returns (uint256) {
    if (
      !MerkleProofUpgradeable.verify(
        merkleProof,
        salesConfig.presaleMerkleRoot,
        keccak256(
          // address, uint256, uint256
          abi.encode(_msgSender(), maxQuantity, pricePerToken)
        )
      )
    ) {
      revert Presale_MerkleNotApproved();
    }

    if (msg.value != pricePerToken * quantity) {
      revert Purchase_WrongPrice(pricePerToken * quantity);
    }

    presaleMintsByAddress[_msgSender()] += quantity;
    if (presaleMintsByAddress[_msgSender()] > maxQuantity) {
      revert Presale_TooManyForAddress();
    }

    _mintNFTs(_msgSender(), quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IHolographERC721Drop.Sale({
      to: _msgSender(),
      quantity: quantity,
      pricePerToken: pricePerToken,
      firstPurchasedTokenId: firstMintedTokenId
    });

    return firstMintedTokenId;
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***     ADMIN OPERATOR FILTERING       ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /// @notice Proxy to update market filter settings in the main registry contracts
  /// @notice Requires admin permissions
  /// @param args Calldata args to pass to the registry
  function updateMarketFilterSettings(bytes calldata args) external onlyAdmin returns (bytes memory) {
    (bool success, bytes memory ret) = address(operatorFilterRegistry).call(args);
    if (!success) {
      revert RemoteOperatorFilterRegistryCallFailed();
    }
    return ret;
  }

  /// @notice Manage subscription for marketplace filtering based off royalty payouts.
  /// @param enable Enable filtering to non-royalty payout marketplaces
  function manageMarketFilterSubscription(bool enable) external onlyAdmin {
    address self = address(this);
    if (marketFilterAddress == address(0x0)) {
      revert MarketFilterAddressNotSupportedForChain();
    }
    if (!operatorFilterRegistry.isRegistered(self) && enable) {
      operatorFilterRegistry.registerAndSubscribe(self, marketFilterAddress);
    } else if (enable) {
      operatorFilterRegistry.subscribe(self, marketFilterAddress);
    } else {
      operatorFilterRegistry.unsubscribe(self, false);
      operatorFilterRegistry.unregister(self);
    }
  }

  /// @notice Hook to filter operators (no-op if no filters are registered)
  /// @dev Part of ERC721A token hooks
  /// @param from Transfer from user
  /// @param to Transfer to user
  /// @param startTokenId Token ID to start with
  /// @param quantity Quantity of token being transferred
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {
    if (from != msg.sender && address(operatorFilterRegistry).code.length > 0) {
      if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
        revert OperatorNotAllowed(msg.sender);
      }
    }
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***     ADMIN MINTING FUNCTIONS        ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |            adminMint()            |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  caller is not admin or minter role?    |               !
  //          !_____/      |                                   |               !
  //          !            | revert Access_MissingRoleOrAdmin()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  drop has no tokens left for caller to mint?            !
  //          !_____/      |                                   |               !
  //          !            |       revert Mint_SoldOut()       |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | mint tokens
  //                       |                                   |<---'
  //                       |                                   |
  //                       |    return last minted token ID    |
  //                       | <----------------------------------
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @notice Admin mint tokens to a recipient for free
  /// @param recipient recipient to mint to
  /// @param quantity quantity to mint
  function adminMint(address recipient, uint256 quantity)
    external
    onlyRoleOrAdmin(MINTER_ROLE)
    canMintTokens(quantity)
    returns (uint256)
  {
    _mintNFTs(recipient, quantity);

    return _lastMintedTokenId();
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |         adminMintAirdrop()        |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  caller is not admin or minter role?    |               !
  //          !_____/      |                                   |               !
  //          !            | revert Access_MissingRoleOrAdmin()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  drop has no tokens left for recipients to mint?        !
  //          !_____/      |                                   |               !
  //          !            |       revert Mint_SoldOut()       |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //                       |                    _____________________________________
  //                       |                    ! LOOP  /  for all recipients        !
  //                       |                    !______/       |                     !
  //                       |                    !              |----.                !
  //                       |                    !              |    | mint tokens    !
  //                       |                    !              |<---'                !
  //                       |                    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |    return last minted token ID    |
  //                       | <----------------------------------
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @dev Mints multiple editions to the given list of addresses.
  /// @param recipients list of addresses to send the newly minted editions to
  function adminMintAirdrop(address[] calldata recipients)
    external
    override
    onlyRoleOrAdmin(MINTER_ROLE)
    canMintTokens(recipients.length)
    returns (uint256)
  {
    uint256 atId = _currentIndex;
    uint256 startAt = atId;

    unchecked {
      for (uint256 endAt = atId + recipients.length; atId < endAt; atId++) {
        _mintNFTs(recipients[atId - startAt], 1);
      }
    }
    return _lastMintedTokenId();
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***  ADMIN CONFIGURATION FUNCTIONS     ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                    ,----------.
  //                       / \                   |ERC721Drop|
  //                     Caller                  `----+-----'
  //                       |        setOwner()        |
  //                       | ------------------------->
  //                       |                          |
  //                       |                          |
  //          ________________________________________________________
  //          ! ALT  /  caller is not admin?          |               !
  //          !_____/      |                          |               !
  //          !            | revert Access_OnlyAdmin()|               !
  //          !            | <-------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                          |
  //                       |                          |----.
  //                       |                          |    | set owner
  //                       |                          |<---'
  //                     Caller                  ,----+-----.
  //                       ,-.                   |ERC721Drop|
  //                       `-'                   `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @dev Set new owner for royalties / opensea
  /// @param newOwner new owner to set
  function setOwner(address newOwner) public onlyAdmin {
    _setOwner(newOwner);
  }

  /// @notice Set a new metadata renderer
  /// @param newRenderer new renderer address to use
  /// @param setupRenderer data to setup new renderer with
  function setMetadataRenderer(IMetadataRenderer newRenderer, bytes memory setupRenderer) external onlyAdmin {
    config.metadataRenderer = newRenderer;

    if (setupRenderer.length > 0) {
      newRenderer.initializeWithData(setupRenderer);
    }

    emit UpdatedMetadataRenderer({sender: _msgSender(), renderer: newRenderer});
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |      setSalesConfiguration()      |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  caller is not admin?                   |               !
  //          !_____/      |                                   |               !
  //          !            | revert Access_MissingRoleOrAdmin()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | set funds recipient
  //                       |                                   |<---'
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | emit FundsRecipientChanged()
  //                       |                                   |<---'
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @dev This sets the sales configuration
  /// @param publicSalePrice New public sale price
  /// @param maxSalePurchasePerAddress Max # of purchases (public) per address allowed
  /// @param publicSaleStart unix timestamp when the public sale starts
  /// @param publicSaleEnd unix timestamp when the public sale ends (set to 0 to disable)
  /// @param presaleStart unix timestamp when the presale starts
  /// @param presaleEnd unix timestamp when the presale ends
  /// @param presaleMerkleRoot merkle root for the presale information
  function setSaleConfiguration(
    uint104 publicSalePrice,
    uint32 maxSalePurchasePerAddress,
    uint64 publicSaleStart,
    uint64 publicSaleEnd,
    uint64 presaleStart,
    uint64 presaleEnd,
    bytes32 presaleMerkleRoot
  ) external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
    salesConfig.publicSalePrice = publicSalePrice;
    salesConfig.maxSalePurchasePerAddress = maxSalePurchasePerAddress;
    salesConfig.publicSaleStart = publicSaleStart;
    salesConfig.publicSaleEnd = publicSaleEnd;
    salesConfig.presaleStart = presaleStart;
    salesConfig.presaleEnd = presaleEnd;
    salesConfig.presaleMerkleRoot = presaleMerkleRoot;

    emit SalesConfigChanged(_msgSender());
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                    ,----------.
  //                       / \                   |ERC721Drop|
  //                     Caller                  `----+-----'
  //                       |        setOwner()        |
  //                       | ------------------------->
  //                       |                          |
  //                       |                          |
  //          ________________________________________________________
  //          ! ALT  /  caller is not admin or SALES_MANAGER_ROLE?    !
  //          !_____/      |                          |               !
  //          !            | revert Access_OnlyAdmin()|               !
  //          !            | <-------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                          |
  //                       |                          |----.
  //                       |                          |    | set sales configuration
  //                       |                          |<---'
  //                       |                          |
  //                       |                          |----.
  //                       |                          |    | emit SalesConfigChanged()
  //                       |                          |<---'
  //                     Caller                  ,----+-----.
  //                       ,-.                   |ERC721Drop|
  //                       `-'                   `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @notice Set a different funds recipient
  /// @param newRecipientAddress new funds recipient address
  function setFundsRecipient(address payable newRecipientAddress) external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
    if (newRecipientAddress == address(0)) {
      revert Admin_InvalidFundRecipientAddress(newRecipientAddress);
    }

    config.fundsRecipient = newRecipientAddress;
    emit FundsRecipientChanged(newRecipientAddress, _msgSender());
  }

  //                       ,-.                  ,-.                      ,-.
  //                       `-'                  `-'                      `-'
  //                       /|\                  /|\                      /|\
  //                        |                    |                        |                      ,----------.
  //                       / \                  / \                      / \                     |ERC721Drop|
  //                     Caller            FeeRecipient            FundsRecipient                `----+-----'
  //                       |                    |           withdraw()   |                            |
  //                       | ------------------------------------------------------------------------->
  //                       |                    |                        |                            |
  //                       |                    |                        |                            |
  //          ________________________________________________________________________________________________________
  //          ! ALT  /  caller is not admin or manager?                  |                            |               !
  //          !_____/      |                    |                        |                            |               !
  //          !            |                    revert Access_WithdrawNotAllowed()                    |               !
  //          !            | <-------------------------------------------------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    |                        |                            |
  //                       |                    |                   send fee amount                   |
  //                       |                    | <----------------------------------------------------
  //                       |                    |                        |                            |
  //                       |                    |                        |                            |
  //                       |                    |                        |             ____________________________________________________________
  //                       |                    |                        |             ! ALT  /  send unsuccesful?                                 !
  //                       |                    |                        |             !_____/        |                                            !
  //                       |                    |                        |             !              |----.                                       !
  //                       |                    |                        |             !              |    | revert Withdraw_FundsSendFailure()    !
  //                       |                    |                        |             !              |<---'                                       !
  //                       |                    |                        |             !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    |                        |             !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    |                        |                            |
  //                       |                    |                        | send remaining funds amount|
  //                       |                    |                        | <---------------------------
  //                       |                    |                        |                            |
  //                       |                    |                        |                            |
  //                       |                    |                        |             ____________________________________________________________
  //                       |                    |                        |             ! ALT  /  send unsuccesful?                                 !
  //                       |                    |                        |             !_____/        |                                            !
  //                       |                    |                        |             !              |----.                                       !
  //                       |                    |                        |             !              |    | revert Withdraw_FundsSendFailure()    !
  //                       |                    |                        |             !              |<---'                                       !
  //                       |                    |                        |             !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    |                        |             !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                     Caller            FeeRecipient            FundsRecipient                ,----+-----.
  //                       ,-.                  ,-.                      ,-.                     |ERC721Drop|
  //                       `-'                  `-'                      `-'                     `----------'
  //                       /|\                  /|\                      /|\
  //                        |                    |                        |
  //                       / \                  / \                      / \
  /// @notice This withdraws ETH from the contract to the contract owner.
  function withdraw() external nonReentrant {
    address sender = _msgSender();

    // Get fee amount
    uint256 funds = address(this).balance;
    (address payable feeRecipient, uint256 holographFee) = holographFeeForAmount(funds);

    // Check if withdraw is allowed for sender
    if (
      !hasRole(DEFAULT_ADMIN_ROLE, sender) &&
      !hasRole(SALES_MANAGER_ROLE, sender) &&
      sender != feeRecipient &&
      sender != config.fundsRecipient
    ) {
      revert Access_WithdrawNotAllowed();
    }

    // Payout HOLOGRAPH fee
    if (holographFee > 0) {
      (bool successFee, ) = feeRecipient.call{value: holographFee, gas: FUNDS_SEND_GAS_LIMIT}("");
      if (!successFee) {
        revert Withdraw_FundsSendFailure();
      }
      funds -= holographFee;
    }

    // Payout recipient
    (bool successFunds, ) = config.fundsRecipient.call{value: funds, gas: FUNDS_SEND_GAS_LIMIT}("");
    if (!successFunds) {
      revert Withdraw_FundsSendFailure();
    }

    // Emit event for indexing
    emit FundsWithdrawn(_msgSender(), config.fundsRecipient, funds, feeRecipient, holographFee);
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |       finalizeOpenEdition()       |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  caller is not admin or SALES_MANAGER_ROLE?             !
  //          !_____/      |                                   |               !
  //          !            | revert Access_MissingRoleOrAdmin()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //                       |                    _______________________________________________________________________
  //                       |                    ! ALT  /  drop is not an open edition?                                 !
  //                       |                    !_____/        |                                                       !
  //                       |                    !              |----.                                                  !
  //                       |                    !              |    | revert Admin_UnableToFinalizeNotOpenEdition()    !
  //                       |                    !              |<---'                                                  !
  //                       |                    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | set config edition size
  //                       |                                   |<---'
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | emit OpenMintFinalized()
  //                       |                                   |<---'
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @notice Admin function to finalize and open edition sale
  function finalizeOpenEdition() external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
    if (config.editionSize != type(uint64).max) {
      revert Admin_UnableToFinalizeNotOpenEdition();
    }

    config.editionSize = uint64(_totalMinted());
    emit OpenMintFinalized(_msgSender(), config.editionSize);
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***      GENERAL GETTER FUNCTIONS      ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /// @notice Simple override for owner interface.
  /// @return user owner address
  function owner() public view override(OwnableSkeleton, IHolographERC721Drop) returns (address) {
    return super.owner();
  }

  /// @notice Contract URI Getter, proxies to metadataRenderer
  /// @return Contract URI
  function contractURI() external view returns (string memory) {
    return config.metadataRenderer.contractURI();
  }

  /// @notice Getter for metadataRenderer contract
  function metadataRenderer() external view returns (IMetadataRenderer) {
    return IMetadataRenderer(config.metadataRenderer);
  }

  /// @notice Token URI Getter, proxies to metadataRenderer
  /// @param tokenId id of token to get URI for
  /// @return Token URI
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) {
      revert IERC721AUpgradeable.URIQueryForNonexistentToken();
    }

    return config.metadataRenderer.tokenURI(tokenId);
  }

  /// @notice ERC165 supports interface
  /// @param interfaceId interface id to check if supported
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165Upgradeable, ERC721AUpgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return
      super.supportsInterface(interfaceId) ||
      type(IOwnable).interfaceId == interfaceId ||
      type(IERC2981Upgradeable).interfaceId == interfaceId ||
      type(IHolographERC721Drop).interfaceId == interfaceId;
  }
}
