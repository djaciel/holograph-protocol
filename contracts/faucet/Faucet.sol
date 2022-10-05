// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

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
