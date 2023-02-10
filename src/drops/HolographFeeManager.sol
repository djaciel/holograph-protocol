// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../abstract/Initializable.sol";

import {IHolographFeeManager} from "./interfaces/IHolographFeeManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract HolographFeeManager is Initializable, Ownable, IHolographFeeManager {
  mapping(address => uint256) private feeOverride;
  uint256 private defaultFeeBPS;

  event FeeOverrideSet(address indexed, uint256 indexed);

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (uint256 _defaultFeeBPS, address feeManagerAdmin) = abi.decode(data, (uint256, address));

    defaultFeeBPS = _defaultFeeBPS;
    _transferOwnership(feeManagerAdmin);
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function setFeeOverride(address target, uint256 amountBPS) external onlyOwner {
    require(amountBPS < 2001, "Fee too high (not greater than 20%)");
    feeOverride[target] = amountBPS;
    emit FeeOverrideSet(target, amountBPS);
  }

  function getWithdrawFeesBps(address target) external view returns (address payable, uint256) {
    if (feeOverride[target] > 0) {
      return (payable(owner()), feeOverride[target]);
    }
    return (payable(owner()), defaultFeeBPS);
  }
}
