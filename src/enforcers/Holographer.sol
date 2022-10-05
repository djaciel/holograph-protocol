/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import "../interface/IHolograph.sol";
import "../interface/IHolographer.sol";
import "../interface/IHolographRegistry.sol";
import "../interface/IInitializable.sol";

/**
 * @dev This contract is a binder. It puts together all the variables to make the underlying contracts functional and be bridgeable.
 */
contract Holographer is Admin, Initializable, IHolographer {
  bytes32 constant _originChainSlot = precomputeslot("eip1967.Holograph.originChain");
  bytes32 constant _holographSlot = precomputeslot("eip1967.Holograph.holograph");
  bytes32 constant _contractTypeSlot = precomputeslot("eip1967.Holograph.contractType");
  bytes32 constant _sourceContractSlot = precomputeslot("eip1967.Holograph.sourceContract");
  bytes32 constant _blockHeightSlot = precomputeslot("eip1967.Holograph.blockHeight");

  /**
   * @dev Constructor is left empty and init is used instead.
   */
  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPHER: already initialized");
    (bytes memory encoded, bytes memory initCode) = abi.decode(data, (bytes, bytes));
    (uint32 originChain, address holograph, bytes32 contractType, address sourceContract) = abi.decode(
      encoded,
      (uint32, address, bytes32, address)
    );
    assembly {
      sstore(_adminSlot, caller())
      sstore(_blockHeightSlot, number())
      sstore(_contractTypeSlot, contractType)
      sstore(_holographSlot, holograph)
      sstore(_originChainSlot, originChain)
      sstore(_sourceContractSlot, sourceContract)
    }
    (bool success, bytes memory returnData) = IHolographRegistry(IHolograph(holograph).getRegistry())
      .getContractTypeAddress(contractType)
      .delegatecall(abi.encodeWithSignature("init(bytes)", initCode));
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == IInitializable.init.selector, "initialization failed");
    _setInitialized();
    return IInitializable.init.selector;
  }

  /**
   * @dev Returns the block height of when the smart contract was deployed. Useful for retrieving deployment config for re-deployment on other EVM-compatible chains.
   */
  function getDeploymentBlock() external view returns (address holograph) {
    assembly {
      holograph := sload(_blockHeightSlot)
    }
  }

  /**
   * @dev Returns a hardcoded address for the Holograph smart contract.
   */
  function getHolograph() external view returns (address holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  /**
   * @dev Returns a hardcoded address for the Holograph smart contract that controls and enforces the ERC standards.
   */
  function getHolographEnforcer() public view returns (address) {
    IHolograph holograph;
    bytes32 contractType;
    assembly {
      holograph := sload(_holographSlot)
      contractType := sload(_contractTypeSlot)
    }
    return IHolographRegistry(holograph.getRegistry()).getContractTypeAddress(contractType);
  }

  /**
   * @dev Returns the original chain that contract was deployed on.
   */
  function getOriginChain() external view returns (uint32 originChain) {
    assembly {
      originChain := sload(_originChainSlot)
    }
  }

  /**
   * @dev Returns a hardcoded address for the custom secure storage contract deployed in parallel with this contract deployment.
   */
  function getSourceContract() external view returns (address sourceContract) {
    assembly {
      sourceContract := sload(_sourceContractSlot)
    }
  }

  /**
   * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
   */
  receive() external payable {}

  /**
   * @dev This takes the Enforcer's source code, runs it, and uses current address for storage slots.
   */
  fallback() external payable {
    address holographEnforcer = getHolographEnforcer();
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), holographEnforcer, 0, calldatasize(), 0, 0)
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
