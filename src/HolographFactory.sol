/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./Holographer.sol";

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
contract HolographFactory is Admin, Initializable {
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
      sstore(precomputeslot("eip1967.Holograph.Bridge.admin"), origin())

      sstore(precomputeslot("eip1967.Holograph.Bridge.holograph"), holograph)
      sstore(precomputeslot("eip1967.Holograph.Bridge.registry"), registry)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  /**
   * @dev A sample function of the deployment of bridgeable smart contracts.
   * @dev The used variables and formatting is not the final or decisive version, but the general idea is directly portrayed.
   * @notice In this function we have incorporated a secure storage function/extension. Keep in mind that this is not required or needed for bridgeable deployments to work. It is just a personal development choice.
   */
  function deployHolographableContract(
    DeploymentConfig calldata config,
    Verification calldata signature,
    address signer
  ) external {
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
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
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
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
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
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.holograph')) - 1);
    assembly {
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
    }
  }

  function setHolograph(address holograph) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.holograph')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.holograph"), holograph)
    }
  }

  function getRegistry() public view returns (address registry) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
    assembly {
      registry := sload(precomputeslot("eip1967.Holograph.Bridge.registry"))
    }
  }

  function setRegistry(address registry) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.registry"), registry)
    }
  }
}
