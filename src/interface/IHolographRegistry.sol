HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

interface IHolographRegistry {

    function referenceContractTypeAddress(address contractAddress) external returns (bytes32);

    function setContractTypeAddress(bytes32 contractType, address contractAddress) external;

    function updateReservedContractTypes(bytes32[] calldata hashes, bool[] calldata reserved) external;

    function getContractTypeAddress(bytes32 contractType) external view returns (address);

    function factoryDeployedHash(bytes32 hash, address contractAddress) external;

    function isHolographedContract(address smartContract) external view returns (bool);

    function isHolographedHashDeployed(bytes32 hash) external view returns (bool);

}
