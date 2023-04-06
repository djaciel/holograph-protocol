// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

import {Admin} from "../../abstract/Admin.sol";
import {Initializable} from "../../abstract/Initializable.sol";

import {IDropsPriceOracle} from "../interface/IDropsPriceOracle.sol";
import {IUniswapV2Pair} from "./interface/IUniswapV2Pair.sol";

contract DropsPriceOracleAvalanche is Admin, Initializable, IDropsPriceOracle {
  address constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // 18 decimals
  address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; // 6 decimals
  address constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7; // 6 decimals

  IUniswapV2Pair constant SushiV2UsdcPool = IUniswapV2Pair(0x6539bF462F73fF9497054bA261C195DA8639ED61);
  IUniswapV2Pair constant SushiV2UsdtPool = IUniswapV2Pair(0x7e5E4b677c2a682B6d2e95Ae3ec07ae1Ea7D3aB5);

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   */
  function init(bytes memory) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    assembly {
      sstore(_adminSlot, origin())
    }
    _setInitialized();
    return Initializable.init.selector;
  }

  /**
   * @notice Convert USD value to native gas token value
   * @dev It is important to note that different USD stablecoins use different decimal places.
   * @param usdAmount a 6 decimal places USD amount
   */
  function convertUsdToWei(uint256 usdAmount) external view returns (uint256 weiAmount) {
    weiAmount = (_getSushiUSDC(usdAmount) + _getSushiUSDT(usdAmount)) / 2;
  }

  function _getSushiUSDC(uint256 usdAmount) internal view returns (uint256 weiAmount) {
    // add decimal places for amount IF decimals are above 6!
    // usdAmount = usdAmount * (10**(18 - 6));
    (uint112 _reserve0, uint112 _reserve1, ) = SushiV2UsdcPool.getReserves();
    // x is always native token / WAVAX
    uint256 x = _reserve0;
    // y is always USD token / USDC
    uint256 y = _reserve1;

    uint256 numerator = (x * usdAmount) * 1000;
    uint256 denominator = (y - usdAmount) * 997;

    weiAmount = (numerator / denominator) + 1;
  }

  function _getSushiUSDT(uint256 usdAmount) internal view returns (uint256 weiAmount) {
    // add decimal places for amount IF decimals are above 6!
    // usdAmount = usdAmount * (10**(18 - 6));
    (uint112 _reserve0, uint112 _reserve1, ) = SushiV2UsdtPool.getReserves();
    // x is always native token / WAVAX
    uint256 x = _reserve1;
    // y is always USD token / USDT
    uint256 y = _reserve0;

    uint256 numerator = (x * usdAmount) * 1000;
    uint256 denominator = (y - usdAmount) * 997;

    weiAmount = (numerator / denominator) + 1;
  }
}
