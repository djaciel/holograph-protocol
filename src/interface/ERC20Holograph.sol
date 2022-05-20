/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Metadata.sol";
import "./ERC20Permit.sol";
import "./ERC20Receiver.sol";
import "./ERC20Safer.sol";
import "./ERC165.sol";

interface ERC20Holograph is ERC165, ERC20, ERC20Burnable, ERC20Metadata, ERC20Receiver, ERC20Safer, ERC20Permit {
  function holographBridgeIn(
    uint32 chainType,
    address from,
    address to,
    uint256 amount,
    bytes calldata data
  ) external returns (bytes4);

  function holographBridgeOut(
    uint32 chainType,
    address operator,
    address from,
    address to,
    uint256 amount
  ) external returns (bytes4, bytes memory data);

  function sourceBurn(address from, uint256 amount) external;

  function sourceMint(address to, uint256 amount) external;

  function sourceMintBatch(address[] calldata wallets, uint256[] calldata amounts) external;

  function sourceTransfer(
    address from,
    address to,
    uint256 amount
  ) external;
}
