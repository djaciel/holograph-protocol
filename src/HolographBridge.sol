/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./enum/ChainIdType.sol";

import "./interface/ERC20Holograph.sol";
import "./interface/ERC721Holograph.sol";
import "./interface/HolographableEnforcer.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographBridge.sol";
import "./interface/IHolographFactory.sol";
import "./interface/IHolographOperator.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";
import "./interface/IInterfaces.sol";

import "./struct/DeploymentConfig.sol";
import "./struct/Verification.sol";

/**
 * @dev This smart contract contains the actual core bridging logic.
 */
contract HolographBridge is Admin, Initializable, IHolographBridge {
  bytes32 constant _factorySlot = precomputeslot("eip1967.Holograph.factory");
  bytes32 constant _holographSlot = precomputeslot("eip1967.Holograph.holograph");
  bytes32 constant _interfacesSlot = precomputeslot("eip1967.Holograph.interfaces");
  bytes32 constant _jobNonceSlot = precomputeslot("eip1967.Holograph.jobNonce");
  bytes32 constant _operatorSlot = precomputeslot("eip1967.Holograph.operator");
  bytes32 constant _registrySlot = precomputeslot("eip1967.Holograph.registry");

  /**
   * @dev Constructor is left empty and only the admin address is set.
   */
  constructor() {}

  modifier onlyBridge() {
    require(msg.sender == address(this), "HOLOGRAPH: bridge only call");
    _;
  }

  modifier onlyOperator() {
    require(msg.sender == address(_operator()), "HOLOGRAPH: operator only call");
    _;
  }

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address factory, address holograph, address interfaces, address operator, address registry) = abi.decode(
      data,
      (address, address, address, address, address)
    );
    assembly {
      sstore(_adminSlot, origin())

      sstore(_factorySlot, factory)
      sstore(_holographSlot, holograph)
      sstore(_interfacesSlot, interfaces)
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
    bytes calldata data
  ) external onlyOperator {
    require(
      _registry().isHolographedContract(holographableContract) || address(_factory()) == holographableContract,
      "HOLOGRAPH: not holographed"
    );
    bytes4 selector = HolographableEnforcer(holographableContract).bridgeIn(fromChain, data);
    require(selector == HolographableEnforcer.bridgeIn.selector, "HOLOGRAPH: bridge in failed");
    if (hTokenValue > 0) {
      // provide operator with hToken value for executing bridge job
      require(
        ERC20Holograph(hToken).holographBridgeMint(hTokenRecipient, hTokenValue) ==
          ERC20Holograph.holographBridgeMint.selector,
        "HOLOGRAPH: hToken mint failed"
      );
    }
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
    (bytes4 selector, bytes memory payload) = HolographableEnforcer(holographableContract).bridgeOut(
      toChain,
      msg.sender,
      data
    );
    require(selector == HolographableEnforcer.bridgeOut.selector, "HOLOGRAPH: bridge out failed");
    bytes memory encodedData = abi.encodeWithSelector(
      HolographableEnforcer.bridgeIn.selector,
      _jobNonce(),
      _holograph().getChainType(),
      holographableContract,
      _registry().getHToken(_holograph().getChainType()),
      address(0),
      0,
      payload
    );
    _operator().send{value: msg.value}(gasLimit, gasPrice, toChain, msg.sender, encodedData);
  }

  function getBridgeOutRequestPayload(
    uint32 toChain,
    address holographableContract,
    bytes calldata data
  ) external view returns (bytes memory samplePayload) {
    require(
      _registry().isHolographedContract(holographableContract) || address(_factory()) == holographableContract,
      "HOLOGRAPH: not holographed"
    );
    (bool success, bytes memory rawResponse) = holographableContract.staticcall(
      abi.encodeWithSelector(HolographableEnforcer.bridgeOut.selector, toChain, msg.sender, data)
    );
    require(success, "HOLOGRAPH: bridge out failed");
    (bytes4 selector, bytes memory payload) = abi.decode(rawResponse, (bytes4, bytes));
    uint256 jobNonce;
    assembly {
      jobNonce := sload(_jobNonceSlot)
    }
    require(selector == HolographableEnforcer.bridgeOut.selector, "HOLOGRAPH: bridge out failed");
    bytes memory encodedData = abi.encodeWithSelector(
      HolographableEnforcer.bridgeIn.selector,
      jobNonce + 1,
      _holograph().getChainType(),
      holographableContract,
      _registry().getHToken(_holograph().getChainType()),
      address(0),
      0,
      payload
    );
    samplePayload = abi.encodePacked(encodedData, type(uint256).max, type(uint256).max);
  }

  /**
   * @dev Internal nonce used for randomness.
   *      We increment it on each return.
   */
  function _jobNonce() private returns (uint256 jobNonce) {
    assembly {
      jobNonce := add(sload(_jobNonceSlot), 0x0000000000000000000000000000000000000000000000000000000000000001)
      sstore(_jobNonceSlot, jobNonce)
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

  function _interfaces() private view returns (IInterfaces interfaces) {
    assembly {
      interfaces := sload(_interfacesSlot)
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

  function getJobNonce() external view returns (uint256 jobNonce) {
    assembly {
      jobNonce := sload(_jobNonceSlot)
    }
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

  function getInterfaces() external view returns (address interfaces) {
    assembly {
      interfaces := sload(_interfacesSlot)
    }
  }

  function setInterfaces(address interfaces) external onlyAdmin {
    assembly {
      sstore(_interfacesSlot, interfaces)
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
}
