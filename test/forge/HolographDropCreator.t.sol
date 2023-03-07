// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Constants} from "./utils/Constants.sol";

import {DeploymentConfig} from "../../contracts/struct/DeploymentConfig.sol";
import {Verification} from "../../contracts/struct/Verification.sol";

import {IMetadataRenderer} from "../../contracts/drops/interface/IMetadataRenderer.sol";
import "../../contracts/old_drops/HolographDropCreator.sol";
import "../../contracts/old_drops/HolographFeeManager.sol";
import {HolographERC721Drop} from "../../contracts/old_drops/HolographERC721Drop.sol";

import {HolographFactory} from "../../contracts/HolographFactory.sol";

import {MockMetadataRenderer} from "./metadata/MockMetadataRenderer.sol";
import {IERC721AUpgradeable} from "../../contracts/old_drops/interfaces/IERC721AUpgradeable.sol";

import {DummyCustomContract} from "../../contracts/old_drops/utils/DummyCustomContract.sol";

contract HolographDropCreatorTest is Test {
  address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
  address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS = payable(address(0x001));
  address payable public constant HOLOGRAPH_TREASURY_ADDRESS = payable(address(0x999));

  HolographERC721Drop public erc721Drop;
  HolographDropCreator public impl;
  HolographDropCreator public creator;

  HolographFeeManager public feeManager;
  EditionMetadataRenderer public editionMetadataRenderer;
  DropMetadataRenderer public dropMetadataRenderer;

  address public alice;

  // Drop properties
  string private name;
  string private symbol;
  uint64 private editionSize;
  uint16 private royaltyBPS;
  string private description;
  string private imageURI;
  string private animationURI;
  string private metadataURI;
  string private metadataContractURI;
  address payable private defaultAdmin;
  address payable private fundsRecipient;
  bytes private metadataInitializer;

  function setUp() public {
    // Setup VM
    // NOTE: These tests rely on the Holograph protocol being deployed to the local chain
    //       At the moment, the deploy pipeline is still managed by Hardhat, so we need to
    //       first run it via `npx hardhat deploy --network localhost` or `yarn deploy:localhost` if you need two local chains before running the tests.
    uint256 forkId = vm.createFork("http://localhost:8545");
    vm.selectFork(forkId);

    // Setup signer wallet
    // NOTE: This is the address that will be used to sign transactions
    //       A signature is required to deploy Holographable contracts via the HolographFactory
    alice = vm.addr(1);

    vm.prank(HOLOGRAPH_TREASURY_ADDRESS);
    feeManager = new HolographFeeManager();
    feeManager.init(abi.encode(500, HOLOGRAPH_TREASURY_ADDRESS));
    editionMetadataRenderer = new EditionMetadataRenderer();
    dropMetadataRenderer = new DropMetadataRenderer();

    // Setup ERC721 Drop Properties
    name = "Holograph ERC721 Drop Collection";
    symbol = "hDROP";
    editionSize = 100;
    royaltyBPS = 1000;
    description = "description";
    imageURI = "imageURI";
    animationURI = "animationURI";
    metadataURI = "metadataURI";
    metadataContractURI = "metadataContractURI";
    defaultAdmin = payable(DEFAULT_OWNER_ADDRESS);
    fundsRecipient = payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS);
    metadataInitializer = abi.encode(description, imageURI, animationURI);
  }

  function test_CreateEdition() public {
    // Create implementations
    erc721Drop = new HolographERC721Drop();
    creator = new HolographDropCreator();

    // Initialize deployment with actual values
    creator.init(abi.encode(address(erc721Drop), address(editionMetadataRenderer), address(dropMetadataRenderer)));

    address deployedEdition = creator.createEdition(
      name,
      symbol,
      editionSize,
      royaltyBPS,
      defaultAdmin,
      fundsRecipient,
      IHolographERC721Drop.SalesConfiguration({
        publicSaleStart: 0,
        publicSaleEnd: type(uint64).max, // Never ends
        presaleStart: 0,
        presaleEnd: 0,
        publicSalePrice: 0.1 ether,
        maxSalePurchasePerAddress: 0,
        presaleMerkleRoot: bytes32(0)
      }),
      description,
      animationURI,
      imageURI
    );

    HolographERC721Drop drop = HolographERC721Drop(payable(deployedEdition));
    vm.startPrank(DEFAULT_FUNDS_RECIPIENT_ADDRESS);
    vm.deal(DEFAULT_FUNDS_RECIPIENT_ADDRESS, 10 ether);
    drop.purchase{value: 1 ether}(10);
    assertEq(drop.totalSupply(), 10);
  }

  function test_CreateDrop() public {
    // Create implementations
    erc721Drop = new HolographERC721Drop();
    creator = new HolographDropCreator();

    // Initialize deployment with actual values
    creator.init(abi.encode(address(erc721Drop), address(editionMetadataRenderer), address(dropMetadataRenderer)));

    address deployedDrop = creator.createDrop(
      name,
      symbol,
      editionSize,
      royaltyBPS,
      defaultAdmin,
      fundsRecipient,
      IHolographERC721Drop.SalesConfiguration({
        publicSaleStart: 0,
        publicSaleEnd: type(uint64).max,
        presaleStart: 0,
        presaleEnd: 0,
        publicSalePrice: 0,
        maxSalePurchasePerAddress: 0,
        presaleMerkleRoot: bytes32(0)
      }),
      metadataURI,
      metadataContractURI
    );
    HolographERC721Drop drop = HolographERC721Drop(payable(deployedDrop));
    drop.purchase(10);
    assertEq(drop.totalSupply(), 10);
  }

  function test_CreateGenericDrop() public {
    // Create implementations
    erc721Drop = new HolographERC721Drop();
    creator = new HolographDropCreator();

    // Initialize deployment with actual values
    creator.init(abi.encode(address(erc721Drop), address(editionMetadataRenderer), address(dropMetadataRenderer)));

    MockMetadataRenderer mockRenderer = new MockMetadataRenderer();

    address deployedDrop = creator.setupDropsContract(
      name,
      symbol,
      editionSize,
      royaltyBPS,
      defaultAdmin,
      fundsRecipient,
      IHolographERC721Drop.SalesConfiguration({
        publicSaleStart: 0,
        publicSaleEnd: type(uint64).max,
        presaleStart: 0,
        presaleEnd: 0,
        publicSalePrice: 0,
        maxSalePurchasePerAddress: 0,
        presaleMerkleRoot: bytes32(0)
      }),
      mockRenderer,
      ""
    );
    HolographERC721Drop drop = HolographERC721Drop(payable(deployedDrop));
    HolographERC721Drop.SaleDetails memory saleDetails = drop.saleDetails();
    assertEq(saleDetails.publicSaleStart, 0);
    assertEq(saleDetails.publicSaleEnd, type(uint64).max);
    vm.expectRevert(IERC721AUpgradeable.URIQueryForNonexistentToken.selector);
    drop.tokenURI(1);
    assertEq(drop.contractURI(), "DEMO");
    drop.purchase(1);
    assertEq(drop.tokenURI(1), "DEMO");
  }

  function test_CreateHolographEdition() public {
    // Setup sale config for edition
    IHolographERC721Drop.SalesConfiguration memory saleConfig = IHolographERC721Drop.SalesConfiguration({
      publicSaleStart: 0, // starts now
      publicSaleEnd: type(uint64).max, // never ends
      presaleStart: 0, // never starts
      presaleEnd: 0, // never ends
      publicSalePrice: 0.1 ether, // 0.1 ETH
      maxSalePurchasePerAddress: 0, // no limit
      presaleMerkleRoot: bytes32(0) // no presale
    });
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
    // Create initializer
    DropInitializer memory initializer = DropInitializer(
      address(feeManager), // HolographFeeManager,
      address(0), // HolographERC721TransferHelper
      address(0), // marketFilterAddress
      name,
      symbol,
      defaultAdmin,
      fundsRecipient,
      editionSize,
      royaltyBPS,
      setupData,
      address(editionMetadataRenderer),
      metadataInitializer
    );

    // Get deployment config, hash it, and then sign it
    DeploymentConfig memory config = getDeploymentConfig(initializer);
    bytes32 hash = keccak256(
      abi.encodePacked(
        config.contractType,
        config.chainType,
        config.salt,
        keccak256(config.byteCode),
        keccak256(config.initCode),
        alice
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
    Verification memory signature = Verification(r, s, v);
    address signer = ecrecover(hash, v, r, s);
    require(signer == alice, "Invalid signature");

    HolographFactory factory = HolographFactory(payable(Constants.getHolographFactory()));
    console.log("Factory address: ", address(factory));
    console.log("Holograph address: ", address(factory.getHolograph()));
    console.log("Registry address: ", address(factory.getRegistry()));
    console.log("Signer address: ", signer);

    // Deploy the drop / edition
    vm.recordLogs();
    factory.deployHolographableContract(config, signature, alice); // Pass the payload hash, with the signature, and signer's address
    Vm.Log[] memory entries = vm.getRecordedLogs();
    address newDropAddress = address(uint160(uint256(entries[5].topics[1])));
    console.log("New drop address: ", newDropAddress);

    // Test checks start here
    HolographERC721Drop drop = HolographERC721Drop(payable(newDropAddress));
    vm.startPrank(DEFAULT_FUNDS_RECIPIENT_ADDRESS);
    vm.deal(DEFAULT_FUNDS_RECIPIENT_ADDRESS, 10 ether);
    drop.purchase{value: 1 ether}(10);
    assertEq(drop.totalSupply(), 10);
  }

  function test_CreateHolographDrop() public {
    // Setup sale config for drop
    IHolographERC721Drop.SalesConfiguration memory saleConfig = IHolographERC721Drop.SalesConfiguration({
      publicSaleStart: 0, // starts now
      publicSaleEnd: type(uint64).max, // never ends
      presaleStart: 0, // never starts
      presaleEnd: 0, // never ends
      publicSalePrice: 0, // free
      maxSalePurchasePerAddress: 0, // no limit
      presaleMerkleRoot: bytes32(0) // no presale
    });
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
    // Create initializer
    DropInitializer memory initializer = DropInitializer(
      address(feeManager), // HolographFeeManager,
      address(0), // HolographERC721TransferHelper
      address(0), // marketFilterAddress
      "Holograph ERC721 Drop Collection",
      "hDROP",
      payable(DEFAULT_OWNER_ADDRESS),
      payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS),
      100,
      1000,
      setupData,
      address(dropMetadataRenderer),
      abi.encode("description", "imageURI", "animationURI")
    );

    // Get deployment config, hash it, and then sign it
    DeploymentConfig memory config = getDeploymentConfig(initializer);
    bytes32 hash = keccak256(
      abi.encodePacked(
        config.contractType,
        config.chainType,
        config.salt,
        keccak256(config.byteCode),
        keccak256(config.initCode),
        alice
      )
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, hash);
    Verification memory signature = Verification(r, s, v);
    address signer = ecrecover(hash, v, r, s);

    HolographFactory factory = HolographFactory(payable(Constants.getHolographFactory()));
    console.log("Factory address: ", address(factory));
    console.log("Holograph address: ", address(factory.getHolograph()));
    console.log("Registry address: ", address(factory.getRegistry()));
    console.log("Signer address: ", signer);

    // Deploy the drop / edition
    vm.recordLogs();
    factory.deployHolographableContract(config, signature, alice); // Pass the payload hash, with the signature, and signer's address
    Vm.Log[] memory entries = vm.getRecordedLogs();
    address newDropAddress = address(uint160(uint256(entries[5].topics[1])));
    console.log("New drop address: ", newDropAddress);

    // Test checks start here
    HolographERC721Drop drop = HolographERC721Drop(payable(newDropAddress));
    vm.startPrank(DEFAULT_FUNDS_RECIPIENT_ADDRESS);
    vm.deal(DEFAULT_FUNDS_RECIPIENT_ADDRESS, 10 ether);
    drop.purchase(10);
    assertEq(drop.totalSupply(), 10);
  }

  // TEST HELPERS
  function getDeploymentConfig(DropInitializer memory initializer) public returns (DeploymentConfig memory) {
    return
      DeploymentConfig({
        contractType: 0x00000000000000000000000000486F6C6F677261706845524337323144726F70, // HolographERC721Drop
        chainType: 1338, // holograph.getChainId(),
        salt: 0x0000000000000000000000000000000000000000000000000000000000000001, // random salt from user
        byteCode: abi.encodePacked(vm.getCode("DummyCustomContract.sol:DummyCustomContract")), // for custom contract is not used
        initCode: abi.encode(initializer, false) // init code is used to initialize the ERC721Drop enforcer
      });
  }
}
