/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";
import "../abstract/Owner.sol";

import "../enum/HolographGenericEvent.sol";
import "../enum/InterfaceType.sol";

import "../interface/HolographGenericInterface.sol";
import "../interface/ERC165.sol";
import "../interface/Holographable.sol";
import "../interface/HolographedGeneric.sol";
import "../interface/HolographInterface.sol";
import "../interface/InitializableInterface.sol";
import "../interface/HolographInterfacesInterface.sol";
import "../interface/Ownable.sol";

/**
 * @title Holograph Bridgeable Generic Contract
 * @author CXIP-Labs
 * @notice A smart contract for creating custom bridgeable logic.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract HolographGeneric is Admin, Owner, Initializable, HolographGenericInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
   */
  bytes32 constant _holographSlot = precomputeslot("eip1967.Holograph.holograph");
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.sourceContract')) - 1)
   */
  bytes32 constant _sourceContractSlot = precomputeslot("eip1967.Holograph.sourceContract");

  /**
   * @dev Configuration for events to trigger for source smart contract.
   */
  uint256 private _eventConfig;

  /**
   * @notice Only allow calls from bridge smart contract.
   */
  modifier onlyBridge() {
    require(msg.sender == _holograph().getBridge(), "GENERIC: bridge only call");
    _;
  }

  /**
   * @notice Only allow calls from source smart contract.
   */
  modifier onlySource() {
    address sourceContract;
    assembly {
      sourceContract := sload(_sourceContractSlot)
    }
    require(msg.sender == sourceContract, "GENERIC: source only call");
    _;
  }

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "GENERIC: already initialized");
    InitializableInterface sourceContract;
    assembly {
      sstore(_ownerSlot, caller())
      sourceContract := sload(_sourceContractSlot)
    }
    (uint256 eventConfig, bool skipInit, bytes memory initCode) = abi.decode(initPayload, (uint256, bool, bytes));
    _eventConfig = eventConfig;
    if (!skipInit) {
      require(sourceContract.init(initCode) == InitializableInterface.init.selector, "GENERIC: could not init source");
    }
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  /**
   * @dev Allows for source smart contract to withdraw contract balance.
   */
  function sourceWithdraw(address payable destination) external onlySource {
    destination.transfer(address(this).balance);
  }

  /**
   * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
   */
  receive() external payable {}

  /**
   * @notice Fallback to the source contract.
   * @dev Any function call that is not covered here, will automatically be sent over to the source contract.
   */
  fallback() external payable {
    assembly {
      calldatacopy(0, 0, calldatasize())
      mstore(calldatasize(), caller())
      let result := call(gas(), sload(_sourceContractSlot), callvalue(), 0, add(calldatasize(), 32), 0, 0)
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

  function _sourceCall(bytes memory payload) private returns (bool output) {
    assembly {
      let pos := mload(0x40)
      mstore(0x40, add(pos, 0x20))
      mstore(add(payload, mload(payload)), caller())
      let result := call(gas(), sload(_sourceContractSlot), callvalue(), payload, add(mload(payload), 0x20), 0, 0)
      returndatacopy(pos, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      output := mload(pos)
    }
  }

  /**
   * @dev Although EIP-165 is not required for ERC20 contracts, we still decided to implement it.
   *
   * This makes it easier for external smart contracts to easily identify a valid ERC20 token contract.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool) {
    HolographInterfacesInterface interfaces = HolographInterfacesInterface(_interfaces());
    ERC165 erc165Contract;
    assembly {
      erc165Contract := sload(_sourceContractSlot)
    }
    if (
      interfaces.supportsInterface(InterfaceType.GENERIC, interfaceId) || erc165Contract.supportsInterface(interfaceId) // check global interfaces // check if source supports interface
    ) {
      return true;
    } else {
      return false;
    }
  }

  function bridgeIn(uint32 fromChain, bytes calldata payload) external onlyBridge returns (bytes4) {
    if (_isEventRegistered(HolographGenericEvent.bridgeIn)) {
      require(
        _sourceCall(abi.encodeWithSelector(HolographedGeneric.bridgeIn.selector, fromChain, payload)),
        "HOLOGRAPH: bridge in failed"
      );
    }
    return Holographable.bridgeIn.selector;
  }

  function bridgeOut(
    uint32 toChain,
    address sender,
    bytes calldata payload
  ) external onlyBridge returns (bytes4 selector, bytes memory data) {
    if (_isEventRegistered(HolographGenericEvent.bridgeOut)) {
      bytes memory sourcePayload = abi.encodeWithSelector(
        HolographedGeneric.bridgeOut.selector,
        toChain,
        sender,
        payload
      );
      assembly {
        mstore(add(sourcePayload, mload(sourcePayload)), caller())
        let result := call(
          gas(),
          sload(_sourceContractSlot),
          callvalue(),
          sourcePayload,
          add(mload(sourcePayload), 32),
          0,
          0
        )
        returndatacopy(data, 0, returndatasize())
        switch result
        case 0 {
          revert(0, returndatasize())
        }
      }
    }
    return (Holographable.bridgeOut.selector, data);
  }

  /**
   * @dev Allows for source smart contract to emit events.
   */
  function sourceEmit(bytes calldata eventData) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log0(0, eventData.length)
    }
  }

  function sourceEmit(bytes32 eventId, bytes calldata eventData) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log1(0, eventData.length, eventId)
    }
  }

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes calldata eventData
  ) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log2(0, eventData.length, eventId, topic1)
    }
  }

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes32 topic2,
    bytes calldata eventData
  ) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log3(0, eventData.length, eventId, topic1, topic2)
    }
  }

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes32 topic2,
    bytes32 topic3,
    bytes calldata eventData
  ) external onlySource {
    assembly {
      calldatacopy(0, eventData.offset, eventData.length)
      log4(0, eventData.length, eventId, topic1, topic2, topic3)
    }
  }

  /**
   * @dev Get the source smart contract as bridgeable interface.
   */
  function SourceGeneric() private view returns (HolographedGeneric sourceContract) {
    assembly {
      sourceContract := sload(_sourceContractSlot)
    }
  }

  /**
   * @dev Get the interfaces contract address.
   */
  function _interfaces() private view returns (address) {
    return _holograph().getInterfaces();
  }

  function owner() public view override returns (address) {
    Ownable ownableContract;
    assembly {
      ownableContract := sload(_sourceContractSlot)
    }
    return ownableContract.owner();
  }

  function _holograph() private view returns (HolographInterface holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  function _isEventRegistered(HolographGenericEvent _eventName) private view returns (bool) {
    return ((_eventConfig >> uint256(_eventName)) & uint256(1) == 1 ? true : false);
  }

  // the code below is temporary, in place to prevent Holographers on testnet from having different deployment addresses

  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.contractType')) - 1)
   */
  bytes32 constant _contractTypeSlot = precomputeslot("eip1967.Holograph.contractType");

  /**
   * @dev Returns the contract type that is used for loading the Enforcer
   */
  function getContractType() external view returns (bytes32 contractType) {
    assembly {
      contractType := sload(_contractTypeSlot)
    }
  }
}
