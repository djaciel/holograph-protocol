// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import {DropInitializer} from "../struct/DropInitializer.sol";

import {HolographERC721DropProxy} from "./HolographERC721DropProxy.sol";
import {EditionMetadataRenderer} from "./metadata/EditionMetadataRenderer.sol";
import {IHolographERC721Drop} from "./interfaces/IHolographERC721Drop.sol";
import {DropMetadataRenderer} from "./metadata/DropMetadataRenderer.sol";
import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";
import {HolographERC721Drop} from "./HolographERC721Drop.sol";

/// @notice Holograph NFT Creator V1
contract HolographDropCreator is Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
   */
  bytes32 constant _holographSlot = 0xb4107f746e9496e8452accc7de63d1c5e14c19f510932daa04077cd49e8bd77a;

  string private constant CANNOT_BE_ZERO = "Cannot be 0 address";

  /// @notice Emitted when a edition is created reserving the corresponding token IDs.
  event CreatedDrop(address indexed creator, address indexed editionContractAddress, uint256 editionSize);

  /// @notice Address for HolographERC721Drop of implementation contract to clone
  address public implementation;

  /// @notice Edition metdata renderer
  EditionMetadataRenderer public editionMetadataRenderer;

  /// @notice Drop metdata renderer
  DropMetadataRenderer public dropMetadataRenderer;

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (
      address implementationAddress, 
      address editionMetadataRendererAddress, 
      address dropMetadataRendererAddress
    ) = abi.decode(initPayload, (address, address, address));
    
    require(implementationAddress != address(0), CANNOT_BE_ZERO);
    require(address(editionMetadataRendererAddress) != address(0), CANNOT_BE_ZERO);
    require(address(dropMetadataRendererAddress) != address(0), CANNOT_BE_ZERO);

    implementation = implementationAddress;
    editionMetadataRenderer = EditionMetadataRenderer(editionMetadataRendererAddress);
    dropMetadataRenderer = DropMetadataRenderer(dropMetadataRendererAddress);

    // assembly {
    //   sstore(_holographSlot, holograph)
    // }

    _setInitialized();
    return InitializableInterface.init.selector;
  }

  constructor() {}

  function createAndConfigureDrop(
    string memory name,
    string memory symbol,
    address defaultAdmin,
    uint64 editionSize,
    uint16 royaltyBPS,
    address payable fundsRecipient,
    bytes[] memory setupCalls,
    IMetadataRenderer metadataRenderer,
    bytes memory metadataInitializer
  ) public returns (address payable newDropAddress) {
    // Get initial implementation to get variables that used to be set as immutable
    HolographERC721Drop impl = HolographERC721Drop(payable(implementation));
    HolographERC721DropProxy erc721DropProxy = new HolographERC721DropProxy();
    DropInitializer memory initialzer = DropInitializer(
      impl.holographFeeManager.address,
      impl.holographERC721TransferHelper.address,
      impl.factoryUpgradeGate.address,
      impl.marketFilterDAOAddress.address,
      name,
      symbol,
      defaultAdmin,
      fundsRecipient,
      editionSize,
      royaltyBPS,
      setupCalls,
      address(metadataRenderer),
      metadataInitializer
    );

    // Run init to connect proxy to initial implementation, and to configure the drop
    erc721DropProxy.init(abi.encode(implementation, abi.encode(initialzer)));
    newDropAddress = payable(address(erc721DropProxy));
  }

  //        ,-.
  //        `-'
  //        /|\
  //         |                    ,----------------.              ,----------.
  //        / \                   |HolographDropCreator|              |HolographERC721Drop|
  //      Caller                  `-------+--------'              `----+-----'
  //        |                       createDrop()                       |
  //        | --------------------------------------------------------->
  //        |                             |                            |
  //        |                             |----.
  //        |                             |    | initialize NFT metadata
  //        |                             |<---'
  //        |                             |                            |
  //        |                             |           deploy           |
  //        |                             | --------------------------->
  //        |                             |                            |
  //        |                             |       initialize drop      |
  //        |                             | --------------------------->
  //        |                             |                            |
  //        |                             |----.                       |
  //        |                             |    | emit CreatedDrop      |
  //        |                             |<---'                       |
  //        |                             |                            |
  //        | return drop contract address|                            |
  //        | <----------------------------                            |
  //      Caller                  ,-------+--------.              ,----+-----.
  //        ,-.                   |HolographDropCreator|              |HolographERC721Drop|
  //        `-'                   `----------------'              `----------'
  //        /|\
  //         |
  //        / \
  /// @notice deprecated: Will be removed in 2023
  /// @notice Function to setup the media contract across all metadata types
  /// @dev Called by edition and drop fns internally
  /// @param name Name for new contract (cannot be changed)
  /// @param symbol Symbol for new contract (cannot be changed)
  /// @param defaultAdmin Default admin address
  /// @param editionSize The max size of the media contract allowed
  /// @param royaltyBPS BPS for on-chain royalties (cannot be changed)
  /// @param fundsRecipient recipient for sale funds and, unless overridden, royalties
  function setupDropsContract(
    string memory name,
    string memory symbol,
    address defaultAdmin,
    uint64 editionSize,
    uint16 royaltyBPS,
    address payable fundsRecipient,
    IHolographERC721Drop.SalesConfiguration memory saleConfig,
    IMetadataRenderer metadataRenderer,
    bytes memory metadataInitializer
  ) public returns (address) {
    bytes[] memory setupData = new bytes[](1);
    setupData[0] = abi.encodeWithSelector(
      HolographERC721Drop.setSaleConfiguration.selector,
      saleConfig.publicSalePrice,
      saleConfig.maxSalePurchasePerAddress,
      saleConfig.publicSaleStart,
      saleConfig.publicSaleEnd,
      saleConfig.presaleStart,
      saleConfig.presaleEnd,
      saleConfig.presaleMerkleRoot
    );
    address newDropAddress = createAndConfigureDrop({
      name: name,
      symbol: symbol,
      defaultAdmin: defaultAdmin,
      fundsRecipient: fundsRecipient,
      editionSize: editionSize,
      royaltyBPS: royaltyBPS,
      setupCalls: setupData,
      metadataRenderer: metadataRenderer,
      metadataInitializer: metadataInitializer
    });

    emit CreatedDrop({creator: msg.sender, editionSize: editionSize, editionContractAddress: newDropAddress});

    return newDropAddress;
  }

  //        ,-.
  //        `-'
  //        /|\
  //         |                    ,----------------.              ,----------.
  //        / \                   |HolographDropCreator|              |HolographERC721Drop|
  //      Caller                  `-------+--------'              `----+-----'
  //        |                       createDrop()                       |
  //        | --------------------------------------------------------->
  //        |                             |                            |
  //        |                             |----.
  //        |                             |    | initialize NFT metadata
  //        |                             |<---'
  //        |                             |                            |
  //        |                             |           deploy           |
  //        |                             | --------------------------->
  //        |                             |                            |
  //        |                             |       initialize drop      |
  //        |                             | --------------------------->
  //        |                             |                            |
  //        |                             |----.                       |
  //        |                             |    | emit CreatedDrop      |
  //        |                             |<---'                       |
  //        |                             |                            |
  //        | return drop contract address|                            |
  //        | <----------------------------                            |
  //      Caller                  ,-------+--------.              ,----+-----.
  //        ,-.                   |HolographDropCreator|              |ERC721Drop|
  //        `-'                   `----------------'              `----------'
  //        /|\
  //         |
  //        / \
  /// @notice @deprecated Will be removed in 2023
  /// @dev Setup the media contract for a drop
  /// @param name Name for new contract (cannot be changed)
  /// @param symbol Symbol for new contract (cannot be changed)
  /// @param defaultAdmin Default admin address
  /// @param editionSize The max size of the media contract allowed
  /// @param royaltyBPS BPS for on-chain royalties (cannot be changed)
  /// @param fundsRecipient recipient for sale funds and, unless overridden, royalties
  /// @param metadataURIBase URI Base for metadata
  /// @param metadataContractURI URI for contract metadata
  function createDrop(
    string memory name,
    string memory symbol,
    address defaultAdmin,
    uint64 editionSize,
    uint16 royaltyBPS,
    address payable fundsRecipient,
    IHolographERC721Drop.SalesConfiguration memory saleConfig,
    string memory metadataURIBase,
    string memory metadataContractURI
  ) external returns (address) {
    bytes memory metadataInitializer = abi.encode(metadataURIBase, metadataContractURI);
    return
      setupDropsContract({
        defaultAdmin: defaultAdmin,
        name: name,
        symbol: symbol,
        royaltyBPS: royaltyBPS,
        editionSize: editionSize,
        fundsRecipient: fundsRecipient,
        saleConfig: saleConfig,
        metadataRenderer: dropMetadataRenderer,
        metadataInitializer: metadataInitializer
      });
  }

  //        ,-.
  //        `-'
  //        /|\
  //         |                    ,----------------.              ,----------.
  //        / \                   |HolographDropCreator|              |HolographERC721Drop|
  //      Caller                  `-------+--------'              `----+-----'
  //        |                      createEdition()                     |
  //        | --------------------------------------------------------->
  //        |                             |                            |
  //        |                             |----.
  //        |                             |    | initialize NFT metadata
  //        |                             |<---'
  //        |                             |                            |
  //        |                             |           deploy           |
  //        |                             | --------------------------->
  //        |                             |                            |
  //        |                             |     initialize edition     |
  //        |                             | --------------------------->
  //        |                             |                            |
  //        |                             |----.                       |
  //        |                             |    | emit CreatedDrop      |
  //        |                             |<---'                       |
  //        |                             |                            |
  //        | return drop contract address|                            |
  //        | <----------------------------                            |
  //      Caller                  ,-------+--------.              ,----+-----.
  //        ,-.                   |HolographDropCreator|              |ERC721Drop|
  //        `-'                   `----------------'              `----------'
  //        /|\
  //         |
  //        / \
  /// @notice Creates a new edition contract as a factory with a deterministic address
  /// @notice Important: None of these fields (except the Url fields with the same hash) can be changed after calling
  /// @notice deprecated: Will be removed in 2023
  /// @param name Name of the edition contract
  /// @param symbol Symbol of the edition contract
  /// @param defaultAdmin Default admin address
  /// @param editionSize Total size of the edition (number of possible editions)
  /// @param royaltyBPS BPS amount of royalty
  /// @param fundsRecipient Funds recipient for the NFT sale
  /// @param description Metadata: Description of the edition entry
  /// @param animationURI Metadata: Animation url (optional) of the edition entry
  /// @param imageURI Metadata: Image url (semi-required) of the edition entry
  function createEdition(
    string memory name,
    string memory symbol,
    uint64 editionSize,
    uint16 royaltyBPS,
    address payable fundsRecipient,
    address defaultAdmin,
    IHolographERC721Drop.SalesConfiguration memory saleConfig,
    string memory description,
    string memory animationURI,
    string memory imageURI
  ) external returns (address) {
    bytes memory metadataInitializer = abi.encode(description, imageURI, animationURI);

    return
      setupDropsContract({
        name: name,
        symbol: symbol,
        defaultAdmin: defaultAdmin,
        editionSize: editionSize,
        royaltyBPS: royaltyBPS,
        saleConfig: saleConfig,
        fundsRecipient: fundsRecipient,
        metadataRenderer: editionMetadataRenderer,
        metadataInitializer: metadataInitializer
      });
  }
}
