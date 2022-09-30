/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../interface/IInitializable.sol";

abstract contract Initializable is IInitializable {
  bytes32 constant _initializedSlot = precomputeslot("eip1967.Holograph.initialized");

  function init(bytes memory _data) external virtual returns (bytes4);

  function _isInitialized() internal view returns (bool initialized) {
    assembly {
      initialized := sload(_initializedSlot)
    }
  }

  function _setInitialized() internal {
    assembly {
      sstore(_initializedSlot, 0x0000000000000000000000000000000000000000000000000000000000000001)
    }
  }
}
