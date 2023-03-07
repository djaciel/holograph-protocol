// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import {ERC721H} from "../abstract/ERC721H.sol";
import {NonReentrant} from "../abstract/NonReentrant.sol";

import {HolographERC721Interface} from "../interface/HolographERC721Interface.sol";
import {HolographInterface} from "../interface/HolographInterface.sol";

import {DropInitializer} from "../drops/struct/DropInitializer.sol";

import {Address} from "../drops/library/Address.sol";
import {MerkleProof} from "../drops/library/MerkleProof.sol";

import {IMetadataRenderer} from "../drops/interface/IMetadataRenderer.sol";
import {IOperatorFilterRegistry} from "../drops/interface/IOperatorFilterRegistry.sol";
import {IHolographERC721Drop} from "../drops/interface/IHolographERC721Drop.sol";

contract HolographDropsEditionsV1 is NonReentrant, ERC721H, IHolographERC721Drop {
  /**
   * @notice Thrown when there is no active market filter address supported for the current chain
   * @dev Used for enabling and disabling filter for the given chain.
   */
  error MarketFilterAddressNotSupportedForChain();

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
    if (config.editionSize != 0 && quantity + _currentTokenId > config.editionSize) {
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

  function owner() external view override(ERC721H, IHolographERC721Drop) returns (address) {
    return _getOwner();
  }

  function isAdmin(address user) external view returns (bool) {
    return (_getOwner() == user);
  }

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
    config = Configuration({
      metadataRenderer: IMetadataRenderer(initializer.metadataRenderer),
      editionSize: initializer.editionSize,
      royaltyBPS: initializer.royaltyBPS,
      fundsRecipient: initializer.fundsRecipient
    });

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

  function _mintNFTs(address recipient, uint256 quantity) internal {
    HolographERC721Interface H721 = HolographERC721Interface(holographer());
    uint256 chainPrepend = H721.sourceGetChainPrepend();
    uint224 tokenId = 0;
    for (uint256 i = 0; i < quantity; i++) {
      _currentTokenId += 1;
      while (
        H721.exists(chainPrepend + uint256(_currentTokenId)) || H721.burned(chainPrepend + uint256(_currentTokenId))
      ) {
        _currentTokenId += 1;
      }
      tokenId = _currentTokenId;
      H721.sourceMint(recipient, tokenId);
      //uint256 id = chainPrepend + uint256(tokenId);
    }
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
   * @notice Set a new metadata renderer
   * @param newRenderer new renderer address to use
   * @param setupRenderer data to setup new renderer with
   */
  function setMetadataRenderer(IMetadataRenderer newRenderer, bytes memory setupRenderer) external onlyOwner {
    config.metadataRenderer = newRenderer;

    if (setupRenderer.length > 0) {
      newRenderer.initializeWithData(setupRenderer);
    }

    emit UpdatedMetadataRenderer({sender: msg.sender, renderer: newRenderer});
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

  /// @notice Set a different funds recipient
  /// @param newRecipientAddress new funds recipient address
  function setFundsRecipient(address payable newRecipientAddress) external onlyOwner {
    // TODO(iain): funds recipient cannot be 0?
    config.fundsRecipient = newRecipientAddress;
    emit FundsRecipientChanged(newRecipientAddress, msgSender());
  }

  /// @notice This withdraws ETH from the contract to the contract owner.
  function withdraw() external override nonReentrant {
    if (config.fundsRecipient == address(0)) {
      revert("Funds Recipient address not set");
    }
    address sender = msgSender();

    // Get fee amount
    uint256 funds = address(this).balance;
    address payable feeRecipient = payable(HolographInterface(holographer()).getTreasury());
    // for now set it to 0 since there is no fee
    uint256 holographFee = 0;

    // Check if withdraw is allowed for sender
    if (sender != config.fundsRecipient && sender != _getOwner() && sender != feeRecipient) {
      revert Access_WithdrawNotAllowed();
    }

    // Payout HOLOGRAPH fee
    if (holographFee > 0) {
      (bool successFee, ) = feeRecipient.call{value: holographFee, gas: 210_000}("");
      if (!successFee) {
        revert Withdraw_FundsSendFailure();
      }
      funds -= holographFee;
    }

    // Payout recipient
    (bool successFunds, ) = config.fundsRecipient.call{value: funds, gas: 210_000}("");
    if (!successFunds) {
      revert Withdraw_FundsSendFailure();
    }

    // Emit event for indexing
    emit FundsWithdrawn(sender, config.fundsRecipient, funds, feeRecipient, holographFee);
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
