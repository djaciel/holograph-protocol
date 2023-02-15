// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {IERC165Upgradeable} from "../interfaces/IERC165Upgradeable.sol";

abstract contract ERC165 is IERC165Upgradeable {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }
}
