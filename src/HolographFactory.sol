/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./Holographer.sol";

import "./interface/HolographableEnforcer.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";

import "./struct/DeploymentConfig.sol";
import "./struct/Verification.sol";

/**
 * @dev This smart contract demonstrates a clear and concise way that we plan to deploy smart contracts.
 * @dev With the goal of deploying replicate-able non-fungible token smart contracts through this process.
 * @dev This is just the first step. But it is fundamental for achieving cross-chain non-fungible tokens.
 */
contract HolographFactory is Admin, Initializable, HolographableEnforcer {
  bytes32 constant _holographSlot = precomputeslot("eip1967.Holograph.holograph");
  bytes32 constant _registrySlot = precomputeslot("eip1967.Holograph.registry");

  /**
   * @dev This event is fired every time that a bridgeable contract is deployed.
   */
  event BridgeableContractDeployed(address indexed contractAddress, bytes32 indexed hash);

  /**
   * @dev Constructor is left empty and only the admin address is set.
   */
  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address holograph, address registry) = abi.decode(data, (address, address));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_holographSlot, holograph)
      sstore(_registrySlot, registry)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  function bridgeIn(
    uint32,
    /* fromChain*/
    bytes calldata payload
  ) external returns (bytes4) {
    (DeploymentConfig memory config, Verification memory signature, address signer) = abi.decode(
      payload,
      (DeploymentConfig, Verification, address)
    );
    deployHolographableContract(config, signature, signer);
    return HolographableEnforcer.bridgeIn.selector;
  }

  function bridgeOut(
    uint32,
    /* toChain*/
    address,
    /* sender*/
    bytes calldata payload
  ) external pure returns (bytes4 selector, bytes memory data) {
    return (HolographableEnforcer.bridgeOut.selector, payload);
  }

  /**
   * @dev A sample function of the deployment of bridgeable smart contracts.
   * @dev The used variables and formatting is not the final or decisive version, but the general idea is directly portrayed.
   * @notice In this function we have incorporated a secure storage function/extension. Keep in mind that this is not required or needed for bridgeable deployments to work. It is just a personal development choice.
   */
  function deployHolographableContract(
    DeploymentConfig memory config,
    Verification memory signature,
    address signer
  ) public {
    bytes32 hash = keccak256(
      abi.encodePacked(
        config.contractType,
        config.chainType,
        config.salt,
        keccak256(config.byteCode),
        keccak256(config.initCode),
        signer
      )
    );
    require(_verifySigner(signature.r, signature.s, signature.v, hash, signer), "HOLOGRAPH: invalid signature");
    require(!IHolographRegistry(getRegistry()).isHolographedHashDeployed(hash), "HOLOGRAPH: already deployed");
    uint256 saltInt = uint256(hash);
    address sourceContractAddress;
    bytes memory sourceByteCode = config.byteCode;
    assembly {
      sourceContractAddress := create2(0, add(sourceByteCode, 0x20), mload(sourceByteCode), saltInt)
    }
    bytes memory holographerBytecode = type(Holographer).creationCode;
    address holographerAddress;
    assembly {
      holographerAddress := create2(0, add(holographerBytecode, 0x20), mload(holographerBytecode), saltInt)
    }
    address holograph;
    assembly {
      holograph := sload(_holographSlot)
    }
    require(
      IInitializable(holographerAddress).init(
        abi.encode(abi.encode(config.chainType, holograph, config.contractType, sourceContractAddress), config.initCode)
      ) == IInitializable.init.selector,
      "initialization failed"
    );
    IHolographRegistry(getRegistry()).factoryDeployedHash(hash, holographerAddress);
    emit BridgeableContractDeployed(holographerAddress, hash);
  }

  function _isContract(address contractAddress) private view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(contractAddress)
    }
    return (codehash != 0x0 && codehash != precomputekeccak256(""));
  }

  function _verifySigner(
    bytes32 r,
    bytes32 s,
    uint8 v,
    bytes32 hash,
    address signer
  ) private pure returns (bool) {
    if (v < 27) {
      v += 27;
    }
    return (ecrecover(hash, v, r, s) == signer ||
      ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == signer);
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

  function getRegistry() public view returns (address registry) {
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
