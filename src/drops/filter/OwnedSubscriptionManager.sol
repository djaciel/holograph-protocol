// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IOperatorFilterRegistry} from "../../../contracts/drops/interfaces/IOperatorFilterRegistry.sol";
import {OwnableWithConfirmation} from "../../../contracts/drops/utils/OwnableWithConfirmation.sol";

contract OwnedSubscriptionManager is OwnableWithConfirmation {
  IOperatorFilterRegistry immutable registry = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  constructor(address _initialOwner) OwnableWithConfirmation(_initialOwner) {
    registry.register(address(this));
  }
}
