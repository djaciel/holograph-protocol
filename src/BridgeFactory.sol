// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./interface/ISecureStorage.sol";

/*
 * @dev This smart contract demonstrates a clear and concise way that we plan to deploy smart contracts.
 * @dev With the goal of deploying replicate-able non-fungible token smart contracts through this process.
 * @dev This is just the first step. But it is fundamental for achieving cross-chain non-fungible tokens.
 */
contract BridgeFactory is Admin {

    /*
     * @dev This event is fired every time that a bridgeable contract is deployed.
     */
    event BridgeableContractDeployed(address indexed contractAddress, bytes32 indexed hash);

    /*
     * @dev Constructor is left empty and only the admin address is set.
     */
    constructor() Admin(false) {
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
    function getChainType() public view returns (uint256 chainType) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.chainType')) - 1);
        assembly {
            chainType := sload(0x53f4736b3941358c349f7ec35387508752b8072b3da9b148bd4ddfdc7193f781)
        }
    }

    /*
     * @dev Sets the chain type that the factory is currently on.
     */
    function setChainType(uint256 chainType) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.chainType')) - 1);
        assembly {
            sstore(0x53f4736b3941358c349f7ec35387508752b8072b3da9b148bd4ddfdc7193f781, chainType)
        }
    }

    /*
     * @dev Returns the address of the bridge registry.
     * @dev More details on bridge registry and it's purpose can be found in the BridgeRegistry smart contract.
     */
    function getBridgeRegistry() public view returns (address bridgeRegistry) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.bridgeRegistry')) - 1);
        assembly {
            bridgeRegistry := sload(0xfc89649c4d8647cdcc800285fa4e41291204b97fcf93802affd29dbf455c9cc7)
        }
    }

    /*
     * @dev Sets the address of the bridge registry.
     */
    function setBridgeRegistry(address bridgeRegistry) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.bridgeRegistry')) - 1);
        assembly {
            sstore(0xfc89649c4d8647cdcc800285fa4e41291204b97fcf93802affd29dbf455c9cc7, bridgeRegistry)
        }
    }

    /*
     * @dev Returns the address of the secure storage smart contract source code.
     * @dev More details on secure storage and it's purpose can be found in the SecureStorage smart contract.
     */
    function getSecureStorage() public view returns (address secureStorage) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.secureStorage')) - 1);
        assembly {
            secureStorage := sload(0x79f80368403b7edc02a8210b03e3a2e29c8161d4dd32b5c18e363302a0a04914)
        }
    }

    /*
     * @dev Sets the address of the secure storage smart contract source code.
     */
    function setSecureStorage(address secureStorage) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.secureStorage')) - 1);
        assembly {
            sstore(0x79f80368403b7edc02a8210b03e3a2e29c8161d4dd32b5c18e363302a0a04914, secureStorage)
        }
    }

    /*
     * @dev Bytecode of the Secure Storage Proxy smart contracts. Split at the point where Bridge Registry address should be.
     */
    bytes private constant _sspb1 = hex"SECURE_STORAGE_PROXY_BYTECODE_1";
    bytes private constant _sspb2 = hex"SECURE_STORAGE_PROXY_BYTECODE_2";

    /*
     * @dev Bytecode of the Bridgeable Contract smart contract. Split at the points where: Bridge Registry address, contract type, and secure storage address should be.
     */
    bytes private constant _bcb1 = hex"BRIDGEABLE_CONTRACT_BYTECODE_1";
    bytes private constant _bcb2 = hex"BRIDGEABLE_CONTRACT_BYTECODE_2";
    bytes private constant _bcb3 = hex"BRIDGEABLE_CONTRACT_BYTECODE_3";
    bytes private constant _bcb4 = hex"BRIDGEABLE_CONTRACT_BYTECODE_4";

    /*
     * @dev A sample function of the deployment of bridgeable smart contracts.
     * @dev The used variables and formatting is not the final or decisive version, but the general idea is directly portrayed.
     * @notice In this function we have incorporated a secure storage function/extension. Keep in mind that this is not required or needed for bridgeable deployments to work. It is just a personal development choice.
     */
    function deployBridgeableContract(uint256 contractType, uint256 chainType, bool openBridge, uint64 bridgeFee, address originalContractOwner, bytes calldata initCode) public {
        // all of the necessary data is packed and hashed
        bytes32 hash = keccak256(abi.encodePacked(contractType, chainType, openBridge, bridgeFee, originalContractOwner, initCode));
        // we check that a smart contract for this hash has not been deployed yet
        require(_getDeploymentAddress(hash) == address(0), "CXIP: contract already deployed");
        // hash is converted to an integer, in preparation for the create2 function
        uint256 salt = uint256(hash);
        address secureStorageAddress;
        // we combine the secure storage proxy bytecode parts, with the bridge registry address included
        bytes memory secureStorageBytecode = abi.encodePacked(
            _sspb1,
            getBridgeRegistry(),
            _sspb2
        );
        // the combined bytecode is then deployed
        assembly {
            secureStorageAddress := create2(0, add(secureStorageBytecode, 0x20), mload(secureStorageBytecode), salt)
        }
        // we now combine the bridgeable contract bytecode parts, with the relevant data packed in between the parts
        bytes memory code = abi.encodePacked(
            _bcb1,
            getBridgeRegistry(),
            _bcb2,
            contractType,
            _bcb3,
            secureStorageAddress,
            _bcb4
        );
        address contractAddress;// = address(bytes20(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code)))));
        // the combined bytecode is then deployed
        assembly {
            contractAddress := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(contractAddress)) {
                revert(0, 0)
            }
        }
        // we update the deployed secure storage proxy contract with the newly deployed bridgeable contract address
        // this allows the bridgeable smart contract to use that secure storage contract and no one else
        ISecureStorage(secureStorageAddress).setOwner(contractAddress);
        // we then initialize the smart contract with the provided init code
        (bool success, bytes memory output) = contractAddress.call(initCode);
        // check that everything completed successfully
        if (!success) {
            // if an error occurred, stop everything and spit out the error for debugging
            revert(string(output));
        }
        // we emit the event to indicate to anyone listening to the blockchain that a bridgeable smart contract has been deployed
        emit BridgeableContractDeployed(contractAddress, hash);
        // deployment map is updated with the has and deployed address, to prevent future deployments to same hash/address
        _setDeploymentAddress(hash, contractAddress);
    }

    /*
     * @dev Internal function for quickly checking if a hash has already been used to deploy a smart contract.
     * @dev If the returned address is 0, then this means that hash has not been used yet.
     */
    function _getDeploymentAddress(bytes32 slot) internal view returns (address deploymentAddress) {
        assembly {
            deploymentAddress := sload(slot)
        }
    }

    /*
     * @dev Internal function for setting the deployed address of a particular hash.
     * @dev Is used as a way to prevent re-deployment of already deployed smart contracts.
     * @dev Since using CREATE2 function allows to re-deploy/overwrite an already deployed smart contract.
     * @dev The underlying source code is not changed, but this will reset to zero all storage slots.
     */
    function _setDeploymentAddress(bytes32 slot, address deploymentAddress) internal {
        assembly {
            sstore(slot, deploymentAddress)
        }
    }

}
