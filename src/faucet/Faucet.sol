/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Initializable.sol";
import "../interface/ERC20Holograph.sol";
import "../interface/IInitializable.sol";

contract Faucet is Initializable {
  address public owner;
  ERC20Holograph public token;

  uint256 public faucetDripAmount = 100 ether;
  uint256 public faucetCooldown = 24 hours;

  mapping(address => uint256) lastAccessTime;

  /**
   * @notice Constructor is empty and not utilised.
   * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
   */
  constructor() {}

  /**
   * @notice Initializes the token.
   * @dev Special function to allow a one time initialisation on deployment.
   */
  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "Faucet contract is already initialized");
    (address contractOwner_, address tokenInstance_) = abi.decode(data, (address, address));
    token = ERC20Holograph(tokenInstance_);
    owner = contractOwner_;
    _setInitialized();
    return IInitializable.init.selector;
  }

  /// @notice Get tokens from faucet's own balance. Rate limited.
  function requestTokens() external {
    require(isAllowedToWithdraw(msg.sender), "Come back later");
    require(token.balanceOf(address(this)) >= faucetDripAmount, "Faucet is empty");
    lastAccessTime[msg.sender] = block.timestamp;
    token.transfer(msg.sender, faucetDripAmount);
  }

  /// @notice Grant tokens to receiver from faucet's own balance. Not rate limited.
  function grantTokens(address address_) external onlyOwner {
    require(token.balanceOf(address(this)) >= faucetDripAmount, "Faucet is empty");
    token.transfer(address_, faucetDripAmount);
  }

  function grantTokens(address address_, uint256 amountWei_) external onlyOwner {
    require(token.balanceOf(address(this)) >= amountWei_, "Insufficient funds");
    token.transfer(address_, amountWei_);
  }

  /// @notice Withdraw all funds from the faucet.
  function withdrawAllTokens(address receiver_) external onlyOwner {
    token.transfer(receiver_, token.balanceOf(address(this)));
  }

  /// @notice Withdraw amount of funds from the faucet. Amount is in wei.
  function withdrawTokens(address receiver_, uint256 amountWei_) external onlyOwner {
    require(token.balanceOf(address(this)) >= amountWei_, "Insufficient funds");
    token.transfer(receiver_, amountWei_);
  }

  /// @notice Configure the time between two drip requests. Time is in seconds.
  function setWithdrawCooldown(uint256 waitTimeSeconds_) external onlyOwner {
    faucetCooldown = waitTimeSeconds_;
  }

  /// @notice Configure the drip request amount. Amount is in wei.
  function setWithdrawAmount(uint256 amountWei_) external onlyOwner {
    faucetDripAmount = amountWei_;
  }

  /// @notice Check whether an address can request drip and is not on cooldown.
  function isAllowedToWithdraw(address address_) public view returns (bool) {
    if (lastAccessTime[address_] == 0) {
      return true;
    } else if (block.timestamp >= lastAccessTime[address_] + faucetCooldown) {
      return true;
    }
    return false;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Caller is not the owner");
    _;
  }
}
