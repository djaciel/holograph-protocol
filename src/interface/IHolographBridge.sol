/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

interface IHolographBridge {
  function bridgeInRequest(
    uint256 nonce,
    uint32 fromChain,
    address holographableContract,
    address hToken,
    address hTokenRecipient,
    uint256 hTokenValue,
    bool doNotRevert,
    bytes calldata data
  ) external payable;

  function bridgeOutRequest(
    uint32 toChain,
    address holographableContract,
    uint256 gasLimit,
    uint256 gasPrice,
    bytes calldata data
  ) external payable;

  function revertedBridgeOutRequest(
    address sender,
    uint32 toChain,
    address holographableContract,
    bytes calldata data
  ) external returns (string memory revertReason);

  function getBridgeOutRequestPayload(
    uint32 toChain,
    address holographableContract,
    bytes calldata data
  ) external returns (bytes memory samplePayload);

  function getFactory() external view returns (address factory);

  function setFactory(address factory) external;

  function getHolograph() external view returns (address holograph);

  function setHolograph(address holograph) external;

  function getJobNonce() external view returns (uint256 jobNonce);

  function getOperator() external view returns (address operator);

  function setOperator(address operator) external;

  function getRegistry() external view returns (address registry);

  function setRegistry(address registry) external;
}
