HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

interface IHolograph {

    function getChainType() external view returns (uint32 chainType);

    function getBridge() external view returns (address bridgeAddress);

    function getFactory() external view returns (address factoryAddress);

    function getRegistry() external view returns (address registryAddress);

}
