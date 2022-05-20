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

library Signature {
  function Derive(
    bytes32 r,
    bytes32 s,
    uint8 v,
    bytes memory encoded
  )
    internal
    pure
    returns (
      address derived1,
      address derived2,
      address derived3,
      address derived4
    )
  {
    bytes32 encoded32;
    assembly {
      encoded32 := mload(add(encoded, 32))
    }
    derived1 = ecrecover(encoded32, v, r, s);
    derived2 = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32)), v, r, s);
    encoded32 = keccak256(encoded);
    derived3 = ecrecover(encoded32, v, r, s);
    encoded32 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32));
    derived4 = ecrecover(encoded32, v, r, s);
  }

  function PackMessage(bytes memory encoded, bool geth) internal pure returns (bytes32) {
    bytes32 hash = keccak256(encoded);
    if (geth) {
      hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    return hash;
  }

  function Valid(
    address target,
    bytes32 r,
    bytes32 s,
    uint8 v,
    bytes memory encoded
  ) internal pure returns (bool) {
    bytes32 encoded32;
    address derived;
    if (encoded.length == 32) {
      assembly {
        encoded32 := mload(add(encoded, 32))
      }
      derived = ecrecover(encoded32, v, r, s);
      if (target == derived) {
        return true;
      }
      derived = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32)), v, r, s);
      if (target == derived) {
        return true;
      }
    }
    bytes32 hash = keccak256(encoded);
    derived = ecrecover(hash, v, r, s);
    if (target == derived) {
      return true;
    }
    hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    derived = ecrecover(hash, v, r, s);
    return target == derived;
  }
}
