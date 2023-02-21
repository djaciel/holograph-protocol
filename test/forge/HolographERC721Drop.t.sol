// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {IERC721AUpgradeable} from "../../contracts/drops/interfaces/IERC721AUpgradeable.sol";

import {DeploymentConfig} from "../../contracts/struct/DeploymentConfig.sol";
import {Verification} from "../../contracts/struct/Verification.sol";
import {DropInitializer} from "../../contracts/struct/DropInitializer.sol";

import {HolographFactory} from "../../contracts/HolographFactory.sol";

import {HolographERC721Drop} from "../../contracts/drops/HolographERC721Drop.sol";
import {HolographFeeManager} from "../../contracts/drops/HolographFeeManager.sol";
import {MockMetadataRenderer} from "./metadata/MockMetadataRenderer.sol";

import {Constants} from "./utils/Constants.sol";

import {DummyMetadataRenderer} from "./utils/DummyMetadataRenderer.sol";
import {DummyCustomContract} from "../../contracts/drops/utils/DummyCustomContract.sol";
import {MockUser} from "./utils/MockUser.sol";
import {IOperatorFilterRegistry} from "../../contracts/drops/interfaces/IOperatorFilterRegistry.sol";
import {IMetadataRenderer} from "../../contracts/drops/interfaces/IMetadataRenderer.sol";
import {IHolographERC721Drop} from "../../contracts/drops/interfaces/IHolographERC721Drop.sol";
import {OperatorFilterRegistry} from "./filter/OperatorFilterRegistry.sol";
import {OperatorFilterRegistryErrorsAndEvents} from "./filter/OperatorFilterRegistryErrorsAndEvents.sol";
import {OwnedSubscriptionManager} from "../../contracts/drops/filter/OwnedSubscriptionManager.sol";
import {DropMetadataRenderer} from "../../contracts/drops/metadata/DropMetadataRenderer.sol";
import {EditionMetadataRenderer} from "../../contracts/drops/metadata/EditionMetadataRenderer.sol";

contract HolographERC721DropTest is Test {
  /// @notice Event emitted when the funds are withdrawn from the minting contract
  /// @param withdrawnBy address that issued the withdraw
  /// @param withdrawnTo address that the funds were withdrawn to
  /// @param amount amount that was withdrawn
  /// @param feeRecipient user getting withdraw fee (if any)
  /// @param feeAmount amount of the fee getting sent (if any)
  event FundsWithdrawn(
    address indexed withdrawnBy,
    address indexed withdrawnTo,
    uint256 amount,
    address feeRecipient,
    uint256 feeAmount
  );

  address public alice;
  MockUser public mockUser;
  HolographFeeManager public feeManager;

  HolographERC721Drop public erc721Drop;

  DummyMetadataRenderer public dummyRenderer = new DummyMetadataRenderer();
  EditionMetadataRenderer public editionMetadataRenderer;
  DropMetadataRenderer public dropMetadataRenderer;

  address public constant DEFAULT_OWNER_ADDRESS = address(0x1);
  address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS = payable(address(0x2));
  address payable public constant HOLOGRAPH_TREASURY_ADDRESS = payable(address(0x3));
  address payable constant TEST_ACCOUNT = payable(address(0x888));
  address public constant MEDIA_CONTRACT = address(0x666);
  address public ownedSubscriptionManager;

  struct Configuration {
    IMetadataRenderer metadataRenderer;
    uint64 editionSize;
    uint16 royaltyBPS;
    address payable fundsRecipient;
  }

  modifier setupTestDrop(uint64 editionSize) {
    // TODO: Remove this old initializer and figure out how to support both drops and edition metadata initialization
    // NOTE: It might be possible to use the same enforcer for both drops and editions,
    // but we would have to encode the metadataRendererInit differently depending on the type of drop or it can use the DummyMetadataRenderer
    dummyRenderer = new DummyMetadataRenderer();
    DropInitializer memory initializer = DropInitializer({
      holographFeeManager: address(feeManager),
      holographERC721TransferHelper: address(0x1234),
      marketFilterAddress: address(0x0),
      contractName: "Test NFT",
      contractSymbol: "TNFT",
      initialOwner: DEFAULT_OWNER_ADDRESS,
      fundsRecipient: payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS),
      editionSize: editionSize,
      royaltyBPS: 800,
      setupCalls: new bytes[](0),
      metadataRenderer: address(dummyRenderer),
      metadataRendererInit: ""
      // metadataRenderer: address(dropMetadataRenderer),
      // metadataRendererInit: abi.encode("description", "imageURI", "animationURI")
    });

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

    // Deploy the drop / edition
    vm.recordLogs();
    factory.deployHolographableContract(config, signature, alice); // Pass the payload hash, with the signature, and signer's address
    Vm.Log[] memory entries = vm.getRecordedLogs();
    address newDropAddress = address(uint160(uint256(entries[2].topics[1])));

    // Connect the drop implementation to the drop proxy address
    erc721Drop = HolographERC721Drop(payable(newDropAddress));

    _;
  }

  // TODO: Determine if this functionality is needed
  // modifier factoryWithSubscriptionAddress(address subscriptionAddress) {
  //   uint64 editionSize = 10;
  //   vm.prank(HOLOGRAPH_TREASURY_ADDRESS);
  //   DropInitializer memory initializer = DropInitializer({
  //     holographFeeManager: address(feeManager),
  //     holographERC721TransferHelper: address(0x1234),
  //     factoryUpgradeGate: address(factoryUpgradeGate),
  //     marketFilterAddress: address(subscriptionAddress),
  //     contractName: "Test NFT",
  //     contractSymbol: "TNFT",
  //     initialOwner: DEFAULT_OWNER_ADDRESS,
  //     fundsRecipient: payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS),
  //     editionSize: editionSize,
  //     royaltyBPS: 800,
  //     setupCalls: new bytes[](0),
  //     metadataRenderer: address(dummyRenderer),
  //     metadataRendererInit: ""
  //   });

  //   erc721DropProxy = new HolographERC721DropProxy();
  //   erc721DropProxy.init(abi.encode(new ERC721Drop(), abi.encode(initializer)));
  //   address payable newDrop = payable(address(erc721DropProxy));
  //   erc721Drop = ERC721Drop(newDrop);

  //   _;
  // }

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
    vm.etch(address(Constants.getOpenseaRoyaltiesRegistry()), address(new OperatorFilterRegistry()).code);
    ownedSubscriptionManager = address(new OwnedSubscriptionManager(address(0x666)));
    vm.prank(HOLOGRAPH_TREASURY_ADDRESS);
    feeManager.setFeeOverride(address(erc721Drop), 500);

    dropMetadataRenderer = new DropMetadataRenderer();
  }

  function test_DeployHolographDrop() public {
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
    require(signer == alice, "Invalid signature");

    HolographFactory factory = HolographFactory(payable(Constants.getHolographFactory()));

    // Deploy the drop / edition
    vm.recordLogs();
    factory.deployHolographableContract(config, signature, alice); // Pass the payload hash, with the signature, and signer's address
    Vm.Log[] memory entries = vm.getRecordedLogs();
    address newDropAddress = address(uint160(uint256(entries[5].topics[1])));
    HolographERC721Drop drop = HolographERC721Drop(payable(newDropAddress));
  }

  function test_Init() public setupTestDrop(10) {
    require(erc721Drop.owner() == DEFAULT_OWNER_ADDRESS, "Default owner set wrong");
    (IMetadataRenderer renderer, uint64 editionSize, uint16 royaltyBPS, address payable fundsRecipient) = erc721Drop
      .config();
    require(address(renderer) == address(dummyRenderer), "Renderer is wrong");
    require(editionSize == 10, "EditionSize is wrong");

    require(royaltyBPS == 800, "RoyaltyBPS is wrong");
    require(fundsRecipient == payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS), "FundsRecipient is wrong");
    string memory name = erc721Drop.name();
    string memory symbol = erc721Drop.symbol();
    require(keccak256(bytes(name)) == keccak256(bytes("Test NFT")));
    require(keccak256(bytes(symbol)) == keccak256(bytes("TNFT")));
    vm.expectRevert("HOLOGRAPHER: already initialized");
    DropInitializer memory initializer = DropInitializer({
      holographFeeManager: address(feeManager),
      holographERC721TransferHelper: address(0x1234),
      marketFilterAddress: address(0x0),
      contractName: "Test NFT",
      contractSymbol: "TNFT",
      initialOwner: DEFAULT_OWNER_ADDRESS,
      fundsRecipient: payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS),
      editionSize: editionSize,
      royaltyBPS: 800,
      setupCalls: new bytes[](0),
      metadataRenderer: address(dummyRenderer),
      metadataRendererInit: ""
    });
    erc721Drop.init(abi.encode(initializer, false));
  }

  // TODO: These tests are for functionality that might no longer be supported
  // function test_SubscriptionEnabled()
  //   public
  //   factoryWithSubscriptionAddress(ownedSubscriptionManager)
  //   setupTestDrop(10)
  // {
  //   IOperatorFilterRegistry operatorFilterRegistry = IOperatorFilterRegistry(
  //     0x000000000000AAeB6D7670E522A718067333cd4E
  //   );
  //   vm.startPrank(address(0x666));
  //   operatorFilterRegistry.updateOperator(ownedSubscriptionManager, address(0xcafeea3), true);
  //   vm.stopPrank();
  //   vm.startPrank(DEFAULT_OWNER_ADDRESS);

  //   console.log("subscriptionAddress: %s", erc721Drop.marketFilterAddress());
  //   erc721Drop.manageMarketFilterSubscription(true);
  //   erc721Drop.adminMint(DEFAULT_OWNER_ADDRESS, 10);
  //   erc721Drop.setApprovalForAll(address(0xcafeea3), true);
  //   vm.stopPrank();
  //   vm.prank(address(0xcafeea3));
  //   vm.expectRevert(
  //     abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, address(0xcafeea3))
  //   );
  //   erc721Drop.transferFrom(DEFAULT_OWNER_ADDRESS, address(0x666), 1);
  //   vm.prank(DEFAULT_OWNER_ADDRESS);
  //   erc721Drop.manageMarketFilterSubscription(false);
  //   vm.prank(address(0xcafeea3));
  //   erc721Drop.transferFrom(DEFAULT_OWNER_ADDRESS, address(0x666), 1);
  // }

  // function test_OnlyAdminEnableSubscription()
  //   public
  //   factoryWithSubscriptionAddress(ownedSubscriptionManager)
  //   setupTestDrop(10)
  // {
  //   vm.startPrank(address(0xcafecafe));
  //   vm.expectRevert(IHolographERC721Drop.Access_OnlyAdmin.selector);
  //   erc721Drop.manageMarketFilterSubscription(true);
  //   vm.stopPrank();
  // }

  // function test_ProxySubscriptionAccessOnlyAdmin()
  //   public
  //   factoryWithSubscriptionAddress(ownedSubscriptionManager)
  //   setupTestDrop(10)
  // {
  //   bytes memory baseCall = abi.encodeWithSelector(
  //     IOperatorFilterRegistry.register.selector,
  //     address(erc721Drop)
  //   );
  //   vm.startPrank(address(0xcafecafe));
  //   vm.expectRevert(IHolographERC721Drop.Access_OnlyAdmin.selector);
  //   erc721Drop.updateMarketFilterSettings(baseCall);
  //   vm.stopPrank();
  // }

  // function test_ProxySubscriptionAccess()
  //   public
  //   factoryWithSubscriptionAddress(ownedSubscriptionManager)
  //   setupTestDrop(10)
  // {
  //   vm.startPrank(address(DEFAULT_OWNER_ADDRESS));
  //   bytes memory baseCall = abi.encodeWithSelector(
  //     IOperatorFilterRegistry.register.selector,
  //     address(erc721Drop)
  //   );
  //   erc721Drop.updateMarketFilterSettings(baseCall);
  //   vm.stopPrank();
  // }

  function test_Purchase(uint64 amount) public setupTestDrop(10) {
    // We assume that the amount is at least one and less than or equal to the edition size given in modifier
    vm.assume(amount > 0 && amount <= 10);
    vm.prank(DEFAULT_OWNER_ADDRESS);

    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 0,
      presaleEnd: 0,
      publicSalePrice: 1 ether,
      maxSalePurchasePerAddress: uint32(amount),
      presaleMerkleRoot: bytes32(0)
    });

    vm.prank(address(TEST_ACCOUNT));
    vm.deal(address(TEST_ACCOUNT), uint256(amount) * 1 ether);
    erc721Drop.purchase{value: amount * 1 ether}(amount);

    assertEq(erc721Drop.saleDetails().maxSupply, 10);
    assertEq(erc721Drop.saleDetails().totalMinted, amount);
    require(erc721Drop.ownerOf(1) == address(TEST_ACCOUNT), "owner is wrong for new minted token");
    assertEq(address(erc721Drop).balance, amount * 1 ether);
  }

  function test_PurchaseTime() public setupTestDrop(10) {
    uint104 price = 0.1 ether;
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: 0,
      presaleStart: 0,
      presaleEnd: 0,
      publicSalePrice: price,
      maxSalePurchasePerAddress: 2,
      presaleMerkleRoot: bytes32(0)
    });

    assertTrue(!erc721Drop.saleDetails().publicSaleActive);

    vm.deal(address(TEST_ACCOUNT), price);
    vm.prank(address(TEST_ACCOUNT));
    vm.expectRevert(IHolographERC721Drop.Sale_Inactive.selector);
    erc721Drop.purchase{value: price}(1);

    assertEq(erc721Drop.saleDetails().maxSupply, 10);
    assertEq(erc721Drop.saleDetails().totalMinted, 0);

    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 9 * 3600,
      publicSaleEnd: 11 * 3600,
      presaleStart: 0,
      presaleEnd: 0,
      maxSalePurchasePerAddress: 20,
      publicSalePrice: price,
      presaleMerkleRoot: bytes32(0)
    });

    assertTrue(!erc721Drop.saleDetails().publicSaleActive);
    // jan 1st 1980
    vm.warp(10 * 3600);
    assertTrue(erc721Drop.saleDetails().publicSaleActive);
    assertTrue(!erc721Drop.saleDetails().presaleActive);

    vm.prank(address(TEST_ACCOUNT));
    erc721Drop.purchase{value: price}(1);

    assertEq(erc721Drop.saleDetails().totalMinted, 1);
    assertEq(erc721Drop.ownerOf(1), address(TEST_ACCOUNT));
  }

  function test_MintAdmin() public setupTestDrop(10) {
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.adminMint(DEFAULT_OWNER_ADDRESS, 1);
    assertEq(erc721Drop.saleDetails().maxSupply, 10);
    assertEq(erc721Drop.saleDetails().totalMinted, 1);
    require(erc721Drop.ownerOf(1) == DEFAULT_OWNER_ADDRESS, "Owner is wrong for new minted token");
  }

  function test_MintMulticall() public setupTestDrop(10) {
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    bytes[] memory calls = new bytes[](3);
    calls[0] = abi.encodeWithSelector(IHolographERC721Drop.adminMint.selector, DEFAULT_OWNER_ADDRESS, 5);
    calls[1] = abi.encodeWithSelector(IHolographERC721Drop.adminMint.selector, address(0x123), 3);
    calls[2] = abi.encodeWithSelector(IHolographERC721Drop.saleDetails.selector);
    bytes[] memory results = erc721Drop.multicall(calls);

    (bool saleActive, bool presaleActive, uint256 publicSalePrice, , , , , , , , ) = abi.decode(
      results[2],
      (bool, bool, uint256, uint64, uint64, uint64, uint64, bytes32, uint256, uint256, uint256)
    );
    assertTrue(!saleActive);
    assertTrue(!presaleActive);
    assertEq(publicSalePrice, 0);
    uint256 firstMintedId = abi.decode(results[0], (uint256));
    uint256 secondMintedId = abi.decode(results[1], (uint256));
    assertEq(firstMintedId, 5);
    assertEq(secondMintedId, 8);
  }

  function test_UpdatePriceMulticall() public setupTestDrop(10) {
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    bytes[] memory calls = new bytes[](3);
    calls[0] = abi.encodeWithSelector(
      IHolographERC721Drop.setSaleConfiguration.selector,
      0.1 ether,
      2,
      0,
      type(uint64).max,
      0,
      0,
      bytes32(0)
    );
    calls[1] = abi.encodeWithSelector(IHolographERC721Drop.adminMint.selector, address(0x999), 3);
    calls[2] = abi.encodeWithSelector(IHolographERC721Drop.adminMint.selector, address(0x123), 3);
    bytes[] memory results = erc721Drop.multicall(calls);

    IHolographERC721Drop.SaleDetails memory saleDetails = erc721Drop.saleDetails();

    assertTrue(saleDetails.publicSaleActive);
    assertTrue(!saleDetails.presaleActive);
    assertEq(saleDetails.publicSalePrice, 0.1 ether);
    uint256 firstMintedId = abi.decode(results[1], (uint256));
    uint256 secondMintedId = abi.decode(results[2], (uint256));
    assertEq(firstMintedId, 3);
    assertEq(secondMintedId, 6);
    vm.stopPrank();
    vm.startPrank(address(0x111));
    vm.deal(address(0x111), 0.3 ether);
    erc721Drop.purchase{value: 0.2 ether}(2);
    assertEq(erc721Drop.balanceOf(address(0x111)), 2);
    vm.stopPrank();
  }

  function test_MintWrongValue() public setupTestDrop(10) {
    vm.deal(address(TEST_ACCOUNT), 1 ether);
    vm.prank(address(TEST_ACCOUNT));
    vm.expectRevert(IHolographERC721Drop.Sale_Inactive.selector);
    erc721Drop.purchase{value: 0.12 ether}(1);
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 0,
      presaleEnd: 0,
      publicSalePrice: 0.15 ether,
      maxSalePurchasePerAddress: 2,
      presaleMerkleRoot: bytes32(0)
    });
    vm.prank(address(TEST_ACCOUNT));
    vm.expectRevert(abi.encodeWithSelector(IHolographERC721Drop.Purchase_WrongPrice.selector, 0.15 ether));
    erc721Drop.purchase{value: 0.12 ether}(1);
  }

  //   function test_Withdraw(uint128 amount) public setupTestDrop(10) {
  //     vm.assume(amount > 0.01 ether);
  //     vm.deal(address(erc721Drop), amount);
  //     vm.prank(DEFAULT_OWNER_ADDRESS);
  //     vm.expectEmit(true, true, true, true);
  //     uint256 leftoverFunds = amount - (amount * 1) / 20;
  //     emit FundsWithdrawn(
  //       DEFAULT_OWNER_ADDRESS,
  //       DEFAULT_FUNDS_RECIPIENT_ADDRESS,
  //       leftoverFunds,
  //       HOLOGRAPH_TREASURY_ADDRESS,
  //       (amount * 1) / 20
  //     );
  //     erc721Drop.withdraw();
  //
  //     (, uint256 feeBps) = feeManager.getWithdrawFeesBps(address(erc721Drop));
  //     assertEq(feeBps, 500);
  //
  //     assertTrue(
  //       HOLOGRAPH_TREASURY_ADDRESS.balance < ((uint256(amount) * 1_000 * 5) / 100000) + 2 ||
  //         HOLOGRAPH_TREASURY_ADDRESS.balance > ((uint256(amount) * 1_000 * 5) / 100000) + 2
  //     );
  //     assertTrue(
  //       DEFAULT_FUNDS_RECIPIENT_ADDRESS.balance > ((uint256(amount) * 1_000 * 95) / 100000) - 2 ||
  //         DEFAULT_FUNDS_RECIPIENT_ADDRESS.balance < ((uint256(amount) * 1_000 * 95) / 100000) + 2
  //     );
  //   }

  function test_MintLimit(uint8 limit) public setupTestDrop(5000) {
    // set limit to speed up tests
    vm.assume(limit > 0 && limit < 50);
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 0,
      presaleEnd: 0,
      publicSalePrice: 0.1 ether,
      maxSalePurchasePerAddress: limit,
      presaleMerkleRoot: bytes32(0)
    });
    vm.deal(address(TEST_ACCOUNT), 1_000_000 ether);
    vm.prank(address(TEST_ACCOUNT));
    erc721Drop.purchase{value: 0.1 ether * uint256(limit)}(limit);

    assertEq(erc721Drop.saleDetails().totalMinted, limit);

    vm.deal(address(0x444), 1_000_000 ether);
    vm.prank(address(0x444));
    vm.expectRevert(IHolographERC721Drop.Purchase_TooManyForAddress.selector);
    erc721Drop.purchase{value: 0.1 ether * (uint256(limit) + 1)}(uint256(limit) + 1);

    assertEq(erc721Drop.saleDetails().totalMinted, limit);
  }

  function testSetSalesConfiguration() public setupTestDrop(10) {
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 0,
      presaleEnd: 100,
      publicSalePrice: 0.1 ether,
      maxSalePurchasePerAddress: 10,
      presaleMerkleRoot: bytes32(0)
    });

    (, , , , , uint64 presaleEndLookup, ) = erc721Drop.salesConfig();
    assertEq(presaleEndLookup, 100);

    address SALES_MANAGER_ADDR = address(0x11002);
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.grantRole(erc721Drop.SALES_MANAGER_ROLE(), SALES_MANAGER_ADDR);
    vm.stopPrank();
    vm.prank(SALES_MANAGER_ADDR);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 100,
      presaleEnd: 0,
      publicSalePrice: 0.1 ether,
      maxSalePurchasePerAddress: 1003,
      presaleMerkleRoot: bytes32(0)
    });

    (, , , , uint64 presaleStartLookup2, uint64 presaleEndLookup2, ) = erc721Drop.salesConfig();
    assertEq(presaleEndLookup2, 0);
    assertEq(presaleStartLookup2, 100);
  }

  function test_GlobalLimit(uint16 limit) public setupTestDrop(uint64(limit)) {
    vm.assume(limit > 0);
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.adminMint(DEFAULT_OWNER_ADDRESS, limit);
    vm.expectRevert(IHolographERC721Drop.Mint_SoldOut.selector);
    erc721Drop.adminMint(DEFAULT_OWNER_ADDRESS, 1);
  }

  //   function test_WithdrawNotAllowed() public setupTestDrop(10) {
  //     vm.expectRevert(IHolographERC721Drop.Access_WithdrawNotAllowed.selector);
  //     erc721Drop.withdraw();
  //   }

  function test_InvalidFinalizeOpenEdition() public setupTestDrop(5) {
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 0,
      presaleEnd: 0,
      publicSalePrice: 0.2 ether,
      presaleMerkleRoot: bytes32(0),
      maxSalePurchasePerAddress: 5
    });
    erc721Drop.purchase{value: 0.6 ether}(3);
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.adminMint(address(0x1234), 2);
    vm.prank(DEFAULT_OWNER_ADDRESS);
    vm.expectRevert(IHolographERC721Drop.Admin_UnableToFinalizeNotOpenEdition.selector);
    erc721Drop.finalizeOpenEdition();
  }

  function test_ValidFinalizeOpenEdition() public setupTestDrop(type(uint64).max) {
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 0,
      presaleEnd: 0,
      publicSalePrice: 0.2 ether,
      presaleMerkleRoot: bytes32(0),
      maxSalePurchasePerAddress: 10
    });
    erc721Drop.purchase{value: 0.6 ether}(3);
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.adminMint(address(0x1234), 2);
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.finalizeOpenEdition();
    vm.expectRevert(IHolographERC721Drop.Mint_SoldOut.selector);
    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.adminMint(address(0x1234), 2);
    vm.expectRevert(IHolographERC721Drop.Mint_SoldOut.selector);
    erc721Drop.purchase{value: 0.6 ether}(3);
  }

  function test_AdminMint() public setupTestDrop(10) {
    address minter = address(0x32402);
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.adminMint(DEFAULT_OWNER_ADDRESS, 1);
    require(erc721Drop.balanceOf(DEFAULT_OWNER_ADDRESS) == 1, "Wrong balance");
    erc721Drop.grantRole(erc721Drop.MINTER_ROLE(), minter);
    vm.stopPrank();
    vm.prank(minter);
    erc721Drop.adminMint(minter, 1);
    require(erc721Drop.balanceOf(minter) == 1, "Wrong balance");
    assertEq(erc721Drop.saleDetails().totalMinted, 2);
  }

  function test_EditionSizeZero() public setupTestDrop(0) {
    address minter = address(0x32402);
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    vm.expectRevert(IHolographERC721Drop.Mint_SoldOut.selector);
    erc721Drop.adminMint(DEFAULT_OWNER_ADDRESS, 1);
    erc721Drop.grantRole(erc721Drop.MINTER_ROLE(), minter);
    vm.stopPrank();
    vm.prank(minter);
    vm.expectRevert(IHolographERC721Drop.Mint_SoldOut.selector);
    erc721Drop.adminMint(minter, 1);

    vm.prank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.setSaleConfiguration({
      publicSaleStart: 0,
      publicSaleEnd: type(uint64).max,
      presaleStart: 0,
      presaleEnd: 0,
      publicSalePrice: 1,
      maxSalePurchasePerAddress: 2,
      presaleMerkleRoot: bytes32(0)
    });

    vm.deal(address(TEST_ACCOUNT), uint256(1) * 2);
    vm.prank(address(TEST_ACCOUNT));
    vm.expectRevert(IHolographERC721Drop.Mint_SoldOut.selector);
    erc721Drop.purchase{value: 1}(1);
  }

  // // test Admin airdrop
  function test_AdminMintAirdrop() public setupTestDrop(1000) {
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    address[] memory toMint = new address[](4);
    toMint[0] = address(0x10);
    toMint[1] = address(0x11);
    toMint[2] = address(0x12);
    toMint[3] = address(0x13);
    erc721Drop.adminMintAirdrop(toMint);
    assertEq(erc721Drop.saleDetails().totalMinted, 4);
    assertEq(erc721Drop.balanceOf(address(0x10)), 1);
    assertEq(erc721Drop.balanceOf(address(0x11)), 1);
    assertEq(erc721Drop.balanceOf(address(0x12)), 1);
    assertEq(erc721Drop.balanceOf(address(0x13)), 1);
  }

  function test_AdminMintAirdropFails() public setupTestDrop(1000) {
    vm.startPrank(address(0x10));
    address[] memory toMint = new address[](4);
    toMint[0] = address(0x10);
    toMint[1] = address(0x11);
    toMint[2] = address(0x12);
    toMint[3] = address(0x13);
    bytes32 minterRole = erc721Drop.MINTER_ROLE();
    vm.expectRevert(abi.encodeWithSignature("Access_MissingRoleOrAdmin(bytes32)", minterRole));
    erc721Drop.adminMintAirdrop(toMint);
  }

  // test admin mint non-admin permissions
  function test_AdminMintBatch() public setupTestDrop(1000) {
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.adminMint(DEFAULT_OWNER_ADDRESS, 100);
    assertEq(erc721Drop.saleDetails().totalMinted, 100);
    assertEq(erc721Drop.balanceOf(DEFAULT_OWNER_ADDRESS), 100);
  }

  function test_AdminMintBatchFails() public setupTestDrop(1000) {
    vm.startPrank(address(0x10));
    bytes32 role = erc721Drop.MINTER_ROLE();
    vm.expectRevert(abi.encodeWithSignature("Access_MissingRoleOrAdmin(bytes32)", role));
    erc721Drop.adminMint(address(0x10), 100);
  }

  function test_Burn() public setupTestDrop(10) {
    address minter = address(0x32402);
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.grantRole(erc721Drop.MINTER_ROLE(), minter);
    vm.stopPrank();
    vm.startPrank(minter);
    address[] memory airdrop = new address[](1);
    airdrop[0] = minter;
    erc721Drop.adminMintAirdrop(airdrop);
    erc721Drop.burn(1);
    vm.stopPrank();
  }

  function test_BurnNonOwner() public setupTestDrop(10) {
    address minter = address(0x32402);
    vm.startPrank(DEFAULT_OWNER_ADDRESS);
    erc721Drop.grantRole(erc721Drop.MINTER_ROLE(), minter);
    vm.stopPrank();
    vm.startPrank(minter);
    address[] memory airdrop = new address[](1);
    airdrop[0] = minter;
    erc721Drop.adminMintAirdrop(airdrop);
    vm.stopPrank();

    vm.prank(address(0x1));
    vm.expectRevert(IERC721AUpgradeable.TransferCallerNotOwnerNorApproved.selector);
    erc721Drop.burn(1);
  }

  // // TODO: Add test burn failure state for users that don't own the token

  function test_EIP165() public setupTestDrop(10) {
    require(erc721Drop.supportsInterface(0x01ffc9a7), "supports 165");
    require(erc721Drop.supportsInterface(0x80ac58cd), "supports 721");
    require(erc721Drop.supportsInterface(0x5b5e139f), "supports 721-metdata");
    require(erc721Drop.supportsInterface(0x2a55205a), "supports 2981");
    require(!erc721Drop.supportsInterface(0x0000000), "doesnt allow non-interface");
  }

  // TEST HELPERS
  function getDeploymentConfig(DropInitializer memory initializer) public returns (DeploymentConfig memory) {
    bytes memory bytecode = abi.encodePacked(vm.getCode("DummyCustomContract.sol:DummyCustomContract"));
    return
      DeploymentConfig({
        contractType: 0x00000000000000000000000000486F6C6F677261706845524337323144726F70, // HolographERC721Drop
        chainType: 1338, // holograph.getChainId(),
        salt: 0x0000000000000000000000000000000000000000000000000000000000000001, // random salt from user
        byteCode: bytecode, // for custom contract is not used
        initCode: abi.encode(initializer, false) // init code is used to initialize the ERC721Drop enforcer
      });
  }
}
