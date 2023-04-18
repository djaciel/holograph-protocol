// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

import {IOperatorFilterRegistry} from "../../../contracts/drops/interface/IOperatorFilterRegistry.sol";
import {OwnableWithConfirmation} from "../utils/OwnableWithConfirmation.sol";

contract OwnedSubscriptionManager is OwnableWithConfirmation {
  IOperatorFilterRegistry immutable registry = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  constructor(address _initialOwner) OwnableWithConfirmation(_initialOwner) {
    registry.register(address(this));
  }
}
