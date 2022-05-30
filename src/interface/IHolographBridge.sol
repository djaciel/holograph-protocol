/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../struct/DeploymentConfig.sol";
import "../struct/Verification.sol";

interface IHolographBridge {
  function executeJob(bytes calldata _payload) external;

  function erc721in(
    uint32 fromChain,
    address collection,
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  function erc721out(
    uint32 toChain,
    address collection,
    address from,
    address to,
    uint256 tokenId
  ) external payable;

  function erc20in(
    uint32 fromChain,
    address token,
    address from,
    address to,
    uint256 amount,
    bytes calldata data
  ) external;

  function erc20out(
    uint32 toChain,
    address token,
    address from,
    address to,
    uint256 amount
  ) external payable;

  function deployIn(bytes calldata data) external;

  function deployOut(
    uint32 toChain,
    DeploymentConfig calldata config,
    Verification calldata signature,
    address signer
  ) external payable;
}
