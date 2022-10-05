/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IInitializable.sol";
import "./interface/IHolograph.sol";

/**
 * @title Holograph Protocol
 * @author https://github.com/holographxyz
 * @notice This is the primary Holograph Protocol smart contract.
 * @dev This contract stores a reference to all the primary modules and variables of the protocol.
 */
contract Holograph is Admin, Initializable, IHolograph {
  bytes32 constant _bridgeSlot = precomputeslot("eip1967.Holograph.bridge");
  bytes32 constant _chainIdSlot = precomputeslot("eip1967.Holograph.chainId");
  bytes32 constant _factorySlot = precomputeslot("eip1967.Holograph.factory");
  bytes32 constant _holographChainIdSlot = precomputeslot("eip1967.Holograph.holographChainId");
  bytes32 constant _interfacesSlot = precomputeslot("eip1967.Holograph.interfaces");
  bytes32 constant _operatorSlot = precomputeslot("eip1967.Holograph.operator");
  bytes32 constant _registrySlot = precomputeslot("eip1967.Holograph.registry");
  bytes32 constant _treasurySlot = precomputeslot("eip1967.Holograph.treasury");
  bytes32 constant _utilityTokenSlot = precomputeslot("eip1967.Holograph.utilityToken");

  /**
   * @dev Constructor is left empty and init is used instead.
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor.
   * @dev This function is called by the deployer/factory when creating a contract.
   */
  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (
      uint32 holographChainId,
      address bridge,
      address factory,
      address interfaces,
      address operator,
      address registry,
      address treasury,
      address utilityToken
    ) = abi.decode(data, (uint32, address, address, address, address, address, address, address));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_bridgeSlot, bridge)
      sstore(_chainIdSlot, chainid())
      sstore(_factorySlot, factory)
      sstore(_holographChainIdSlot, holographChainId)
      sstore(_interfacesSlot, interfaces)
      sstore(_operatorSlot, operator)
      sstore(_registrySlot, registry)
      sstore(_treasurySlot, treasury)
      sstore(_utilityTokenSlot, utilityToken)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  /**
   * @notice Get the address of the Holograph Bridge module.
   * @dev Used for beaming holographable assets cross-chain.
   */
  function getBridge() external view returns (address bridge) {
    assembly {
      bridge := sload(_bridgeSlot)
    }
  }

  /**
   * @notice Update the Holograph Bridge module address.
   */
  function setBridge(address bridge) external onlyAdmin {
    assembly {
      sstore(_bridgeSlot, bridge)
    }
  }

  /**
   * @notice Get the chain ID that the Protocol was deployed on.
   * @dev Useful for checking if/when a hard fork occurs.
   */
  function getChainId() external view returns (uint256 chainId) {
    assembly {
      chainId := sload(_chainIdSlot)
    }
  }

  /**
   * @notice Update the chain ID.
   * @dev Useful for updating once a hard fork has been mitigated.
   */
  function setChainId(uint256 chainId) external onlyAdmin {
    assembly {
      sstore(_chainIdSlot, chainId)
    }
  }

  /**
   * @notice Get the address of the Holograph Factory module.
   * @dev Used for deploying holographable smart contracts.
   */
  function getFactory() external view returns (address factory) {
    assembly {
      factory := sload(_factorySlot)
    }
  }

  /**
   * @notice Update the Holograph Factory module address.
   */
  function setFactory(address factory) external onlyAdmin {
    assembly {
      sstore(_factorySlot, factory)
    }
  }

  /**
   * @notice Get the Holograph chain Id.
   * @dev Holograph uses an internal chain id mapping.
   */
  function getHolographChainId() external view returns (uint32 holographChainId) {
    assembly {
      holographChainId := sload(_holographChainIdSlot)
    }
  }

  /**
   * @notice Update the Holograph chain ID.
   * @dev Useful for updating once a hard fork was mitigated.
   */
  function setHolographChainId(uint32 holographChainId) external onlyAdmin {
    assembly {
      sstore(_holographChainIdSlot, holographChainId)
    }
  }

  /**
   * @notice Get the address of the Holograph Interfaces module.
   * @dev Holograph uses this contract to store data that needs to be accessed by a large portion of the modules.
   */
  function getInterfaces() external view returns (address interfaces) {
    assembly {
      interfaces := sload(_interfacesSlot)
    }
  }

  /**
   * @notice Update the Holograph Interfaces module address.
   */
  function setInterfaces(address interfaces) external onlyAdmin {
    assembly {
      sstore(_interfacesSlot, interfaces)
    }
  }

  /**
   * @notice Get the address of the Holograph Operator module.
   * @dev All cross-chain Holograph Bridge beams are handled by the Holograph Operator module.
   */
  function getOperator() external view returns (address operator) {
    assembly {
      operator := sload(_operatorSlot)
    }
  }

  /**
   * @notice Update the Holograph Operator module address.
   */
  function setOperator(address operator) external onlyAdmin {
    assembly {
      sstore(_operatorSlot, operator)
    }
  }

  /**
   * @notice Get the Holograph Registry module.
   * @dev This module stores a reference for all deployed holographable smart contracts.
   */
  function getRegistry() external view returns (address registry) {
    assembly {
      registry := sload(_registrySlot)
    }
  }

  /**
   * @notice Update the Holograph Registry module address.
   */
  function setRegistry(address registry) external onlyAdmin {
    assembly {
      sstore(_registrySlot, registry)
    }
  }

  /**
   * @notice Get the Holograph Treasury module.
   * @dev All of the Holograph Protocol assets are stored and managed by this module.
   */
  function getTreasury() external view returns (address treasury) {
    assembly {
      treasury := sload(_treasurySlot)
    }
  }

  /**
   * @notice Update the Holograph Treasury module address.
   */
  function setTreasury(address treasury) external onlyAdmin {
    assembly {
      sstore(_treasurySlot, treasury)
    }
  }

  /**
   * @notice Get the Holograph Protocol Utility Token address.
   * @dev This is the official utility token of the Holograph Protocol.
   */
  function getUtilityToken() external view returns (address utilityToken) {
    assembly {
      utilityToken := sload(_utilityTokenSlot)
    }
  }

  /**
   * @notice Update the Holograph Protocol Utility Token address.
   */
  function setUtilityToken(address utilityToken) external onlyAdmin {
    assembly {
      sstore(_utilityTokenSlot, utilityToken)
    }
  }

  /**
   * @dev Purposefully reverts to prevent having any type of ether transfered into the contract.
   */
  receive() external payable {
    revert();
  }

  /**
   * @dev Purposefully reverts to prevent any calls to undefined functions.
   */
  fallback() external payable {
    revert();
  }
}
