/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/ERC20Holograph.sol";
import "./interface/Holographable.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographBridge.sol";
import "./interface/IHolographFactory.sol";
import "./interface/IHolographOperator.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";

/**
 * @title Holograph Bridge
 * @author https://github.com/holographxyz
 * @notice Beam your holographable assets through this contract.
 * @dev The contract abstracts all the complexities of making bridge requests and uses a universal interface to bridge any type of holographable assets.
 */
contract HolographBridge is Admin, Initializable, IHolographBridge {
  bytes32 constant _factorySlot = precomputeslot("eip1967.Holograph.factory");
  bytes32 constant _holographSlot = precomputeslot("eip1967.Holograph.holograph");
  bytes32 constant _jobNonceSlot = precomputeslot("eip1967.Holograph.jobNonce");
  bytes32 constant _operatorSlot = precomputeslot("eip1967.Holograph.operator");
  bytes32 constant _registrySlot = precomputeslot("eip1967.Holograph.registry");

  /**
   * @dev Allow calls only from HolographOperator contract.
   */
  modifier onlyOperator() {
    require(msg.sender == address(_operator()), "HOLOGRAPH: operator only call");
    _;
  }

  /**
   * @dev Constructor is left empty and init is used instead.
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract.
   */
  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address factory, address holograph, address operator, address registry) = abi.decode(
      data,
      (address, address, address, address)
    );
    assembly {
      sstore(_adminSlot, origin())
      sstore(_factorySlot, factory)
      sstore(_holographSlot, holograph)
      sstore(_operatorSlot, operator)
      sstore(_registrySlot, registry)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  function bridgeInRequest(
    uint256, /* nonce*/
    uint32 fromChain,
    address holographableContract,
    address hToken,
    address hTokenRecipient,
    uint256 hTokenValue,
    bool doNotRevert,
    bytes calldata data
  ) external payable onlyOperator {
    require(
      _registry().isHolographedContract(holographableContract) || address(_factory()) == holographableContract,
      "HOLOGRAPH: not holographed"
    );
    bytes4 selector = Holographable(holographableContract).bridgeIn(fromChain, data);
    require(selector == Holographable.bridgeIn.selector, "HOLOGRAPH: bridge in failed");
    if (hTokenValue > 0) {
      // provide operator with hToken value for executing bridge job
      require(
        ERC20Holograph(hToken).holographBridgeMint(hTokenRecipient, hTokenValue) ==
          ERC20Holograph.holographBridgeMint.selector,
        "HOLOGRAPH: hToken mint failed"
      );
    }
    require(doNotRevert, "HOLOGRAPH: reverted");
  }

  function bridgeOutRequest(
    uint32 toChain,
    address holographableContract,
    uint256 gasLimit,
    uint256 gasPrice,
    bytes calldata data
  ) external payable {
    require(
      _registry().isHolographedContract(holographableContract) || address(_factory()) == holographableContract,
      "HOLOGRAPH: not holographed"
    );
    (bytes4 selector, bytes memory payload) = Holographable(holographableContract).bridgeOut(toChain, msg.sender, data);
    require(selector == Holographable.bridgeOut.selector, "HOLOGRAPH: bridge out failed");
    bytes memory encodedData = abi.encodeWithSelector(
      IHolographBridge.bridgeInRequest.selector,
      _jobNonce(),
      _holograph().getHolographChainId(),
      holographableContract,
      _registry().getHToken(_holograph().getHolographChainId()),
      address(0),
      0,
      true,
      payload
    );
    _operator().send{value: msg.value}(gasLimit, gasPrice, toChain, msg.sender, encodedData);
  }

  function revertedBridgeOutRequest(
    address sender,
    uint32 toChain,
    address holographableContract,
    bytes calldata data
  ) external returns (string memory revertReason) {
    try Holographable(holographableContract).bridgeOut(toChain, sender, data) returns (
      bytes4 selector,
      bytes memory payload
    ) {
      if (selector != Holographable.bridgeOut.selector) {
        return "HOLOGRAPH: bridge out failed";
      }
      // otherwise we revert here
      revert(string(payload));
    } catch Error(string memory reason) {
      return reason;
    } catch {
      return "HOLOGRAPH: unknown error";
    }
  }

  function getBridgeOutRequestPayload(
    uint32 toChain,
    address holographableContract,
    bytes calldata data
  ) external returns (bytes memory samplePayload) {
    require(
      _registry().isHolographedContract(holographableContract) || address(_factory()) == holographableContract,
      "HOLOGRAPH: not holographed"
    );
    bytes memory payload;
    try this.revertedBridgeOutRequest(msg.sender, toChain, holographableContract, data) returns (
      string memory revertReason
    ) {
      revert(revertReason);
    } catch Error(string memory realResponse) {
      payload = bytes(realResponse);
    }
    uint256 jobNonce;
    assembly {
      jobNonce := sload(_jobNonceSlot)
    }
    bytes memory encodedData = abi.encodeWithSelector(
      IHolographBridge.bridgeInRequest.selector,
      jobNonce + 1,
      _holograph().getHolographChainId(),
      holographableContract,
      _registry().getHToken(_holograph().getHolographChainId()),
      address(0),
      0,
      true,
      payload
    );
    samplePayload = abi.encodePacked(encodedData, type(uint256).max, type(uint256).max);
  }

  function getFactory() external view returns (address factory) {
    assembly {
      factory := sload(_factorySlot)
    }
  }

  function setFactory(address factory) external onlyAdmin {
    assembly {
      sstore(_factorySlot, factory)
    }
  }

  function getHolograph() external view returns (address holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  function setHolograph(address holograph) external onlyAdmin {
    assembly {
      sstore(_holographSlot, holograph)
    }
  }

  function getJobNonce() external view returns (uint256 jobNonce) {
    assembly {
      jobNonce := sload(_jobNonceSlot)
    }
  }

  function getOperator() external view returns (address operator) {
    assembly {
      operator := sload(_operatorSlot)
    }
  }

  function setOperator(address operator) external onlyAdmin {
    assembly {
      sstore(_operatorSlot, operator)
    }
  }

  function getRegistry() external view returns (address registry) {
    assembly {
      registry := sload(_registrySlot)
    }
  }

  function setRegistry(address registry) external onlyAdmin {
    assembly {
      sstore(_registrySlot, registry)
    }
  }

  function _factory() private view returns (IHolographFactory factory) {
    assembly {
      factory := sload(_factorySlot)
    }
  }

  function _holograph() private view returns (IHolograph holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  /**
   * @dev Internal nonce used for randomness. We increment it on each call.
   */
  function _jobNonce() private returns (uint256 jobNonce) {
    assembly {
      jobNonce := add(sload(_jobNonceSlot), 0x0000000000000000000000000000000000000000000000000000000000000001)
      sstore(_jobNonceSlot, jobNonce)
    }
  }

  function _operator() private view returns (IHolographOperator operator) {
    assembly {
      operator := sload(_operatorSlot)
    }
  }

  function _registry() private view returns (IHolographRegistry registry) {
    assembly {
      registry := sload(_registrySlot)
    }
  }
}
