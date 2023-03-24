// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

interface IDropsPriceOracle {
  function convertUsdToWei(uint256 usdAmount) external view returns (uint256 weiAmount);
}
