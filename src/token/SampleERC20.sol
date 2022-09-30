/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/StrictERC20H.sol";

import "../interface/ERC20Holograph.sol";

/**
 * @title Sample ERC-20 token that is bridgeable via Holograph
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph Bridgeable ERC20 Tokens.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract SampleERC20 is StrictERC20H {
  /**
   * @dev Just a dummy value for now to test transferring of data.
   */
  mapping(address => bytes32) private _walletSalts;

  /**
   * @dev Temporary implementation to suppress compiler state mutability warnings.
   */
  bool private _dummy;

  /**
   * @notice Constructor is empty and not utilised.
   * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
   */
  constructor() {}

  /**
   * @notice Initializes the collection.
   * @dev Special function to allow a one time initialisation on deployment.
   */
  function init(bytes memory data) external override returns (bytes4) {
    // do your own custom logic here
    address contractOwner = abi.decode(data, (address));
    _setOwner(contractOwner);
    // run underlying initializer logic
    return _init(data);
  }

  /**
   * @dev Sample mint where anyone can mint any amounts of tokens.
   */
  function mint(address to, uint256 amount) external onlyHolographer onlyOwner {
    ERC20Holograph(holographer()).sourceMint(to, amount);
    if (_walletSalts[to] == bytes32(0)) {
      _walletSalts[to] = keccak256(
        abi.encodePacked(to, amount, block.timestamp, block.number, blockhash(block.number - 1))
      );
    }
  }

  function bridgeIn(
    uint32, /* _chainId*/
    address, /* _from*/
    address _to,
    uint256, /* _amount*/
    bytes calldata _data
  ) external override onlyHolographer returns (bool) {
    bytes32 salt = abi.decode(_data, (bytes32));
    _walletSalts[_to] = salt;
    return true;
  }

  function bridgeOut(
    uint32, /* _chainId*/
    address, /* _from*/
    address _to,
    uint256 /* _amount*/
  ) external override onlyHolographer returns (bytes memory _data) {
    _dummy = false;
    _data = abi.encode(_walletSalts[_to]);
  }
}
