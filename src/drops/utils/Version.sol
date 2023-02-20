// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

contract Version {
  uint32 private immutable __version;

  /// @notice The version of the contract
  /// @return The version ID of this contract implementation
  function contractVersion() external view returns (uint32) {
    return __version;
  }

  constructor(uint32 version) {
    __version = version;
  }
}
