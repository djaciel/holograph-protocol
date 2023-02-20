// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

import {IERC165Upgradeable} from "../interfaces/IERC165Upgradeable.sol";

abstract contract ERC165 is IERC165Upgradeable {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }
}
