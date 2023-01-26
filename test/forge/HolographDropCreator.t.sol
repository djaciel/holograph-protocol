// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {IMetadataRenderer} from "../../contracts/drops/interfaces/IMetadataRenderer.sol";
import "../../contracts/drops/HolographDropCreator.sol";
import "../../contracts/drops/HolographDropCreatorProxy.sol";
import "../../contracts/drops/HolographFeeManager.sol";
import {MockMetadataRenderer} from "./metadata/MockMetadataRenderer.sol";
import {FactoryUpgradeGate} from "../../contracts/drops/FactoryUpgradeGate.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";

contract HolographDropCreatorTest is Test {
  address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
  address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS = payable(address(0x21303));
  address payable public constant DEFAULT_HOLOGRAPH_DAO_ADDRESS = payable(address(0x999));

  ERC721Drop public erc721Drop;
  HolographDropCreator public impl;
  HolographDropCreator public creator;
  EditionMetadataRenderer public editionMetadataRenderer;
  DropMetadataRenderer public dropMetadataRenderer;

  function setUp() public {
    vm.prank(DEFAULT_HOLOGRAPH_DAO_ADDRESS);
    HolographFeeManager feeManager = new HolographFeeManager(500, DEFAULT_HOLOGRAPH_DAO_ADDRESS);

    // Create implementations
    ERC721Drop erc721Drop = new ERC721Drop();
    editionMetadataRenderer = new EditionMetadataRenderer();
    dropMetadataRenderer = new DropMetadataRenderer();
    HolographDropCreator impl = new HolographDropCreator();
    HolographNFTCreatorProxy creatorProxy = new HolographNFTCreatorProxy();

    // Initialize proxy deployment with actual values
    creatorProxy.init(
      abi.encode(impl, abi.encode(address(erc721Drop), address(editionMetadataRenderer), address(dropMetadataRenderer)))
    );
    address payable creatorProxyAddress = payable(address(creatorProxy));

    // Map proxy out to full contract interface
    creator = HolographDropCreator(creatorProxyAddress);
  }

  function test_CreateEdition() public {
    address deployedEdition = creator.createEdition(
      "name",
      "symbol",
      100,
      500,
      DEFAULT_FUNDS_RECIPIENT_ADDRESS,
      DEFAULT_FUNDS_RECIPIENT_ADDRESS,
      IERC721Drop.SalesConfiguration({
        publicSaleStart: 0,
        publicSaleEnd: type(uint64).max,
        presaleStart: 0,
        presaleEnd: 0,
        publicSalePrice: 0.1 ether,
        maxSalePurchasePerAddress: 0,
        presaleMerkleRoot: bytes32(0)
      }),
      "desc",
      "animation",
      "image"
    );

    ERC721Drop drop = ERC721Drop(payable(deployedEdition));
    vm.startPrank(DEFAULT_FUNDS_RECIPIENT_ADDRESS);
    vm.deal(DEFAULT_FUNDS_RECIPIENT_ADDRESS, 10 ether);
    drop.purchase{value: 1 ether}(10);
    assertEq(drop.totalSupply(), 10);
  }

  function test_CreateDrop() public {
    address deployedDrop = creator.createDrop(
      "name",
      "symbol",
      DEFAULT_FUNDS_RECIPIENT_ADDRESS,
      1000,
      100,
      DEFAULT_FUNDS_RECIPIENT_ADDRESS,
      IERC721Drop.SalesConfiguration({
        publicSaleStart: 0,
        publicSaleEnd: type(uint64).max,
        presaleStart: 0,
        presaleEnd: 0,
        publicSalePrice: 0,
        maxSalePurchasePerAddress: 0,
        presaleMerkleRoot: bytes32(0)
      }),
      "metadata_uri",
      "metadata_contract_uri"
    );
    ERC721Drop drop = ERC721Drop(payable(deployedDrop));
    drop.purchase(10);
    assertEq(drop.totalSupply(), 10);
  }

  function test_CreateGenericDrop() public {
    MockMetadataRenderer mockRenderer = new MockMetadataRenderer();
    address deployedDrop = creator.setupDropsContract(
      "name",
      "symbol",
      DEFAULT_FUNDS_RECIPIENT_ADDRESS,
      1000,
      100,
      DEFAULT_FUNDS_RECIPIENT_ADDRESS,
      IERC721Drop.SalesConfiguration({
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
    ERC721Drop drop = ERC721Drop(payable(deployedDrop));
    ERC721Drop.SaleDetails memory saleDetails = drop.saleDetails();
    assertEq(saleDetails.publicSaleStart, 0);
    assertEq(saleDetails.publicSaleEnd, type(uint64).max);
    vm.expectRevert(IERC721AUpgradeable.URIQueryForNonexistentToken.selector);
    drop.tokenURI(1);
    assertEq(drop.contractURI(), "DEMO");
    drop.purchase(1);
    assertEq(drop.tokenURI(1), "DEMO");
  }
}
