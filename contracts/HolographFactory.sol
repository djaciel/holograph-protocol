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

pragma solidity 0.8.12;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./Holographer.sol";

import "./interface/IHolograph.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";
import "./interface/SecureStorage.sol";

import "./proxy/SecureStorageProxy.sol";

import "./struct/DeploymentConfig.sol";
import "./struct/Verification.sol";

/*
 * @dev This smart contract demonstrates a clear and concise way that we plan to deploy smart contracts.
 * @dev With the goal of deploying replicate-able non-fungible token smart contracts through this process.
 * @dev This is just the first step. But it is fundamental for achieving cross-chain non-fungible tokens.
 */
contract HolographFactory is Admin, Initializable {

    /*
     * @dev This event is fired every time that a bridgeable contract is deployed.
     */
    event BridgeableContractDeployed(address indexed contractAddress, bytes32 indexed hash);

    /*
     * @dev Constructor is left empty and only the admin address is set.
     */
    constructor() Admin(false) {}

    function init(bytes memory data) external override returns (bytes4) {
        require(!_isInitialized(), "HOLOGRAPH: already initialized");
        (address registry, address secureStorage) = abi.decode(data, (address, address));
        assembly {
            sstore(0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349, registry)
            sstore(0xd26498b26a05274577b8ac2e3250418da53433f3ff82027428ee3c530702cdec, secureStorage)
        }
        _setInitialized();
        return IInitializable.init.selector;
    }

    /*
     * @dev Returns the address of the bridge registry.
     * @dev More details on bridge registry and it's purpose can be found in the BridgeRegistry smart contract.
     */
    function getBridgeRegistry() public view returns (address bridgeRegistry) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
        assembly {
            bridgeRegistry := sload(0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349)
        }
    }

    /*
     * @dev Sets the address of the bridge registry.
     */
    function setBridgeRegistry(address bridgeRegistry) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
        assembly {
            sstore(0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349, bridgeRegistry)
        }
    }

    /*
     * @dev Returns the address of the secure storage smart contract source code.
     * @dev More details on secure storage and it's purpose can be found in the SecureStorage smart contract.
     */
    function getSecureStorage() public view returns (address secureStorage) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
        assembly {
            secureStorage := sload(0xd26498b26a05274577b8ac2e3250418da53433f3ff82027428ee3c530702cdec)
        }
    }

    /*
     * @dev Sets the address of the secure storage smart contract source code.
     */
    function setSecureStorage(address secureStorage) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
        assembly {
            sstore(0xd26498b26a05274577b8ac2e3250418da53433f3ff82027428ee3c530702cdec, secureStorage)
        }
    }

    /*
     * @dev A sample function of the deployment of bridgeable smart contracts.
     * @dev The used variables and formatting is not the final or decisive version, but the general idea is directly portrayed.
     * @notice In this function we have incorporated a secure storage function/extension. Keep in mind that this is not required or needed for bridgeable deployments to work. It is just a personal development choice.
     */
    function deployHolographableContract(DeploymentConfig calldata config, Verification calldata signature, address signer) external {
        // all of the necessary data is packed and hashed
        bytes32 hash = keccak256(abi.encodePacked(
            config.contractType,
            config.chainType,
            config.salt,
            keccak256(config.byteCode),
            keccak256(config.initCode),
            signer
        ));
        require(_verifySigner(signature.r, signature.s, signature.v, hash, signer), "HOLOGRAPH: invalid signature");
        // we check that a smart contract for this hash has not been deployed yet
        require(!IHolographRegistry(getBridgeRegistry()).isHolographedHashDeployed(hash), "HOLOGRAPH: already deployed");
        // hash is converted to an integer, in preparation for the create2 function
        uint256 saltInt = uint256(hash);
        address secureStorageAddress;
        // we combine the secure storage proxy bytecode parts, with the bridge registry address included
        bytes memory secureStorageBytecode = type(SecureStorageProxy).creationCode;
        // the combined bytecode is then deployed
        assembly {
            secureStorageAddress := create2(0, add(secureStorageBytecode, 0x20), mload(secureStorageBytecode), saltInt)
        }
        //
        address sourceContractAddress = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), saltInt, keccak256(config.byteCode))))));
        bytes memory sourceByteCode = config.byteCode;
        if (!_isContract(sourceContractAddress)) {
            assembly {
                sourceContractAddress := create2(0, add(sourceByteCode, 0x20), mload(sourceByteCode), saltInt)
            }
            require(_isContract(sourceContractAddress), "source contract create failed");
        }
        bytes memory holographerBytecode = type(Holographer).creationCode;
        address holographerAddress = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), saltInt, keccak256(holographerBytecode))))));
        require(!_isContract(holographerAddress), "HOLOGRAPH: already deployed");
        // the combined bytecode is then deployed
        assembly {
            holographerAddress := create2(0, add(holographerBytecode, 0x20), mload(holographerBytecode), saltInt)
        }
        require(_isContract(holographerAddress), "Holographer deployment failed");
        require(
            IInitializable(secureStorageAddress).init(
                abi.encode(
                    getSecureStorage(),
                    abi.encode(
                        holographerAddress
                    )
                )
            ) == IInitializable.init.selector,
            "initialization failed"
        );
        bytes memory encodedInit = abi.encode(
            abi.encode(
                config.chainType,
                0x020be79e2D5a6a0204C07970F3586dc379d142e0,
                secureStorageAddress,
                config.contractType,
                sourceContractAddress
            ),
            config.initCode
        );
        require(IInitializable(holographerAddress).init(encodedInit) == IInitializable.init.selector, "initialization failed");
        //
        IHolographRegistry(getBridgeRegistry()).factoryDeployedHash(hash, holographerAddress);
        // we emit the event to indicate to anyone listening to the blockchain that a bridgeable smart contract has been deployed
        emit BridgeableContractDeployed(holographerAddress, hash);
    }

    function _isContract(address contractAddress) internal view returns (bool) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(contractAddress)
        }
        return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function _verifySigner(bytes32 r, bytes32 s, uint8 v, bytes32 hash, address signer) internal pure returns (bool) {
        if (v < 27) {
            v += 27;
        }
        return (ecrecover(hash, v, r, s) == signer || ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == signer);
    }

}
