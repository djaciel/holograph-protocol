HOLOGRAPH_LICENSE_HEADER

SOLIDITY_COMPILER_VERSION

interface IHolograph {

    function getChainType() external view returns (uint32 chainType);

    function getBridge() external view returns (address bridgeAddress);

    function getFactory() external view returns (address factoryAddress);

    function getRegistry() external view returns (address registryAddress);

}
