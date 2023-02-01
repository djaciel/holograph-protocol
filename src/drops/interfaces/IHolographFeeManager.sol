// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IHolographFeeManager {
  function getWithdrawFeesBps(address sender) external returns (address payable, uint256);
}
