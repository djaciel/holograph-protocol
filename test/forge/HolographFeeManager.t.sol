// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HolographFeeManager} from "../../contracts/drops/HolographFeeManager.sol";
import {MockUser} from "./utils/MockUser.sol";
import {Test} from "forge-std/Test.sol";

contract HolographFeeManagerTest is Test {
  HolographFeeManager feeManager;
  MockUser mockUser;
  address public constant DEFAULT_ADMIN_ADDRESS = address(23499);
  address public constant mediaContract = address(123456);

  function setUp() public {
    feeManager = new HolographFeeManager(1234, DEFAULT_ADMIN_ADDRESS);
    mockUser = new MockUser();
  }

  function test_GetDefaultFee() public {
    (address payable recipient, uint256 feeBps) = feeManager.getWithdrawFeesBps(address(0x0));

    require(recipient == DEFAULT_ADMIN_ADDRESS, "Recipient is wrong");
    require(feeBps == 1234, "Default fee not recognized");
  }

  function test_GetOverrideFee() public {
    vm.prank(DEFAULT_ADMIN_ADDRESS);
    feeManager.setFeeOverride(address(0x1234), 1444);

    (address payable recipient, uint256 feeBps) = feeManager.getWithdrawFeesBps(address(0x1234));

    require(recipient == DEFAULT_ADMIN_ADDRESS, "Recipient is wrong");
    require(feeBps == 1444, "Fee not recognized");
  }

  function test_UpdateOwner() public {
    address newOwnerAddress = address(429924);
    vm.prank(DEFAULT_ADMIN_ADDRESS);
    feeManager.transferOwnership(newOwnerAddress);

    (address payable recipient, uint256 feeBps) = feeManager.getWithdrawFeesBps(mediaContract);

    require(recipient == newOwnerAddress, "Recipient is wrong");
    require(feeBps == 1234, "Default fee not recognized");
  }

  function test_NewOwnerCanUpdate() public {
    vm.prank(DEFAULT_ADMIN_ADDRESS);
    feeManager.transferOwnership(address(mockUser));

    {
      (address payable recipient, uint256 feeBps) = feeManager.getWithdrawFeesBps(mediaContract);
      require(recipient == address(mockUser), "Recipient is wrong");
      require(feeBps == 1234, "Default fee not recognized");
    }

    vm.prank(address(mockUser));
    feeManager.setFeeOverride(mediaContract, 1200);

    {
      (address payable recipient, uint256 feeBps) = feeManager.getWithdrawFeesBps(mediaContract);
      require(recipient == address(mockUser), "Recipient is wrong");
      require(feeBps == 1200, "Updated fee is wrong");
    }
  }

  function test_CannotSeeFeeTooHigh() public {
    vm.expectRevert("Fee too high (not greater than 20%)");
    vm.prank(DEFAULT_ADMIN_ADDRESS);
    feeManager.setFeeOverride(mediaContract, 2200);
  }

  function test_WrongUserCannotUpdate() public {
    vm.prank(address(24040));
    vm.expectRevert("Ownable: caller is not the owner");
    feeManager.setFeeOverride(mediaContract, 1000);
  }
}
