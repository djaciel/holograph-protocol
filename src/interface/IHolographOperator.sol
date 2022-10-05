/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../struct/OperatorJob.sol";

interface IHolographOperator {
  /**
   * @dev Event is emitted for every time that a valid job is available.
   */
  event AvailableOperatorJob(bytes32 jobHash, bytes payload);

  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) external payable;

  function executeJob(bytes calldata _payload) external payable;

  function jobEstimator(bytes calldata _payload) external payable returns (uint256 leftoverGas);

  function send(
    uint256 gas,
    uint256 gasPrice,
    uint32 toChain,
    address msgSender,
    bytes calldata _payload
  ) external payable;

  function getJobDetails(bytes32 jobHash) external view returns (OperatorJob memory);

  function getPodOperators(uint256 pod) external view returns (address[] memory operators);

  function getPodOperators(
    uint256 pod,
    uint256 index,
    uint256 length
  ) external view returns (address[] memory operators);

  function getPodBondAmount(uint256 pod) external view returns (uint256 base, uint256 current);

  function getBondedPod(address operator) external view returns (uint256 pod);

  function unbondUtilityToken(address operator, address recipient) external;

  function bondUtilityToken(
    address operator,
    uint256 amount,
    uint256 pod
  ) external;

  function getLZEndpoint() external view returns (address lZEndpoint);

  function setLZEndpoint(address lZEndpoint) external;

  function getBridge() external view returns (address bridge);

  function setBridge(address bridge) external;

  function getInterfaces() external view returns (address interfaces);

  function setInterfaces(address interfaces) external;

  function getRegistry() external view returns (address registry);

  function setRegistry(address registry) external;

  function getUtilityToken() external view returns (address utilityToken);

  function setUtilityToken(address utilityToken) external;
}
