/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import "../interface/IInitializable.sol";

contract HolographOperatorProxy is Admin, Initializable {
  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address operator, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.operator"), operator)
      sstore(precomputeslot("eip1967.Holograph.Bridge.admin"), origin())
    }
    (bool success, bytes memory returnData) = operator.delegatecall(abi.encodeWithSignature("init(bytes)", initCode));
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == IInitializable.init.selector, "initialization failed");
    _setInitialized();
    return IInitializable.init.selector;
  }

  function getOperator() external view returns (address operator) {
    // The slot hash has been precomputed for gas optimization
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.operator')) - 1);
    assembly {
      operator := sload(precomputeslot("eip1967.Holograph.Bridge.operator"))
    }
  }

  function setOperator(address operator) external onlyAdmin {
    // The slot hash has been precomputed for gas optimization
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.operator')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.operator"), operator)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let operator := sload(precomputeslot("eip1967.Holograph.Bridge.operator"))
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), operator, 0, calldatasize(), 0, 0)
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
