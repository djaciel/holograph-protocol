/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../Holograph.sol";

contract MockHolographChild is Holograph {
  constructor() {}

  function emptyFunction() external pure returns (string memory) {
    return "on purpose to remove verification conflict";
  }
}
