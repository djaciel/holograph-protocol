// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

import {NonReentrant} from "../abstract/NonReentrant.sol";
import {ERC721AUpgradeable} from "./abstract/ERC721AUpgradeable.sol";
import {Owner} from "./abstract/Owner.sol";

import {Initializable} from "./abstract/Initializable.sol";
import {ERC165} from "./abstract/ERC165.sol";
import {AccessControl} from "./abstract/AccessControl.sol";

import "../interface/HolographInterface.sol";
import "../interface/HolographInterfacesInterface.sol";
import "../interface/HolographRegistryInterface.sol";
import "../interface/HolographRoyaltiesInterface.sol";
import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";
import {IOperatorFilterRegistry} from "./interfaces/IOperatorFilterRegistry.sol";
import {IHolographERC721Drop} from "./interfaces/IHolographERC721Drop.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";
import {IAccessControl} from "./interfaces/IAccessControl.sol";
import {IERC165Upgradeable} from "./interfaces/IERC165Upgradeable.sol";
import {IERC721AUpgradeable} from "./interfaces/IERC721AUpgradeable.sol";

import {DropInitializer} from "../struct/DropInitializer.sol";

import {MerkleProof} from "./library/MerkleProof.sol";
import {Address} from "./library/Address.sol";

/**
 * @notice HOLOGRAPH NFT contract for Drops and Editions
 *
 * @dev For drops: assumes 1. linear mint order, 2. max number of mints needs to be less than max_uint64
 *
 */
contract HolographERC721Drop is
  Initializable,
  Owner,
  ERC721AUpgradeable,
  NonReentrant,
  AccessControl,
  IHolographERC721Drop
{
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.sourceContract')) - 1)
   */
  bytes32 constant _sourceContractSlot = precomputeslot("eip1967.Holograph.sourceContract");

  /// @dev This is the max mint batch size for the optimized ERC721A mint contract
  uint256 constant MAX_MINT_BATCH_SIZE = 8;

  /// @dev Gas limit to send funds
  uint256 constant FUNDS_SEND_GAS_LIMIT = 210_000;

  /// @notice Configuration for NFT minting contract storage
  IHolographERC721Drop.Configuration public config;

  /// @notice Sales configuration
  IHolographERC721Drop.SalesConfiguration public salesConfig;

  /// @dev Mapping for presale mint counts by address to allow public mint limit
  mapping(address => uint256) public presaleMintsByAddress;

  /// @notice Access control roles
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");
  bytes32 public constant SALES_MANAGER_ROLE = keccak256("SALES_MANAGER");

  /// @dev HOLOGRAPH transfer helper address for auto-approval
  address public holographERC721TransferHelper;

  address public marketFilterAddress;

  IOperatorFilterRegistry public operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  /// @notice Only allow for users with admin access
  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
      revert Access_OnlyAdmin();
    }

    _;
  }

  /// @notice Only a given role has access or admin
  /// @param role role to check for alongside the admin role
  modifier onlyRoleOrAdmin(bytes32 role) {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(role, msg.sender)) {
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

  /**
   * @dev Receives and executes a batch of function calls on this contract.
   */
  function multicall(bytes[] memory data) public returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
  }

  /// @dev Initialize a new drop contract
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");

    (DropInitializer memory initializer, bool skipInit) = abi.decode(initPayload, (DropInitializer, bool));
    holographERC721TransferHelper = initializer.holographERC721TransferHelper;
    marketFilterAddress = initializer.marketFilterAddress;

    _name = initializer.contractName;
    _symbol = initializer.contractSymbol;
    _currentIndex = _startTokenId();

    // Setup the owner role
    _setupRole(DEFAULT_ADMIN_ROLE, initializer.initialOwner);
    // Set ownership to original sender of contract call
    address newOwner = initializer.initialOwner;
    Initializable sourceContract;
    assembly {
      sstore(_ownerSlot, newOwner)
      sourceContract := sload(_sourceContractSlot)
    }

    if (initializer.setupCalls.length > 0) {
      // Setup temporary role
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      // Execute setupCalls
      multicall(initializer.setupCalls);
      // Remove temporary role
      _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    setStatus(1);

    // Setup Holograph Royalties
    if (!skipInit) {
      require(sourceContract.init(bytes("")) == Initializable.init.selector, "DROPS: could not init source");
      _royalties().delegatecall(
        abi.encodeWithSelector(
          HolographRoyaltiesInterface.initHolographRoyalties.selector,
          abi.encode(uint256(initializer.royaltyBPS), uint256(0))
        )
      );
    }

    // Setup config variables
    config.royaltyBPS = initializer.royaltyBPS;
    config.fundsRecipient = initializer.fundsRecipient;
    config.editionSize = initializer.editionSize;
    config.metadataRenderer = IMetadataRenderer(initializer.metadataRenderer);

    // TODO: Need to make sure to initialize the metadata renderer
    IMetadataRenderer(initializer.metadataRenderer).initializeWithData(initializer.metadataRendererInit);

    // Holograph initialization
    _setInitialized();
    return Initializable.init.selector;
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

  function owner() external view override(Owner, IHolographERC721Drop) returns (address) {
    return getOwner();
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
      _numberMinted(msg.sender) + quantity - presaleMintsByAddress[msg.sender] > salesConfig.maxSalePurchasePerAddress
    ) {
      revert Purchase_TooManyForAddress();
    }

    _mintNFTs(msg.sender, quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IHolographERC721Drop.Sale({
      to: msg.sender,
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
      !MerkleProof.verify(
        merkleProof,
        salesConfig.presaleMerkleRoot,
        keccak256(
          // address, uint256, uint256
          abi.encode(msg.sender, maxQuantity, pricePerToken)
        )
      )
    ) {
      revert Presale_MerkleNotApproved();
    }

    if (msg.value != pricePerToken * quantity) {
      revert Purchase_WrongPrice(pricePerToken * quantity);
    }

    presaleMintsByAddress[msg.sender] += quantity;
    if (presaleMintsByAddress[msg.sender] > maxQuantity) {
      revert Presale_TooManyForAddress();
    }

    _mintNFTs(msg.sender, quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IHolographERC721Drop.Sale({
      to: msg.sender,
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
    if (marketFilterAddress == address(0)) {
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
    uint256 currentId = _currentIndex;
    uint256 startAt = currentId;

    unchecked {
      for (uint256 endAt = currentId + recipients.length; currentId < endAt; currentId++) {
        _mintNFTs(recipients[currentId - startAt], 1);
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
  function setOwner(address newOwner) public override onlyAdmin {
    assembly {
      sstore(_ownerSlot, newOwner)
    }
  }

  /// @notice Set a new metadata renderer
  /// @param newRenderer new renderer address to use
  /// @param setupRenderer data to setup new renderer with
  function setMetadataRenderer(IMetadataRenderer newRenderer, bytes memory setupRenderer) external onlyAdmin {
    config.metadataRenderer = newRenderer;

    if (setupRenderer.length > 0) {
      newRenderer.initializeWithData(setupRenderer);
    }

    emit UpdatedMetadataRenderer({sender: msg.sender, renderer: newRenderer});
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

    emit SalesConfigChanged(msg.sender);
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
    emit OpenMintFinalized(msg.sender, config.editionSize);
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***      GENERAL GETTER FUNCTIONS      ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

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

  /**
   * @notice Shows the interfaces the contracts support
   * @dev Must add new 4 byte interface Ids here to acknowledge support
   * @param interfaceId ERC165 style 4 byte interfaceId.
   * @return bool True if supported.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165, IERC165Upgradeable, AccessControl)
    returns (bool)
  {
    HolographInterfacesInterface interfaces = HolographInterfacesInterface(_interfaces());
    ERC165 erc165Contract;
    assembly {
      erc165Contract := sload(precomputeslot("eip1967.Holograph.sourceContract"))
    }
    if (
      interfaces.supportsInterface(InterfaceType.ERC721, interfaceId) || // check global interfaces
      interfaces.supportsInterface(InterfaceType.ROYALTIES, interfaceId) || // check if royalties supports interface
      erc165Contract.supportsInterface(interfaceId) // check if source supports interface
    ) {
      return true;
    } else {
      return false;
    }
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***        INTERFACE FUNCTIONS         ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  function _holograph() internal view returns (HolographInterface holograph) {
    assembly {
      /**
       * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
       */
      holograph := sload(precomputeslot("eip1967.Holograph.holograph"))
    }
  }

  /**
   * @dev Get the interfaces contract address.
   */
  function _interfaces() internal view returns (address) {
    return _holograph().getInterfaces();
  }

  /**
   * @dev Get the bridge contract address.
   */
  function _royalties() internal view returns (address) {
    return
      HolographRegistryInterface(_holograph().getRegistry()).getContractTypeAddress(asciihex("HolographRoyalties"));
  }

  event FundsReceived(address indexed source, uint256 amount);

  receive() external payable {
    emit FundsReceived(msg.sender, msg.value);
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***        FALLBACK FUNCTIONS          ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /**
   * @notice Fallback to the source contract.
   * @dev Any function call that is not covered here, will automatically be sent over to the source contract.
   */
  fallback() external payable {
    // Check if royalties support the function, send there, otherwise revert to source
    address _target;
    if (HolographInterfacesInterface(_interfaces()).supportsInterface(InterfaceType.ROYALTIES, msg.sig)) {
      _target = _royalties();
      assembly {
        calldatacopy(0, 0, calldatasize())
        let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
        returndatacopy(0, 0, returndatasize())
        switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
      }
    } else {
      assembly {
        calldatacopy(0, 0, calldatasize())
        mstore(calldatasize(), caller())
        /**
         * @dev bytes32(uint256(keccak256('eip1967.Holograph.sourceContract')) - 1)
         */
        let result := call(
          gas(),
          sload(precomputeslot("eip1967.Holograph.sourceContract")),
          callvalue(),
          0,
          add(calldatasize(), 0x20),
          0,
          0
        )
        returndatacopy(0, 0, returndatasize())
        switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
      }
    }
  }
}
