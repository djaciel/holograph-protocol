// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Test} from "forge-std/Test.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";

import {IHolographERC721Drop} from "../../contracts/drops/interfaces/IHolographERC721Drop.sol";
import {HolographERC721Drop} from "../../contracts/drops/HolographERC721Drop.sol";
import {HolographFeeManager} from "../../contracts/drops/HolographFeeManager.sol";
import {DummyMetadataRenderer} from "./utils/DummyMetadataRenderer.sol";
import {MockUser} from "./utils/MockUser.sol";
import {IMetadataRenderer} from "../../contracts/drops/interfaces/IMetadataRenderer.sol";
import {FactoryUpgradeGate} from "../../contracts/drops/FactoryUpgradeGate.sol";
import {HolographERC721DropProxy} from "../../contracts/drops/HolographERC721DropProxy.sol";

contract HolographERC721DropTest is Test {
  HolographERC721Drop holographNFTBase;
  MockUser mockUser;
  DummyMetadataRenderer public dummyRenderer = new DummyMetadataRenderer();
  HolographFeeManager public feeManager;
  address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
  address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS = payable(address(0x21303));
  address payable public constant DEFAULT_HOLOGRAPH_DAO_ADDRESS = payable(address(0x999));
  address public constant mediaContract = address(0x123456);

  function setUp() public {}
}
