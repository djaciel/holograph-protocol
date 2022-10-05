/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

interface IHolographRegistry {
  function factoryDeployedHash(bytes32 hash, address contractAddress) external;

  function getContractTypeAddress(bytes32 contractType) external view returns (address);

  function getHolograph() external view returns (address holograph);

  function getHolographableContracts(uint256 index, uint256 length) external view returns (address[] memory contracts);

  function getHolographableContractsLength() external view returns (uint256);

  function getHolographedHashAddress(bytes32 hash) external view returns (address);

  function getHToken(uint32 chainId) external view returns (address);

  function getUtilityToken() external view returns (address tokenContract);

  function isHolographedContract(address smartContract) external view returns (bool);

  function isHolographedHashDeployed(bytes32 hash) external view returns (bool);

  function referenceContractTypeAddress(address contractAddress) external returns (bytes32);

  function setContractTypeAddress(bytes32 contractType, address contractAddress) external;

  function setHolograph(address holograph) external;

  function setHToken(uint32 chainId, address hToken) external;

  function setUtilityToken(address tokenContract) external;

  function updateReservedContractTypes(bytes32[] calldata hashes, bool[] calldata reserved) external;
}
