/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./ERC165.sol";
import "./Holographable.sol";

interface HolographGenericInterface is ERC165, Holographable {
  function sourceEmit(bytes calldata eventData) external;

  function sourceEmit(bytes32 eventId, bytes calldata eventData) external;

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes calldata eventData
  ) external;

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes32 topic2,
    bytes calldata eventData
  ) external;

  function sourceEmit(
    bytes32 eventId,
    bytes32 topic1,
    bytes32 topic2,
    bytes32 topic3,
    bytes calldata eventData
  ) external;
}
