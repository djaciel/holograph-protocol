/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import "../interface/InitializableInterface.sol";

contract HolographERC721DropProxy is Admin, Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.erc721Drop')) - 1)
   */
  bytes32 constant _erc721DropSlot = 0x1554546c9d208a6936b69502220320b25abca24aa47b28340191ec7e05dd1c06;

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address erc721Drop, bytes memory initCode) = abi.decode(data, (address, bytes));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_erc721DropSlot, erc721Drop)
    }
    (bool success, bytes memory returnData) = erc721Drop.delegatecall(abi.encodeWithSignature("init(bytes)", initCode));
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == InitializableInterface.init.selector, "initialization failed");
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function getHolographErc721Drop() external view returns (address erc721Drop) {
    assembly {
      erc721Drop := sload(_erc721DropSlot)
    }
  }

  function setHolographErc721Drop(address erc721Drop) external onlyAdmin {
    assembly {
      sstore(_erc721DropSlot, erc721Drop)
    }
  }

  receive() external payable {}

  fallback() external payable {
    assembly {
      let erc721Drop := sload(_erc721DropSlot)
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), erc721Drop, 0, calldatasize(), 0, 0)
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
