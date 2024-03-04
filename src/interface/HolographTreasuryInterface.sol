/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

interface HolographTreasuryInterface {
  /**
   * @notice Update the Holograph Mint Fee
   * @param fee new fee to charge for minting holographable assets
   */
  function setHolographMintFee(uint256 fee) external;

  /**
   * @notice Withdraws native tokens from the contract
   * @dev Can only be called by the admin
   */
  function withdraw() external;

  /**
   * @notice Withdraws native tokens from the contract to a specified address
   * @dev Can only be called by the admin
   * @param recipient The address to send the withdrawn funds to
   */
  function withdrawTo(address payable recipient) external;

  /**
   * @notice Get the Holograph Mint Fee
   * @dev This fee is charged to mint holographable assets
   * @return The current holograph mint fee
   */
  function getHolographMintFee() external view returns (uint256);
}
