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

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IHolograph.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";

/**
 * @dev This contract is a binder. It puts together all the variables to make the underlying contracts functional and be bridgeable.
 */
contract Holographer is Admin, Initializable {
  /**
   * @dev Constructor is left empty and only the admin address is set.
   */
  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPHER: already initialized");
    (bytes memory encoded, bytes memory initCode) = abi.decode(data, (bytes, bytes));
    (uint32 originChain, address holograph, address secureStorage, bytes32 contractType, address sourceContract) = abi
      .decode(encoded, (uint32, address, address, bytes32, address));
    assembly {
      sstore(0x5705f5753aa4f617eef2cae1dada3d3355e9387b04d19191f09b545e684ca50d, caller())
      sstore(0x2378c1f8aa4ffd1a2b352b1ec4b9fe37cee7d2bb3fa1a7e6aeaeb422f15defdb, originChain)
      sstore(0x1eee493315beeac80829afd0aaa340f3821cabe68571a2743478e81638a3d94d, holograph)
      sstore(0xd26498b26a05274577b8ac2e3250418da53433f3ff82027428ee3c530702cdec, secureStorage)
      sstore(0x927d33f74b40d20ebbbc7fbed0f01deacf3e0b589b248a5cc2fc82aa94928913, contractType)
      sstore(0xee63e41dd03b4d304382a6596ec5f4a6eb601d3640835d27fca1d0be62955bb5, sourceContract)
    }
    (bool success, bytes memory returnData) = getHolographEnforcer().delegatecall(
      abi.encodeWithSignature("init(bytes)", initCode)
    );
    bytes4 selector = abi.decode(returnData, (bytes4));
    require(success && selector == IInitializable.init.selector, "initialization failed");
    _setInitialized();
    return IInitializable.init.selector;
  }

  /**
   * @dev Returns a hardcoded address for the custom secure storage contract deployed in parallel with this contract deployment.
   */
  function getHolograph() public view returns (address holograph) {
    assembly {
      holograph := sload(0x1eee493315beeac80829afd0aaa340f3821cabe68571a2743478e81638a3d94d)
    }
  }

  /**
   * @dev Returns a hardcoded address for the Holograph smart contract that controls and enforces the ERC standards.
   * @dev The choice to use this approach was taken to prevent storage slot overrides.
   */
  function getHolographEnforcer() public view returns (address payable) {
    address holograph;
    bytes32 contractType;
    assembly {
      holograph := sload(
        /* slot */
        0x1eee493315beeac80829afd0aaa340f3821cabe68571a2743478e81638a3d94d
      )
      contractType := sload(
        /* slot */
        0x927d33f74b40d20ebbbc7fbed0f01deacf3e0b589b248a5cc2fc82aa94928913
      )
    }
    return payable(IHolographRegistry(IHolograph(holograph).getRegistry()).getContractTypeAddress(contractType));
  }

  /**
   * @dev Returns the original chain that contract was deployed on.
   */
  function getOriginChain() public view returns (uint32 originChain) {
    assembly {
      originChain := sload(
        /* slot */
        0x2378c1f8aa4ffd1a2b352b1ec4b9fe37cee7d2bb3fa1a7e6aeaeb422f15defdb
      )
    }
  }

  /**
   * @dev Returns a hardcoded address for the custom secure storage contract deployed in parallel with this contract deployment.
   */
  function getSecureStorage() public view returns (address secureStorage) {
    assembly {
      secureStorage := sload(
        /* slot */
        0xd26498b26a05274577b8ac2e3250418da53433f3ff82027428ee3c530702cdec
      )
    }
  }

  /**
   * @dev Returns a hardcoded address for the custom secure storage contract deployed in parallel with this contract deployment.
   */
  function getSourceContract() public view returns (address payable sourceContract) {
    assembly {
      sourceContract := sload(
        /* slot */
        0xee63e41dd03b4d304382a6596ec5f4a6eb601d3640835d27fca1d0be62955bb5
      )
    }
  }

  /**
   * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
   */
  receive() external payable {}

  /**
   * @dev Hard-coded registry address and contract type are put inside the fallback to make sure that the contract cannot be modified.
   * @dev This takes the underlying address source code, runs it, and uses current address for storage.
   */
  fallback() external payable {
    address holographEnforcer = getHolographEnforcer();
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), holographEnforcer, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}
