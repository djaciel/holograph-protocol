/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../../abstract/Admin.sol";
import "../../abstract/Initializable.sol";

contract EditionsMetadataRendererProxy is Admin, Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.editionsMetadataRenderer')) - 1)
   */
  bytes32 constant _editionsMetadataRendererSlot = precomputeslot("eip1967.Holograph.editionsMetadataRenderer");

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address editionsMetadataRenderer, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_editionsMetadataRendererSlot, editionsMetadataRenderer)
    }
    (bool success, bytes memory returnData) = editionsMetadataRenderer.delegatecall(
      abi.encodeWithSignature("init(bytes)", initCode)
    );
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == Initializable.init.selector, "initialization failed");
    _setInitialized();
    return Initializable.init.selector;
  }

  function getEditionsMetadataRenderer() external view returns (address editionsMetadataRenderer) {
    assembly {
      editionsMetadataRenderer := sload(_editionsMetadataRendererSlot)
    }
  }

  function setEditionsMetadataRenderer(address editionsMetadataRenderer) external onlyAdmin {
    assembly {
      sstore(_editionsMetadataRendererSlot, editionsMetadataRenderer)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let editionsMetadataRenderer := sload(_editionsMetadataRendererSlot)
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), editionsMetadataRenderer, 0, calldatasize(), 0, 0)
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
