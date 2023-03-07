// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

import {IHolographERC721Drop} from "../interface/IHolographERC721Drop.sol";

contract MetadataRenderAdminCheck {
  error Access_OnlyAdmin();

  /// @notice Modifier to require the sender to be an admin
  /// @param target address that the user wants to modify
  modifier requireSenderAdmin(address target) {
    if (target != msg.sender && !IHolographERC721Drop(target).isAdmin(msg.sender)) {
      revert Access_OnlyAdmin();
    }

    _;
  }
}
