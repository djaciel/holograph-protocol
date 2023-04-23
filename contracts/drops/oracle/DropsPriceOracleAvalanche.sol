// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {Admin} from "../../abstract/Admin.sol";
import {Initializable} from "../../abstract/Initializable.sol";

import {IDropsPriceOracle} from "../interface/IDropsPriceOracle.sol";
import {ILBPair} from "./interface/ILBPair.sol";
import {ILBRouter} from "./interface/ILBRouter.sol";

contract DropsPriceOracleAvalanche is Admin, Initializable, IDropsPriceOracle {
  address constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // 18 decimals
  address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; // 6 decimals
  address constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7; // 6 decimals

  ILBRouter constant TraderJoeRouter = ILBRouter(0xE3Ffc583dC176575eEA7FD9dF2A7c65F7E23f4C3);
  ILBPair constant TraderJoeUsdcPool = ILBPair(0xB5352A39C11a81FE6748993D586EC448A01f08b5);
  ILBPair constant TraderJoeUsdtPool = ILBPair(0xdF3E481a05F58c387Af16867e9F5dB7f931113c9);

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
    weiAmount = (_getTraderJoeUSDC(usdAmount) + _getTraderJoeUSDT(usdAmount)) / 2;
  }

  function _getTraderJoeUSDC(uint256 usdAmount) internal view returns (uint256 weiAmount) {
    // add decimal places for amount IF decimals are above 6!
    // usdAmount = usdAmount * (10**(18 - 6));
    (uint256 amountIn, uint256 feesIn) = TraderJoeRouter.getSwapIn(TraderJoeUsdcPool, usdAmount, false);
    weiAmount = amountIn + feesIn;
  }

  function _getTraderJoeUSDT(uint256 usdAmount) internal view returns (uint256 weiAmount) {
    // add decimal places for amount IF decimals are above 6!
    // usdAmount = usdAmount * (10**(18 - 6));
    (uint256 amountIn, uint256 feesIn) = TraderJoeRouter.getSwapIn(TraderJoeUsdtPool, usdAmount, false);
    weiAmount = amountIn + feesIn;
  }
}
