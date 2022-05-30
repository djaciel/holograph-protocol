/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IHolograph.sol";
import "./interface/IHolographBridge.sol";
import "./interface/IHolographOperator.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";

import "./library/ChainId.sol";

/**
 * @dev This smart contract contains the actual core operator logic.
 */
contract HolographOperator is Admin, Initializable, IHolographOperator {
  /**
   * @dev Internal mapping of hashes for valid operator jobs.
   */
  mapping(bytes32 => bool) private _availableJobs;

  /**
   * @dev Event is emitted for every time that a valid job is available.
   */
  event AvailableJob(bytes _payload);

  event LzEvent(uint16 _dstChainId, bytes _destination, bytes _payload);

  modifier onlyBridge() {
    require(msg.sender == _bridge(), "HOLOGRAPH: bridge only call");
    _;
  }

  modifier onlyLZ() {
    assembly {
      switch eq(sload(precomputeslot("eip1967.Holograph.Bridge.lZEndpoint")), caller())
      case 0 {
        mstore(0x80, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0xa0, 0x0000002000000000000000000000000000000000000000000000000000000000)
        mstore(0xc0, 0x0000001b484f4c4f47524150483a204c5a206f6e6c7920656e64706f696e7400)
        mstore(0xe0, 0x0000000000000000000000000000000000000000000000000000000000000000)
        revert(0x80, 0xc4)
      }
    }
    _;
  }

  /**
   * @dev Constructor is left empty and only the admin address is set.
   */
  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address holograph, address registry, address bridge) = abi.decode(data, (address, address, address));
    assembly {
      // sstore(precomputeslot("eip1967.Holograph.Bridge.deadAddress"), 0x000000000000000000000000000000000000000000000000000000000000dead)
      sstore(precomputeslot("eip1967.Holograph.Bridge.admin"), origin())
      sstore(precomputeslot("eip1967.Holograph.Bridge.holograph"), holograph)
      sstore(precomputeslot("eip1967.Holograph.Bridge.bridge"), bridge)
      sstore(precomputeslot("eip1967.Holograph.Bridge.registry"), registry)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  function lzReceive(
    uint16, /* _srcChainId*/
    bytes calldata _srcAddress,
    uint64, /* _nonce*/
    bytes calldata _payload
  ) external onlyLZ {
    assembly {
      let ptr := mload(0x40)
      calldatacopy(add(ptr, 0x0c), _srcAddress.offset, _srcAddress.length)
      switch eq(mload(ptr), address())
      case 0 {
        mstore(0x80, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0xa0, 0x0000002000000000000000000000000000000000000000000000000000000000)
        mstore(0xc0, 0x0000001e484f4c4f47524150483a20756e617574686f72697a65642073656e64)
        mstore(0xe0, 0x6572000000000000000000000000000000000000000000000000000000000000)
        revert(0x80, 0xc4)
      }
    }
    _availableJobs[keccak256(_payload)] = true;
    emit AvailableJob(_payload);
  }

  function executeJob(bytes calldata _payload) external {
    // we do our operator logic here
    // we will also manage gas/value here
    bytes32 hash = keccak256(_payload);
    require(_availableJobs[hash], "HOLOGRAPH: invalid job");
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := call(
        gas(),
        sload(precomputeslot("eip1967.Holograph.Bridge.bridge")),
        callvalue(),
        0,
        calldatasize(),
        0,
        0
      )
      if eq(result, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
    _availableJobs[hash] = false;
  }

  function jobEstimator(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) external {
    assembly {
      // switch eq(sload(precomputeslot("eip1967.Holograph.Bridge.deadAddress")), caller())
      switch eq(mload(0x60), caller())
      case 0 {
        mstore(0x80, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0xa0, 0x0000002000000000000000000000000000000000000000000000000000000000)
        mstore(0xc0, 0x00000018484f4c4f47524150483a206f70657261746f72206f6e6c7900000000)
        mstore(0xe0, 0x0000000000000000000000000000000000000000000000000000000000000000)
        revert(0x80, 0xc4)
      }
    }
    IHolographOperator(address(this)).lzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    IHolographOperator(address(this)).executeJob(_payload);
  }

  function send(
    uint16 _dstChainId,
    bytes calldata _destination,
    bytes calldata _payload,
    address payable, /* _refundAddress*/
    address, /* _zroPaymentAddress*/
    bytes calldata /* _adapterParams*/
  ) external payable onlyBridge {
    // we really don't care about anything and just emit an event that we can leverage for multichain replication
    emit LzEvent(_dstChainId, _destination, _payload);
  }

  function _bridge() internal view returns (address bridge) {
    assembly {
      bridge := sload(precomputeslot("eip1967.Holograph.Bridge.bridge"))
    }
  }

  function _holograph() internal view returns (address holograph) {
    assembly {
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
    }
  }

  function _registry() internal view returns (address registry) {
    assembly {
      registry := sload(precomputeslot("eip1967.Holograph.Bridge.registry"))
    }
  }

  function getLZEndpoint() external view returns (address lZEndpoint) {
    assembly {
      lZEndpoint := sload(precomputeslot("eip1967.Holograph.Bridge.lZEndpoint"))
    }
  }

  function setLZEndpoint(address lZEndpoint) external onlyAdmin {
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.lZEndpoint"), lZEndpoint)
    }
  }
}
