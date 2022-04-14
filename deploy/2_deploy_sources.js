'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {hexify, throwError, web3Error, createNetworkPropsForUser, saveContractResult,
     generateExpectedAddress
} = require("./helpers/utils");
const {getGenesisContract, getHolographContract, getHolographFactoryContract, getHolographFactoryProxyContract,
    getHolographBridgeContract, getHolographBridgeProxyContract, getHolographRegistryContract, getPA1DContract,
    getHolographRegistryProxyContract, getSecureStorageContract, getSecureStorageProxyContract
} = require("./helpers/contracts");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)
    const salt = '0x000000000000000000000000';

    const defaultTXOptions = {
        chainId: network.chain,
        from: provider.addresses[0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }

    const GENESIS = getGenesisContract(web3, NETWORK)

// HolographRegistry
        const HOLOGRAPH_REGISTRY = getHolographRegistryContract(web3, NETWORK)

        const holographRegistryDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_REGISTRY.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['bytes32[]'],
                [[]]
            ) // bytes memory initCode
        ).send (defaultTXOptions).catch(web3Error);

        let holographRegistryAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_REGISTRY.artifact.bin
        })

        if (!holographRegistryDeploymentResult.status) {
            throwError (JSON.stringify (holographRegistryDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_REGISTRY.artifact ['bin-runtime'] != await web3.eth.getCode (holographRegistryAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographRegistryAddress');
        }

        saveContractResult(NETWORK, HOLOGRAPH_REGISTRY.name, holographRegistryAddress)

// HolographRegistryProxy
        const HOLOGRAPH_REGISTRY_PROXY = getHolographRegistryProxyContract(web3, NETWORK)

        const holographRegistryProxyDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_REGISTRY_PROXY.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'bytes'],
                [
                    holographRegistryAddress,
                    web3.eth.abi.encodeParameters (
                        ['bytes32[]'],
                        [
                            [
                                '0x0000000000000000000000000000000000486f6c6f6772617068455243373231', // HolographERC721
                                '0x0000000000000000000000000000000000000000000000000000000050413144'  // PA1D
                            ]
                        ]
                    )
                ]
            ) // bytes memory initCode
        ).send (defaultTXOptions).catch(web3Error);

        let holographRegistryProxyAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_REGISTRY_PROXY.artifact.bin
        })

        if (!holographRegistryProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographRegistryProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_REGISTRY_PROXY.artifact['bin-runtime'] != await web3.eth.getCode (holographRegistryProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographRegistryProxyAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_REGISTRY_PROXY.name, holographRegistryProxyAddress)

// HolographFactory
        const HOLOGRAPH_FACTORY = getHolographFactoryContract(web3, NETWORK)

        const holographFactoryDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_FACTORY.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'address'],
                ['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (3000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch(web3Error);

        let holographFactoryAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_FACTORY.artifact.bin
        })

        if (!holographFactoryDeploymentResult.status) {
            throwError (JSON.stringify (holographFactoryDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_FACTORY.artifact['bin-runtime'] != await web3.eth.getCode (holographFactoryAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographFactoryAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_FACTORY.name, holographFactoryAddress)

// SecureStorage
        const SECURE_STORAGE = getSecureStorageContract(web3, NETWORK)

        const secureStorageDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + SECURE_STORAGE.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address'],
                ['0x0000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send (defaultTXOptions).catch(web3Error);

        let secureStorageAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: SECURE_STORAGE.artifact.bin
        })

        if (!secureStorageDeploymentResult.status) {
            throwError (JSON.stringify (secureStorageDeploymentResult, null, 4));
        }
        if ('0x' + SECURE_STORAGE.artifact['bin-runtime'] != await web3.eth.getCode (secureStorageAddress)) {
            throwError ('Could not properly compute CREATE2 address for secureStorageAddress');
        }
        saveContractResult(NETWORK, SECURE_STORAGE.name, secureStorageAddress)

// SecureStorageProxy
        const SECURE_STORAGE_PROXY = getSecureStorageProxyContract(web3, NETWORK)

        const secureStorageProxyDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + SECURE_STORAGE_PROXY.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'bytes'],
                [
                    secureStorageAddress,
                    web3.eth.abi.encodeParameters (
                        ['address'],
                        ['0x0000000000000000000000000000000000000000']
                    ) // bytes memory initCode
                ]
            ) // bytes memory initCode
        ).send (defaultTXOptions).catch(web3Error);

        let secureStorageProxyAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: SECURE_STORAGE_PROXY.artifact.bin
        })

        if (!secureStorageProxyDeploymentResult.status) {
            throwError (JSON.stringify (secureStorageProxyDeploymentResult, null, 4));
        }
        if ('0x' + SECURE_STORAGE_PROXY.artifact['bin-runtime'] != await web3.eth.getCode (secureStorageProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for secureStorageProxyAddress');
        }
        saveContractResult(NETWORK, SECURE_STORAGE_PROXY.name, secureStorageProxyAddress)

// HolographFactoryProxy
        const HOLOGRAPH_FACTORY_PROXY = getHolographFactoryProxyContract(web3, NETWORK)

        const holographFactoryProxyDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_FACTORY_PROXY.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'bytes'],
                [
                    holographFactoryAddress,
                    web3.eth.abi.encodeParameters (
                        ['address', 'address'],
                        [holographRegistryProxyAddress, secureStorageAddress]
                    ) // bytes memory initCode
                ]
            ) // bytes memory initCode
        ).send(defaultTXOptions).catch(web3Error);

        let holographFactoryProxyAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_FACTORY_PROXY.artifact.bin
        })

        if (!holographFactoryProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographFactoryProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_FACTORY_PROXY.artifact['bin-runtime'] != await web3.eth.getCode (holographFactoryProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographFactoryProxyAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_FACTORY_PROXY.name, holographFactoryProxyAddress)

// HolographBridge
        const HOLOGRAPH_BRIDGE = getHolographBridgeContract(web3, NETWORK)

        const holographBridgeDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_BRIDGE.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'address'],
                ['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (2000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch(web3Error);

        let holographBridgeAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_BRIDGE.artifact.bin
        })

        if (!holographBridgeDeploymentResult.status) {
            throwError (JSON.stringify (holographBridgeDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_BRIDGE.artifact['bin-runtime'] != await web3.eth.getCode (holographBridgeAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographBridgeAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_BRIDGE.name, holographBridgeAddress)

// HolographBridgeProxy
        const HOLOGRAPH_BRIDGE_PROXY = getHolographBridgeProxyContract(web3, NETWORK)

        const holographBridgeProxyDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_BRIDGE_PROXY.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'bytes'],
                [
                    holographBridgeAddress,
                    web3.eth.abi.encodeParameters (
                        ['address', 'address'],
                        [holographRegistryProxyAddress, holographFactoryProxyAddress]
                    ) // bytes memory initCode
                ]
            ) // bytes memory initCode
        ).send(defaultTXOptions).catch(web3Error);

        let holographBridgeProxyAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_BRIDGE_PROXY.artifact.bin
        })

        if (!holographBridgeProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographBridgeProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_BRIDGE_PROXY.artifact['bin-runtime'] != await web3.eth.getCode (holographBridgeProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographBridgeProxyAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_BRIDGE_PROXY.name, holographBridgeProxyAddress)

// Holograph
        const HOLOGRAPH = getHolographContract(web3, NETWORK)

        const holographDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['uint32', 'address', 'address', 'address', 'address'],
                [
                    hexify (network.holographId.toString (16).padStart (8, '0'), true),
                    holographRegistryProxyAddress,
                    holographFactoryProxyAddress,
                    holographBridgeProxyAddress,
                    secureStorageProxyAddress
                ]
            ) // bytes memory initCode
        ).send(defaultTXOptions).catch(web3Error);

        let holographAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH.artifact.bin
        })
        if (!holographDeploymentResult.status) {
            throwError (JSON.stringify (holographDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH.artifact['bin-runtime'] != await web3.eth.getCode (holographAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH.name, holographAddress)

// PA1D
        const PA1D = getPA1DContract(web3, NETWORK)

        const pa1dDeploymentResult = await GENESIS.contract.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + PA1D.artifact.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'uint256'],
                [provider.addresses [0], '0x0000000000000000000000000000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (5000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch(web3Error);

        let pa1dAddress = generateExpectedAddress({
            genesisAddress: GENESIS.address,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: PA1D.artifact.bin
        })

        if (!pa1dDeploymentResult.status) {
            throwError (JSON.stringify (pa1dDeploymentResult, null, 4));
        }
        if ('0x' + PA1D.artifact['bin-runtime'] != await web3.eth.getCode (pa1dAddress)) {
            throwError ('Could not properly compute CREATE2 address for pa1dAddress');
        }
        saveContractResult(NETWORK, PA1D.name, pa1dAddress)

    process.exit ();
}

main ();
