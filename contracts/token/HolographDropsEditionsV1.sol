// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../abstract/ERC721H.sol";

import "../interface/HolographERC721Interface.sol";

import {NonReentrant} from "../abstract/NonReentrant.sol";
import {IMetadataRenderer} from "../drops/interfaces/IMetadataRenderer.sol";
import {IOperatorFilterRegistry} from "../drops/interfaces/IOperatorFilterRegistry.sol";
import {DropInitializer} from "../struct/DropInitializer.sol";
import {MerkleProof} from "../drops/library/MerkleProof.sol";

/**
 * @notice Interface for HOLOGRAPH Drops contract
 */
interface IHolographERC721Drop {
  // Access errors
  /**
   * @notice Only admin can access this function
   */
  error Access_OnlyAdmin();
  /**
   * @notice Missing the given role or admin access
   */
  error Access_MissingRoleOrAdmin(bytes32 role);
  /**
   * @notice Withdraw is not allowed by this user
   */
  error Access_WithdrawNotAllowed();
  /**
   * @notice Cannot withdraw funds due to ETH send failure.
   */
  error Withdraw_FundsSendFailure();

  /**
   * @notice Thrown when the operator for the contract is not allowed
   * @dev Used when strict enforcement of marketplaces for creator royalties is desired.
   */
  error OperatorNotAllowed(address operator);

  /**
   * @notice Thrown when there is no active market filter address supported for the current chain
   * @dev Used for enabling and disabling filter for the given chain.
   */
  error MarketFilterAddressNotSupportedForChain();

  /**
   * @notice Used when the operator filter registry external call fails
   * @dev Used for bubbling error up to clients.
   */
  error RemoteOperatorFilterRegistryCallFailed();

  // Sale/Purchase errors
  /**
   * @notice Sale is inactive
   */
  error Sale_Inactive();
  /**
   * @notice Presale is inactive
   */
  error Presale_Inactive();
  /**
   * @notice Presale merkle root is invalid
   */
  error Presale_MerkleNotApproved();
  /**
   * @notice Wrong price for purchase
   */
  error Purchase_WrongPrice(uint256 correctPrice);
  /**
   * @notice NFT sold out
   */
  error Mint_SoldOut();
  /**
   * @notice Too many purchase for address
   */
  error Purchase_TooManyForAddress();
  /**
   * @notice Too many presale for address
   */
  error Presale_TooManyForAddress();

  // Admin errors
  /**
   * @notice Royalty percentage too high
   */
  error Setup_RoyaltyPercentageTooHigh(uint16 maxRoyaltyBPS);
  /**
   * @notice Invalid admin upgrade address
   */
  error Admin_InvalidUpgradeAddress(address proposedAddress);
  /**
   * @notice Invalid fund recipient adress
   */
  error Admin_InvalidFundRecipientAddress(address newRecipientAddress);
  /**
   * @notice Unable to finalize an edition not marked as open (size set to uint64_max_value)
   */
  error Admin_UnableToFinalizeNotOpenEdition();

  /**
   * @notice Event emitted for each sale
   * @param to address sale was made to
   * @param quantity quantity of the minted nfts
   * @param pricePerToken price for each token
   * @param firstPurchasedTokenId first purchased token ID (to get range add to quantity for max)
   */
  event Sale(
    address indexed to,
    uint256 indexed quantity,
    uint256 indexed pricePerToken,
    uint256 firstPurchasedTokenId
  );

  /**
   * @notice Sales configuration has been changed
   * @dev To access new sales configuration, use getter function.
   * @param changedBy Changed by user
   */
  event SalesConfigChanged(address indexed changedBy);

  /**
   * @notice Event emitted when the funds recipient is changed
   * @param newAddress new address for the funds recipient
   * @param changedBy address that the recipient is changed by
   */
  event FundsRecipientChanged(address indexed newAddress, address indexed changedBy);

  /**
   * @notice Event emitted when the funds are withdrawn from the minting contract
   * @param withdrawnBy address that issued the withdraw
   * @param withdrawnTo address that the funds were withdrawn to
   * @param amount amount that was withdrawn
   * @param feeRecipient user getting withdraw fee (if any)
   * @param feeAmount amount of the fee getting sent (if any)
   */
  event FundsWithdrawn(
    address indexed withdrawnBy,
    address indexed withdrawnTo,
    uint256 amount,
    address feeRecipient,
    uint256 feeAmount
  );

  /**
   * @notice Event emitted when an open mint is finalized and further minting is closed forever on the contract.
   * @param sender address sending close mint
   * @param numberOfMints number of mints the contract is finalized at
   */
  event OpenMintFinalized(address indexed sender, uint256 numberOfMints);

  /**
   * @notice Event emitted when metadata renderer is updated.
   * @param sender address of the updater
   * @param renderer new metadata renderer address
   */
  event UpdatedMetadataRenderer(address sender, IMetadataRenderer renderer);

  /**
   * @notice General configuration for NFT Minting and bookkeeping
   */
  struct Configuration {
    /**
     * @dev Metadata renderer (uint160)
     */
    IMetadataRenderer metadataRenderer;
    /**
     * @dev Total size of edition that can be minted (uint160+64 = 224)
     */
    uint64 editionSize;
    /**
     * @dev Royalty amount in bps (uint224+16 = 240)
     */
    uint16 royaltyBPS;
    /**
     * @dev Funds recipient for sale (new slot, uint160)
     */
    address payable fundsRecipient;
  }

  /**
   * @notice Sales states and configuration
   * @dev Uses 3 storage slots
   */
  struct SalesConfiguration {
    /**
     * @dev Public sale price (max ether value > 1000 ether with this value)
     */
    uint104 publicSalePrice;
    /**
     * @notice Purchase mint limit per address (if set to 0 === unlimited mints)
     * @dev Max purchase number per txn (90+32 = 122)
     */
    uint32 maxSalePurchasePerAddress;
    /**
     * @dev uint64 type allows for dates into 292 billion years
     * @notice Public sale start timestamp (136+64 = 186)
     */
    uint64 publicSaleStart;
    /**
     * @notice Public sale end timestamp (186+64 = 250)
     */
    uint64 publicSaleEnd;
    /**
     * @notice Presale start timestamp
     * @dev new storage slot
     */
    uint64 presaleStart;
    /**
     * @notice Presale end timestamp
     */
    uint64 presaleEnd;
    /**
     * @notice Presale merkle root
     */
    bytes32 presaleMerkleRoot;
  }

  /**
   * @notice Return value for sales details to use with front-ends
   */
  struct SaleDetails {
    // Synthesized status variables for sale and presale
    bool publicSaleActive;
    bool presaleActive;
    // Price for public sale
    uint256 publicSalePrice;
    // Timed sale actions for public sale
    uint64 publicSaleStart;
    uint64 publicSaleEnd;
    // Timed sale actions for presale
    uint64 presaleStart;
    uint64 presaleEnd;
    // Merkle root (includes address, quantity, and price data for each entry)
    bytes32 presaleMerkleRoot;
    // Limit public sale to a specific number of mints per wallet
    uint256 maxSalePurchasePerAddress;
    // Information about the rest of the supply
    // Total that have been minted
    uint256 totalMinted;
    // The total supply available
    uint256 maxSupply;
  }

  /**
   * @notice Return type of specific mint counts and details per address
   */
  struct AddressMintDetails {
    /// Number of total mints from the given address
    uint256 totalMints;
    /// Number of presale mints from the given address
    uint256 presaleMints;
    /// Number of public mints from the given address
    uint256 publicMints;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
   *
   * _Available since v4.8._
   */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    // Look for revert reason and bubble it up if present
    if (returndata.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

contract HolographDropsEditionsV1 is NonReentrant, ERC721H, IHolographERC721Drop {
  /**
   * @dev Internal reference used for minting incremental token ids.
   */
  uint224 private _currentTokenId;

  /**
   * @notice Configuration for NFT minting contract storage
   */
  Configuration public config;

  /**
   * @notice Sales configuration
   */
  SalesConfiguration public salesConfig;

  /**
   * @dev Mapping for presale mint counts by address to allow public mint limit
   */
  mapping(address => uint256) public presaleMintsByAddress;

  /**
   * @dev Mapping for presale mint counts by address to allow public mint limit
   */
  mapping(address => uint256) public totalMintsByAddress;

  /**
   * @dev HOLOGRAPH transfer helper address for auto-approval
   */
  address public holographERC721TransferHelper;

  address public marketFilterAddress;

  IOperatorFilterRegistry public operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  /**
   * @notice Allows user to mint tokens at a quantity
   */
  modifier canMintTokens(uint256 quantity) {
    if (quantity + _currentTokenId > config.editionSize) {
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

  /**
   * @notice Presale active
   */
  modifier onlyPresaleActive() {
    if (!_presaleActive()) {
      revert Presale_Inactive();
    }

    _;
  }

  /**
   * @notice Public sale active
   */
  modifier onlyPublicSaleActive() {
    if (!_publicSaleActive()) {
      revert Sale_Inactive();
    }

    _;
  }

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  function multicall(bytes[] memory data) public returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
  }

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");

    DropInitializer memory initializer = abi.decode(initPayload, (DropInitializer));
    holographERC721TransferHelper = initializer.holographERC721TransferHelper;
    marketFilterAddress = initializer.marketFilterAddress;

    // Setup the owner role
    _setOwner(initializer.initialOwner);

    if (initializer.setupCalls.length > 0) {
      // Execute setupCalls
      multicall(initializer.setupCalls);
    }

    // Setup config variables
    config.royaltyBPS = initializer.royaltyBPS;
    config.fundsRecipient = initializer.fundsRecipient;
    config.editionSize = initializer.editionSize;

    config.metadataRenderer = IMetadataRenderer(initializer.metadataRenderer);

    // TODO: Need to make sure to initialize the metadata renderer
    IMetadataRenderer(initializer.metadataRenderer).initializeWithData(initializer.metadataRendererInit);

    setStatus(1);

    // Holograph initialization
    _setInitialized();
    return _init("");
  }

  function onIsApprovedForAll(
    address, /* _wallet*/
    address _operator
  ) external view returns (bool approved) {
    approved = (holographERC721TransferHelper != address(0) && _operator == holographERC721TransferHelper);
  }

  function _mintNFTs(address, uint256) internal {
    // we do nothing
  }

  /**
   * @notice Sale details
   * @return SaleDetails sale information details
   */
  function saleDetails() external view returns (SaleDetails memory) {
    return
      SaleDetails({
        publicSaleActive: _publicSaleActive(),
        presaleActive: _presaleActive(),
        publicSalePrice: salesConfig.publicSalePrice,
        publicSaleStart: salesConfig.publicSaleStart,
        publicSaleEnd: salesConfig.publicSaleEnd,
        presaleStart: salesConfig.presaleStart,
        presaleEnd: salesConfig.presaleEnd,
        presaleMerkleRoot: salesConfig.presaleMerkleRoot,
        totalMinted: _currentTokenId,
        maxSupply: config.editionSize,
        maxSalePurchasePerAddress: salesConfig.maxSalePurchasePerAddress
      });
  }

  /**
   * @dev Number of NFTs the user has minted per address
   * @param minter to get counts for
   */
  function mintedPerAddress(address minter) external view returns (AddressMintDetails memory) {
    return
      AddressMintDetails({
        presaleMints: presaleMintsByAddress[minter],
        publicMints: totalMintsByAddress[minter] - presaleMintsByAddress[minter],
        totalMints: totalMintsByAddress[minter]
      });
  }

  /**
   * @dev This allows the user to purchase/mint a edition at the given price in the contract.
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
      totalMintsByAddress[msgSender()] + quantity - presaleMintsByAddress[msgSender()] >
      salesConfig.maxSalePurchasePerAddress
    ) {
      revert Purchase_TooManyForAddress();
    }

    _mintNFTs(msgSender(), quantity);

    HolographERC721Interface H721 = HolographERC721Interface(holographer());
    uint256 chainPrepend = H721.sourceGetChainPrepend();
    uint256 firstMintedTokenId = (chainPrepend + uint256(_currentTokenId - quantity)) + 1;

    emit Sale({
      to: msgSender(),
      quantity: quantity,
      pricePerToken: salePrice,
      firstPurchasedTokenId: firstMintedTokenId
    });
    return firstMintedTokenId;
  }

  /**
   * @notice Merkle-tree based presale purchase function
   * @param quantity quantity to purchase
   * @param maxQuantity max quantity that can be purchased via merkle proof #
   * @param pricePerToken price that each token is purchased at
   * @param merkleProof proof for presale mint
   */
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
          abi.encode(msgSender(), maxQuantity, pricePerToken)
        )
      )
    ) {
      revert Presale_MerkleNotApproved();
    }

    if (msg.value != pricePerToken * quantity) {
      revert Purchase_WrongPrice(pricePerToken * quantity);
    }

    presaleMintsByAddress[msgSender()] += quantity;
    if (presaleMintsByAddress[msgSender()] > maxQuantity) {
      revert Presale_TooManyForAddress();
    }

    _mintNFTs(msgSender(), quantity);

    HolographERC721Interface H721 = HolographERC721Interface(holographer());
    uint256 chainPrepend = H721.sourceGetChainPrepend();
    uint256 firstMintedTokenId = (chainPrepend + uint256(_currentTokenId - quantity)) + 1;

    emit Sale({
      to: msgSender(),
      quantity: quantity,
      pricePerToken: pricePerToken,
      firstPurchasedTokenId: firstMintedTokenId
    });

    return firstMintedTokenId;
  }

  /**
   * @notice Proxy to update market filter settings in the main registry contracts
   * @notice Requires admin permissions
   * @param args Calldata args to pass to the registry
   */
  function updateMarketFilterSettings(bytes calldata args) external onlyOwner returns (bytes memory) {
    (bool success, bytes memory ret) = address(operatorFilterRegistry).call(args);
    if (!success) {
      revert RemoteOperatorFilterRegistryCallFailed();
    }
    return ret;
  }

  /**
   * @notice Manage subscription for marketplace filtering based off royalty payouts.
   * @param enable Enable filtering to non-royalty payout marketplaces
   */
  function manageMarketFilterSubscription(bool enable) external onlyOwner {
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
   * @notice Admin mint tokens to a recipient for free
   * @param recipient recipient to mint to
   * @param quantity quantity to mint
   */
  function adminMint(address recipient, uint256 quantity) external onlyOwner canMintTokens(quantity) returns (uint256) {
    _mintNFTs(recipient, quantity);

    return _currentTokenId;
  }

  /**
   * @dev Mints multiple editions to the given list of addresses.
   * @param recipients list of addresses to send the newly minted editions to
   */
  function adminMintAirdrop(address[] calldata recipients)
    external
    onlyOwner
    canMintTokens(recipients.length)
    returns (uint256)
  {
    unchecked {
      for (uint256 i = 0; i < recipients.length; i++) {
        _mintNFTs(recipients[i], 1);
      }
    }

    return _currentTokenId;
  }

  /**
   * @dev This sets the sales configuration
   * @param publicSalePrice New public sale price
   * @param maxSalePurchasePerAddress Max # of purchases (public) per address allowed
   * @param publicSaleStart unix timestamp when the public sale starts
   * @param publicSaleEnd unix timestamp when the public sale ends (set to 0 to disable)
   * @param presaleStart unix timestamp when the presale starts
   * @param presaleEnd unix timestamp when the presale ends
   * @param presaleMerkleRoot merkle root for the presale information
   */
  function setSaleConfiguration(
    uint104 publicSalePrice,
    uint32 maxSalePurchasePerAddress,
    uint64 publicSaleStart,
    uint64 publicSaleEnd,
    uint64 presaleStart,
    uint64 presaleEnd,
    bytes32 presaleMerkleRoot
  ) external onlyOwner {
    salesConfig.publicSalePrice = publicSalePrice;
    salesConfig.maxSalePurchasePerAddress = maxSalePurchasePerAddress;
    salesConfig.publicSaleStart = publicSaleStart;
    salesConfig.publicSaleEnd = publicSaleEnd;
    salesConfig.presaleStart = presaleStart;
    salesConfig.presaleEnd = presaleEnd;
    salesConfig.presaleMerkleRoot = presaleMerkleRoot;

    emit SalesConfigChanged(msgSender());
  }

  /**
   * @notice Admin function to finalize and open edition sale
   */
  function finalizeOpenEdition() external onlyOwner {
    if (config.editionSize != type(uint64).max) {
      revert Admin_UnableToFinalizeNotOpenEdition();
    }

    config.editionSize = uint64(_currentTokenId);
    emit OpenMintFinalized(msgSender(), config.editionSize);
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
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    HolographERC721Interface H721 = HolographERC721Interface(holographer());
    require(H721.exists(tokenId), "ERC721: token does not exist");

    return config.metadataRenderer.tokenURI(tokenId);
  }

  event FundsReceived(address indexed source, uint256 amount);

  receive() external payable override {
    emit FundsReceived(msgSender(), msg.value);
  }
}
