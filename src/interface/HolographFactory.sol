HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

interface HolographFactory {

    event Deployed(address indexed contractAddress, bytes32 indexed hash);

    function getAdmin() external view returns (address admin);

    function setAdmin(address admin) external;

    function getChainType() external view returns (uint256 chainType);

    function setChainType(uint256 chainType) external;

    function getBridgeRegistry() external view returns (address bridgeRegistry);

    function setBridgeRegistry(address bridgeRegistry) external;

    function getSecureStorage() external view returns (address secureStorage);

    function setSecureStorage(address secureStorage) external;

    function deploy(uint256 contractType, uint256 chainType, bool openBridge, uint64 bridgeFee, address originalContractOwner) external;

}
