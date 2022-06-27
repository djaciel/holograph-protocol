/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import "../interface/IInitializable.sol";

contract HolographTreasuryProxy is Admin, Initializable {
  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address treasury, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.treasury"), treasury)
      sstore(precomputeslot("eip1967.Holograph.Bridge.admin"), origin())
    }
    (bool success, bytes memory returnData) = treasury.delegatecall(abi.encodeWithSignature("init(bytes)", initCode));
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == IInitializable.init.selector, "initialization failed");
    _setInitialized();
    return IInitializable.init.selector;
  }

  function getTreasury() external view returns (address treasury) {
    // The slot hash has been precomputed for gas optimization
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.treasury')) - 1);
    assembly {
      treasury := sload(precomputeslot("eip1967.Holograph.Bridge.treasury"))
    }
  }

  function setTreasury(address treasury) external onlyAdmin {
    // The slot hash has been precomputed for gas optimization
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.treasury')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.treasury"), treasury)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let treasury := sload(precomputeslot("eip1967.Holograph.Bridge.treasury"))
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), treasury, 0, calldatasize(), 0, 0)
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
