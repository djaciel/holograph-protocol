/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IHolograph.sol";
import "./interface/IInitializable.sol";

import "./library/ChainId.sol";

/*
 * @dev This smart contract stores the different source codes that have been prepared and can be used for bridging.
 * @dev We will store here the layer 1 for ERC721 and ERC1155 smart contracts.
 * @dev This way it can be super easy to upgrade/update the source code once, and have all smart contracts automatically updated.
 */
contract HolographRegistry is Admin, Initializable {
  /*
   * @dev A list of smart contracts that are guaranteed secure and holographable.
   */
  mapping(address => bool) private _holographedContracts;

  /*
   * @dev A list of hashes and the mapped out contract addresses.
   */
  mapping(bytes32 => address) private _holographedContractsHashMap;

  /*
   * @dev Storage slot for saving contract type to contract address references.
   */
  mapping(bytes32 => address) private _contractTypeAddresses;

  /*
   * @dev Reserved type addresses for Admin.
   *  Note: this is used for defining default contracts.
   */
  mapping(bytes32 => bool) private _reservedTypes;

  /*
   * @dev Mapping of all hTokens available for the different EVM chains
   */
  mapping(uint32 => address) private _hTokens;

  /*
   * @dev Constructor is left empty and only the admin address is set.
   */
  constructor() Admin(false) {}

  /*
   * @dev An array of initially reserved contract types for admin only to set.
   */
  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address holograph, bytes32[] memory reservedTypes) = abi.decode(data, (address, bytes32[]));
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.holograph"), holograph)
    }
    for (uint256 i = 0; i < reservedTypes.length; i++) {
      _reservedTypes[reservedTypes[i]] = true;
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  /*
   * @dev Allows to reference a deployed smart contract, and use it's code as reference inside of Holographers.
   */
  function referenceContractTypeAddress(address contractAddress) external returns (bytes32) {
    bytes32 contractType;
    assembly {
      contractType := extcodehash(contractAddress)
    }
    require(
      (contractType != 0x0 && contractType != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470),
      "HOLOGRAPH: empty contract"
    );
    require(_contractTypeAddresses[contractType] == address(0), "HOLOGRAPH: contract already set");
    require(!_reservedTypes[contractType], "HOLOGRAPH: reserved address type");
    _contractTypeAddresses[contractType] = contractAddress;
    return contractType;
  }

  /*
   * @dev Allows Holograph Factory to register a deployed contract, referenced with deployment hash.
   */
  function factoryDeployedHash(bytes32 hash, address contractAddress) external {
    address holograph;
    assembly {
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
    }
    require(msg.sender == IHolograph(holograph).getFactory(), "HOLOGRAPH: factory only function");
    _holographedContractsHashMap[hash] = contractAddress;
    _holographedContracts[contractAddress] = true;
  }

  /*
   * @dev Sets the contract address for a contract type.
   */
  function setContractTypeAddress(bytes32 contractType, address contractAddress) external onlyAdmin {
    // For now we leave overriding as possible. need to think this through.
    //require(_contractTypeAddresses[contractType] == address(0), "HOLOGRAPH: contract already set");
    require(_reservedTypes[contractType], "HOLOGRAPH: not reserved type");
    _contractTypeAddresses[contractType] = contractAddress;
  }

  /*
   * @dev Sets the hToken address for a specific chain id.
   */
  function setHToken(uint32 chainId, address hToken) external onlyAdmin {
    _hTokens[chainId] = hToken;
  }

  /*
   * @dev Allows admin to update or toggle reserved types.
   */
  function updateReservedContractTypes(bytes32[] calldata hashes, bool[] calldata reserved) external onlyAdmin {
    for (uint256 i = 0; i < hashes.length; i++) {
      _reservedTypes[hashes[i]] = reserved[i];
    }
  }

  /*
   * @dev Returns the contract address for a contract type.
   */
  function getContractTypeAddress(bytes32 contractType) external view returns (address) {
    return _contractTypeAddresses[contractType];
  }

  /*
   * @dev Returns the address for a holographed hash
   */
  function getHolographedHashAddress(bytes32 hash) external view returns (address) {
    return _holographedContractsHashMap[hash];
  }

  /*
   * @dev Returns the hToken address for a given chain id.
   */
  function getHToken(uint32 chainId) external view returns (address) {
    return _hTokens[chainId];
  }

  function isHolographedContract(address smartContract) external view returns (bool) {
    return _holographedContracts[smartContract];
  }

  function isHolographedHashDeployed(bytes32 hash) external view returns (bool) {
    return _holographedContractsHashMap[hash] != address(0);
  }
}
