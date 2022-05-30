/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./Holographer.sol";

import "./interface/IHolograph.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";

import "./proxy/SecureStorageProxy.sol";

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
    (address holograph, address registry, address secureStorage) = abi.decode(data, (address, address, address));
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.admin"), origin())
      sstore(precomputeslot("eip1967.Holograph.Bridge.holograph"), holograph)
      sstore(precomputeslot("eip1967.Holograph.Bridge.registry"), registry)
      sstore(precomputeslot("eip1967.Holograph.Bridge.secureStorage"), secureStorage)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  /**
   * @dev Returns the address of the bridge registry.
   * @dev More details on bridge registry and it's purpose can be found in the BridgeRegistry smart contract.
   */
  function getBridgeRegistry() public view returns (address bridgeRegistry) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
    assembly {
      bridgeRegistry := sload(precomputeslot("eip1967.Holograph.Bridge.registry"))
    }
  }

  /**
   * @dev Sets the address of the bridge registry.
   */
  function setBridgeRegistry(address bridgeRegistry) public onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.registry"), bridgeRegistry)
    }
  }

  /**
   * @dev Returns the address of holograph.
   * @dev More details on bridge holograph and it's purpose can be found in the Holograph smart contract.
   */
  function getHolograph() public view returns (address holograph) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.holograph')) - 1);
    assembly {
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
    }
  }

  /**
   * @dev Sets the address of holograph.
   */
  function setHolograph(address holograph) public onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.holograph')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.holograph"), holograph)
    }
  }

  /**
   * @dev Returns the address of the secure storage smart contract source code.
   * @dev More details on secure storage and it's purpose can be found in the SecureStorage smart contract.
   */
  function getSecureStorage() public view returns (address secureStorage) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
    assembly {
      secureStorage := sload(precomputeslot("eip1967.Holograph.Bridge.secureStorage"))
    }
  }

  /**
   * @dev Sets the address of the secure storage smart contract source code.
   */
  function setSecureStorage(address secureStorage) public onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.secureStorage"), secureStorage)
    }
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
    // all of the necessary data is packed and hashed
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
    // we check that a smart contract for this hash has not been deployed yet
    require(!IHolographRegistry(getBridgeRegistry()).isHolographedHashDeployed(hash), "HOLOGRAPH: already deployed");
    // hash is converted to an integer, in preparation for the create2 function
    uint256 saltInt = uint256(hash);
    address secureStorageAddress;
    // we combine the secure storage proxy bytecode parts, with the bridge registry address included
    bytes memory secureStorageBytecode = type(SecureStorageProxy).creationCode;
    // the combined bytecode is then deployed
    assembly {
      secureStorageAddress := create2(0, add(secureStorageBytecode, 0x20), mload(secureStorageBytecode), saltInt)
    }
    //
    address sourceContractAddress = address(
      uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), saltInt, keccak256(config.byteCode)))))
    );
    bytes memory sourceByteCode = config.byteCode;
    if (!_isContract(sourceContractAddress)) {
      assembly {
        sourceContractAddress := create2(0, add(sourceByteCode, 0x20), mload(sourceByteCode), saltInt)
      }
      require(_isContract(sourceContractAddress), "source contract create failed");
    }
    bytes memory holographerBytecode = type(Holographer).creationCode;
    address holographerAddress = address(
      uint160(
        uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), saltInt, keccak256(holographerBytecode))))
      )
    );
    require(!_isContract(holographerAddress), "HOLOGRAPH: already deployed");
    // the combined bytecode is then deployed
    assembly {
      holographerAddress := create2(0, add(holographerBytecode, 0x20), mload(holographerBytecode), saltInt)
    }
    require(_isContract(holographerAddress), "Holographer deployment failed");
    require(
      IInitializable(secureStorageAddress).init(abi.encode(getSecureStorage(), abi.encode(holographerAddress))) ==
        IInitializable.init.selector,
      "initialization failed"
    );
    address holograph;
    assembly {
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
    }
    bytes memory encodedInit = abi.encode(
      abi.encode(config.chainType, holograph, secureStorageAddress, config.contractType, sourceContractAddress),
      config.initCode
    );
    require(
      IInitializable(holographerAddress).init(encodedInit) == IInitializable.init.selector,
      "initialization failed"
    );
    //
    IHolographRegistry(getBridgeRegistry()).factoryDeployedHash(hash, holographerAddress);
    // we emit the event to indicate to anyone listening to the blockchain that a bridgeable smart contract has been deployed
    emit BridgeableContractDeployed(holographerAddress, hash);
  }

  function _isContract(address contractAddress) internal view returns (bool) {
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
  ) internal pure returns (bool) {
    if (v < 27) {
      v += 27;
    }
    return (ecrecover(hash, v, r, s) == signer ||
      ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == signer);
  }
}
