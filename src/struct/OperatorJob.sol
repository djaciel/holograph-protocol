/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

struct OperatorJob {
  uint8 pod;
  uint16 blockTimes;
  address operator;
  uint256 startBlock;
  uint256[5] fallbackOperators;
}
