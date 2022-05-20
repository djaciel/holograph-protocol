// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

             - one bridge, infinite possibilities -


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

library ChainId {
  function lz2hlg(uint16 lzChainId) internal pure returns (uint32 hlgChainId) {
    assembly {
      switch lzChainId
      // eth
      case 1 {
        hlgChainId := 1
      }
      // bsc
      case 2 {
        hlgChainId := 2
      }
      // avalanche
      case 6 {
        hlgChainId := 3
      }
      // polygon
      case 9 {
        hlgChainId := 4
      }
      // arbitrum
      case 10 {
        hlgChainId := 6
      }
      // optimism
      case 11 {
        hlgChainId := 7
      }
      // fantom
      case 12 {
        hlgChainId := 5
      }
      // rinkeby
      case 10001 {
        hlgChainId := 4000000001
      }
      // bsc testnet
      case 10002 {
        hlgChainId := 4000000002
      }
      // fuji
      case 10006 {
        hlgChainId := 4000000003
      }
      // mumbai
      case 10009 {
        hlgChainId := 4000000004
      }
      // arbitrum rinkeby
      case 10010 {
        hlgChainId := 4000000006
      }
      // optimism kovan
      case 10011 {
        hlgChainId := 4000000007
      }
      // fantom testnet
      case 10012 {
        hlgChainId := 4000000005
      }
      // local2
      case 65534 {
        hlgChainId := 4294967294
      }
      // local
      case 65535 {
        hlgChainId := 4294967295
      }
      default {
        hlgChainId := 0
      }
    }
  }

  function hlg2lz(uint32 hlgChainId) internal pure returns (uint16 lzChainId) {
    assembly {
      switch hlgChainId
      // eth
      case 1 {
        lzChainId := 1
      }
      // bsc
      case 2 {
        lzChainId := 2
      }
      // avalanche
      case 3 {
        lzChainId := 6
      }
      // polygon
      case 4 {
        lzChainId := 9
      }
      // fantom
      case 5 {
        lzChainId := 12
      }
      // arbitrum
      case 6 {
        lzChainId := 10
      }
      // optimism
      case 7 {
        lzChainId := 11
      }
      // rinkeby
      case 4000000001 {
        lzChainId := 10001
      }
      // bsc testnet
      case 4000000002 {
        lzChainId := 10002
      }
      // fuji
      case 4000000003 {
        lzChainId := 10006
      }
      // mumbai
      case 4000000004 {
        lzChainId := 10009
      }
      // fantom testnet
      case 4000000005 {
        lzChainId := 10012
      }
      // arbitrum rinkeby
      case 4000000006 {
        lzChainId := 10010
      }
      // optimism kovan
      case 4000000007 {
        lzChainId := 10011
      }
      // local2
      case 4294967294 {
        lzChainId := 65534
      }
      // local
      case 4294967295 {
        lzChainId := 65535
      }
      default {
        lzChainId := 0
      }
    }
  }

  function syn2hlg(uint32 synChainId) internal pure returns (uint32 hlgChainId) {
    return synChainId;
  }

  function hlg2syn(uint32 hlgChainId) internal pure returns (uint32 synChainId) {
    return hlgChainId;
  }
}
