// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

/// @notice Return type of specific mint counts and details per address
struct AddressMintDetails {
  /// Number of total mints from the given address
  uint256 totalMints;
  /// Number of presale mints from the given address
  uint256 presaleMints;
  /// Number of public mints from the given address
  uint256 publicMints;
}
