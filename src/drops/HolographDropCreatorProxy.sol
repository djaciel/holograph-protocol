/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import "../interface/InitializableInterface.sol";

contract HolographNFTCreatorProxy is Admin, Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.nftCreator')) - 1)
   */
  bytes32 constant _nftCreatorSlot = precomputeslot("eip1967.Holograph.nftCreator");

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address nftCreator, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_nftCreatorSlot, nftCreator)
    }
    (bool success, bytes memory returnData) = nftCreator.delegatecall(abi.encodeWithSignature("init(bytes)", initCode));
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == InitializableInterface.init.selector, "initialization failed");
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function getNFTCreator() external view returns (address nftCreator) {
    assembly {
      nftCreator := sload(_nftCreatorSlot)
    }
  }

  function setNFTCreator(address nftCreator) external onlyAdmin {
    assembly {
      sstore(_nftCreatorSlot, nftCreator)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let nftCreator := sload(_nftCreatorSlot)
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), nftCreator, 0, calldatasize(), 0, 0)
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
