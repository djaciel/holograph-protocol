/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../../abstract/Admin.sol";
import "../../abstract/Initializable.sol";

contract DropsPriceOracleProxy is Admin, Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.dropsPriceOracle')) - 1)
   */
  bytes32 constant _dropsPriceOracleSlot = precomputeslot("eip1967.Holograph.dropsPriceOracle");

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address dropsPriceOracle, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_dropsPriceOracleSlot, dropsPriceOracle)
    }
    (bool success, bytes memory returnData) = dropsPriceOracle.delegatecall(
      abi.encodeWithSignature("init(bytes)", initCode)
    );
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == Initializable.init.selector, "initialization failed");
    _setInitialized();
    return Initializable.init.selector;
  }

  function getDropsPriceOracle() external view returns (address dropsPriceOracle) {
    assembly {
      dropsPriceOracle := sload(_dropsPriceOracleSlot)
    }
  }

  function setDropsPriceOracle(address dropsPriceOracle) external onlyAdmin {
    assembly {
      sstore(_dropsPriceOracleSlot, dropsPriceOracle)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let dropsPriceOracle := sload(_dropsPriceOracleSlot)
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), dropsPriceOracle, 0, calldatasize(), 0, 0)
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
