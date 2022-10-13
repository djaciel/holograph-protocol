/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Initializable.sol";

import "../interface/InitializableInterface.sol";

contract Mock is Initializable {
  constructor() {}

  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "MOCK: already initialized");
    bytes32 arbitraryData = abi.decode(initPayload, (bytes32));
    setStorage(0, arbitraryData);
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function getStorage(uint256 slot) public view returns (bytes32 data) {
    assembly {
      data := sload(slot)
    }
  }

  function setStorage(uint256 slot, bytes32 data) public {
    assembly {
      sstore(slot, data)
    }
  }

  function mockCall(address target, bytes calldata data) public payable {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}
