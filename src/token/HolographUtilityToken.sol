/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/ERC20H.sol";

import "../interface/ERC20.sol";
import "../interface/ERC20Holograph.sol";
import "../interface/IHolograph.sol";
import "../interface/IHolographer.sol";

/**
 * @title Holograph Utility Token.
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph's ERC20 Utility Tokens.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract HolographUtilityToken is ERC20H {
  constructor() {}

  /**
   * @notice Initializes the token.
   * @dev Special function to allow a one time initialisation on deployment.
   */
  function init(bytes memory data) external override returns (bytes4) {
    address contractOwner = abi.decode(data, (address));
    _setOwner(contractOwner);
    // run underlying initializer logic
    return _init(data);
  }
}
