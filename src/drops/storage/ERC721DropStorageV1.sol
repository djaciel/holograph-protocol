// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IHolographERC721Drop} from "../interfaces/IHolographERC721Drop.sol";

contract ERC721DropStorageV1 {
  /// @notice Configuration for NFT minting contract storage
  IHolographERC721Drop.Configuration public config;

  /// @notice Sales configuration
  IHolographERC721Drop.SalesConfiguration public salesConfig;

  /// @dev Mapping for presale mint counts by address to allow public mint limit
  mapping(address => uint256) public presaleMintsByAddress;
}
