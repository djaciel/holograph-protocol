// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {DeploymentConfig} from "../../contracts/struct/DeploymentConfig.sol";
import {Verification} from "../../contracts/struct/Verification.sol";

import {IMetadataRenderer} from "../../contracts/drops/interfaces/IMetadataRenderer.sol";
import "../../contracts/drops/HolographDropCreator.sol";
import "../../contracts/drops/HolographDropCreatorProxy.sol";
import "../../contracts/drops/HolographFeeManager.sol";
import "../../contracts/drops/HolographERC721Drop.sol";

import {HolographFactory} from "../../contracts/HolographFactory.sol";

import {MockMetadataRenderer} from "./metadata/MockMetadataRenderer.sol";
import {FactoryUpgradeGate} from "../../contracts/drops/FactoryUpgradeGate.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";

contract Dummy {
  constructor() {}
}

contract HolographDropCreatorTest is Test {
  address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
  address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS = payable(address(0x21303));
  address payable public constant DEFAULT_HOLOGRAPH_DAO_ADDRESS = payable(address(0x999));

  HolographERC721Drop public erc721Drop;
  HolographDropCreator public impl;
  HolographDropCreator public creator;
  EditionMetadataRenderer public editionMetadataRenderer;
  DropMetadataRenderer public dropMetadataRenderer;

  address public alice;

  function setUp() public {
    uint256 forkId = vm.createFork("http://localhost:8545");
    vm.selectFork(forkId);

    vm.prank(DEFAULT_HOLOGRAPH_DAO_ADDRESS);
    HolographFeeManager feeManager = new HolographFeeManager(500, DEFAULT_HOLOGRAPH_DAO_ADDRESS);

    // Create implementations
    // ERC721Drop erc721Drop = new ERC721Drop();
    // editionMetadataRenderer = new EditionMetadataRenderer();
    // dropMetadataRenderer = new DropMetadataRenderer();
    // HolographDropCreator impl = new HolographDropCreator();
    // HolographNFTCreatorProxy creatorProxy = new HolographNFTCreatorProxy();

    // // Initialize proxy deployment with actual values
    // creatorProxy.init(
    //   abi.encode(impl, abi.encode(address(erc721Drop), address(editionMetadataRenderer), address(dropMetadataRenderer)))
    // );
    // address payable creatorProxyAddress = payable(address(creatorProxy));

    // // Map proxy out to full contract interface
    // creator = HolographDropCreator(creatorProxyAddress);

    // Setup signer wallet
    alice = vm.addr(1);
  }

  function getDeploymentConfig(DropInitializer memory initializer) public returns (DeploymentConfig memory) {
    return
      DeploymentConfig({
        contractType: "HolographERC721Drop",
        chainType: 1338, // holograph.getChainId(),
        salt: 0x0000000000000000000000000000000000000000000000000000000000000001, // random salt from user
        byteCode: abi.encode(0x0), // for custom contract is not used
        initCode: abi.encode(initializer) // init code is used to initialize the ERC721Drop enforcer
      });
  }

  /**
   * @dev Internal function used for verifying a signature
   */
  function _verifySigner(
    bytes32 r,
    bytes32 s,
    uint8 v,
    bytes32 hash,
    address signer
  ) private returns (bool) {
    // console.logBytes32(r);
    // console.logBytes32(s);
    // console.logUint(v);
    console.logBytes32(hash);

    if (v < 27) {
      v += 27;
    }
    if (v != 27 && v != 28) {
      return false;
    }
    // prevent signature malleability by checking if s-value is in the upper range
    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      // if s-value is in upper range, calculate a new s-value
      s = bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - uint256(s));
      // flip the v-value
      if (v == 27) {
        v = 28;
      } else {
        v = 27;
      }
      // check if s-value is still in upper range
      if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
        return false;
      }
    }
    /**
     * @dev signature is checked against EIP-191 first, then directly, to support legacy wallets
     */
    return (signer != address(0) &&
      (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == signer ||
        ecrecover(hash, v, r, s) == signer));
  }

  function _isContract(address contractAddress) private view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(contractAddress)
    }
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
  }

  function test_CreateEdition() public {
    string memory name = "name";
    string memory symbol = "symbol";
    uint64 editionSize = 100;
    uint16 royaltyBPS = 500;
    string memory description = "description";
    string memory imageURI = "imageURI";
    string memory animationURI = "animationURI";

    address payable defaultAdmin = payable(DEFAULT_OWNER_ADDRESS);
    address payable fundsRecipient = payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS);

    bytes memory metadataInitializer = abi.encode(description, imageURI, animationURI);

    // Setup sale config
    IHolographERC721Drop.SalesConfiguration memory saleConfig = IHolographERC721Drop.SalesConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 0,
      presaleEnd: 0,
      publicSalePrice: 0.1 ether,
      maxSalePurchasePerAddress: 0,
      presaleMerkleRoot: bytes32(0)
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
    bytes[] memory setupCalls;

    // Create initializer
    DropInitializer memory initializer = DropInitializer(
      address(0), // HolographFeeManager,
      address(0), // HolographERC721TransferHelper
      address(0), // FactoryUpgradeGate,
      DEFAULT_HOLOGRAPH_DAO_ADDRESS,
      name,
      symbol,
      defaultAdmin,
      fundsRecipient,
      editionSize,
      royaltyBPS,
      setupCalls,
      address(0), // editionMetadataRenderer,
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
    assertEq(alice, signer);

    bool isSigner = _verifySigner(r, s, v, hash, alice);
    assertEq(isSigner, true);

    // Pass the payload hash, with the signature, and signer's address
    HolographFactory factory = HolographFactory(payable(0x5Db4dB97fDfFB29cD85eA5484C3722095c413fc7)); // TODO: Replace with `getFactoryAddress`'

    console.log("Factory address: ", address(factory));
    console.log("Holograph address: ", address(factory.getHolograph()));
    console.log("Registry address: ", address(factory.getRegistry()));
    console.log("Signer address: ", signer);

    vm.recordLogs();
    factory.deployHolographableContract(config, signature, alice);
    Vm.Log[] memory entries = vm.getRecordedLogs();
    address newDropAddress = address(uint160(uint256(entries[0].topics[1])));
    console.log("New drop address: ", newDropAddress);

    // TODO: Test checks start here - Reenable when ready
    // ERC721Drop drop = ERC721Drop(payable(deployedEdition));
    // vm.startPrank(DEFAULT_FUNDS_RECIPIENT_ADDRESS);
    // vm.deal(DEFAULT_FUNDS_RECIPIENT_ADDRESS, 10 ether);
    // drop.purchase{value: 1 ether}(10);
    // assertEq(drop.totalSupply(), 10);
  }

  // function test_CreateDrop() public {
  //   address deployedDrop = creator.createDrop(
  //     "name",
  //     "symbol",
  //     DEFAULT_FUNDS_RECIPIENT_ADDRESS,
  //     1000,
  //     100,
  //     DEFAULT_FUNDS_RECIPIENT_ADDRESS,
  //     IHolographERC721Drop.SalesConfiguration({
  //       publicSaleStart: 0,
  //       publicSaleEnd: type(uint64).max,
  //       presaleStart: 0,
  //       presaleEnd: 0,
  //       publicSalePrice: 0,
  //       maxSalePurchasePerAddress: 0,
  //       presaleMerkleRoot: bytes32(0)
  //     }),
  //     "metadata_uri",
  //     "metadata_contract_uri"
  //   );
  //   ERC721Drop drop = ERC721Drop(payable(deployedDrop));
  //   drop.purchase(10);
  //   assertEq(drop.totalSupply(), 10);
  // }

  // function test_CreateGenericDrop() public {
  //   MockMetadataRenderer mockRenderer = new MockMetadataRenderer();
  //   address deployedDrop = creator.setupDropsContract(
  //     "name",
  //     "symbol",
  //     DEFAULT_FUNDS_RECIPIENT_ADDRESS,
  //     1000,
  //     100,
  //     DEFAULT_FUNDS_RECIPIENT_ADDRESS,
  //     IHolographERC721Drop.SalesConfiguration({
  //       publicSaleStart: 0,
  //       publicSaleEnd: type(uint64).max,
  //       presaleStart: 0,
  //       presaleEnd: 0,
  //       publicSalePrice: 0,
  //       maxSalePurchasePerAddress: 0,
  //       presaleMerkleRoot: bytes32(0)
  //     }),
  //     mockRenderer,
  //     ""
  //   );
  //   ERC721Drop drop = ERC721Drop(payable(deployedDrop));
  //   ERC721Drop.SaleDetails memory saleDetails = drop.saleDetails();
  //   assertEq(saleDetails.publicSaleStart, 0);
  //   assertEq(saleDetails.publicSaleEnd, type(uint64).max);
  //   vm.expectRevert(IERC721AUpgradeable.URIQueryForNonexistentToken.selector);
  //   drop.tokenURI(1);
  //   assertEq(drop.contractURI(), "DEMO");
  //   drop.purchase(1);
  //   assertEq(drop.tokenURI(1), "DEMO");
  // }
}
