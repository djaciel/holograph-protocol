// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IHolographFeeManager {
  function getHOLOGRAPHWithdrawFeesBPS(address sender) external returns (address payable, uint256);
}
