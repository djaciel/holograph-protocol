// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

import {ILBPair} from "./ILBPair.sol";

interface ILBRouter {
  function getSwapIn(
    ILBPair LBPair,
    uint128 amountOut,
    bool swapForY
  ) external view returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);
}
