// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

struct TokenERC20 {
    string name;
    string symbol;
    address tokenAddress;
    uint8 decimals;
    uint256 balance;
}
