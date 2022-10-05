/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

interface IHolograph {
  function getBridge() external view returns (address bridge);

  function setBridge(address bridge) external;

  function getChainId() external view returns (uint256 chainId);

  function setChainId(uint256 chainId) external;

  function getFactory() external view returns (address factory);

  function setFactory(address factory) external;

  function getHolographChainId() external view returns (uint32 holographChainId);

  function setHolographChainId(uint32 holographChainId) external;

  function getInterfaces() external view returns (address interfaces);

  function setInterfaces(address interfaces) external;

  function getOperator() external view returns (address operator);

  function setOperator(address operator) external;

  function getRegistry() external view returns (address registry);

  function setRegistry(address registry) external;

  function getTreasury() external view returns (address treasury);

  function setTreasury(address treasury) external;

  function getUtilityToken() external view returns (address utilityToken);

  function setUtilityToken(address utilityToken) external;
}
