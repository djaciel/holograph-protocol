// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "../interface/InitializableInterface.sol";

contract HolographDropCreatorProxy is Admin, Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.dropCreator')) - 1)
   */
  bytes32 constant _dropCreatorSlot = 0x8ff08cc6e8c4c508c563852adb1853b353af6edb502f5298dd4937029dcaf6a8;

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address dropCreator, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_dropCreatorSlot, dropCreator)
    }
    (bool success, bytes memory returnData) = dropCreator.delegatecall(
      abi.encodeWithSignature("init(bytes)", initCode)
    );
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == InitializableInterface.init.selector, "initialization failed");
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function getDropCreator() external view returns (address dropCreator) {
    assembly {
      dropCreator := sload(_dropCreatorSlot)
    }
  }

  function setNFTCreator(address dropCreator) external onlyAdmin {
    assembly {
      sstore(_dropCreatorSlot, dropCreator)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let dropCreator := sload(_dropCreatorSlot)
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), dropCreator, 0, calldatasize(), 0, 0)
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
