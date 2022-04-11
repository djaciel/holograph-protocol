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

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IInitializable.sol";

contract Holograph is Admin, Initializable {

    constructor() Admin(false) {}

    function init(bytes memory data) external override returns (bytes4) {
        require(!_isInitialized(), "HOLOGRAPH: already initialized");
        (uint32 chainType, address registry, address factory, address bridge, address secureStorage) = abi.decode(data, (uint32, address, address, address, address));
        assembly {
            sstore(0xf659863303d91045cf6f5789ae687c591017a1efd53ebb2eec518fb10873ecb8, chainType)
            sstore(0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349, registry)
            sstore(0x7eefc8e705e14d34b5d1d6c3ea7f4e20cecb5956b182bac952a455d9372b87e2, factory)
            sstore(0x03be85923973d3197c19b1ad1f9b28c331dd9229cd80cbf84926b2286fc4563f, bridge)
            sstore(0xd26498b26a05274577b8ac2e3250418da53433f3ff82027428ee3c530702cdec, secureStorage)
        }
        _setInitialized();
        return IInitializable.init.selector;
    }

    /*
     * @dev Returns an integer value of the chain type that the factory is currently on.
     * @dev For example:
     *                   1 = Ethereum mainnet
     *                   2 = Binance Smart Chain mainnet
     *                   3 = Avalanche mainnet
     *                   4 = Polygon mainnet
     *                   etc.
     */
    function getChainType() public view returns (uint32 chainType) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.chainType')) - 1);
        assembly {
            chainType := sload(0xf659863303d91045cf6f5789ae687c591017a1efd53ebb2eec518fb10873ecb8)
        }
    }

    /*
     * @dev Sets the chain type that the factory is currently on.
     */
    function setChainType(uint32 chainType) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.chainType')) - 1);
        assembly {
            sstore(0xf659863303d91045cf6f5789ae687c591017a1efd53ebb2eec518fb10873ecb8, chainType)
        }
    }

    function getBridge() external view returns (address bridge) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.bridge')) - 1);
        assembly {
            bridge := sload(0x03be85923973d3197c19b1ad1f9b28c331dd9229cd80cbf84926b2286fc4563f)
        }
    }

    function setBridge(address bridge) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.bridge')) - 1);
        assembly {
            sstore(/* slot */0x03be85923973d3197c19b1ad1f9b28c331dd9229cd80cbf84926b2286fc4563f, bridge)
        }
    }

    function getFactory() external view returns (address factory) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factory')) - 1);
        assembly {
            factory := sload(/* slot */0x7eefc8e705e14d34b5d1d6c3ea7f4e20cecb5956b182bac952a455d9372b87e2)
        }
    }

    function setFactory(address factory) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factory')) - 1);
        assembly {
            sstore(/* slot */0x7eefc8e705e14d34b5d1d6c3ea7f4e20cecb5956b182bac952a455d9372b87e2, factory)
        }
    }

    function getRegistry() external view returns (address registry) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
        assembly {
            registry := sload(/* slot */0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349)
        }
    }

    function setRegistry(address registry) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
        assembly {
            sstore(/* slot */0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349, registry)
        }
    }

    function getSecureStorage() external view returns (address secureStorage) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
        assembly {
            secureStorage := sload(/* slot */0xd26498b26a05274577b8ac2e3250418da53433f3ff82027428ee3c530702cdec)
        }
    }

    function setSecureStorage(address secureStorage) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
        assembly {
            sstore(/* slot */0xd26498b26a05274577b8ac2e3250418da53433f3ff82027428ee3c530702cdec, secureStorage)
        }
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

}
