// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

/**
 * @notice This allows this contract to receive native currency funds from other contracts
 * Uses event logging for UI reasons.
 */
contract FundsReceiver {
  event FundsReceived(address indexed source, uint256 amount);

  receive() external payable {
    emit FundsReceived(msg.sender, msg.value);
  }
}
