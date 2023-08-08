/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

contract LayerZeroModuleProxy is Admin, Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.layerZeroModule')) - 1)
   */
  bytes32 constant _layerZeroModuleSlot = precomputeslot("eip1967.Holograph.layerZeroModule");

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address layerZeroModule, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_layerZeroModuleSlot, layerZeroModule)
    }
    (bool success, bytes memory returnData) = layerZeroModule.delegatecall(
      abi.encodeWithSignature("init(bytes)", initCode)
    );
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == Initializable.init.selector, "initialization failed");
    _setInitialized();
    return Initializable.init.selector;
  }

  function getLayerZeroModule() external view returns (address layerZeroModule) {
    assembly {
      layerZeroModule := sload(_layerZeroModuleSlot)
    }
  }

  function setLayerZeroModule(address layerZeroModule) external onlyAdmin {
    assembly {
      sstore(_layerZeroModuleSlot, layerZeroModule)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let layerZeroModule := sload(_layerZeroModuleSlot)
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), layerZeroModule, 0, calldatasize(), 0, 0)
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
