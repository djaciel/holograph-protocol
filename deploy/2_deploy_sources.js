'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {hexify, throwError, web3Error, getContractArtifact, createNetworkPropsForUser, saveContractResult,
     generateExpectedAddress, getContractAddress, createFactoryAtAddress
} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)
    const salt = '0x000000000000000000000000';

    const defaultTXOptions = {
        chainId: network.chain,
        from: provider.addresses[0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }

    const GENESIS = 'HolographGenesis';
    const GENESIS_ARTIFACT = getContractArtifact(GENESIS)
    const GENESIS_ADDRESS = getContractAddress(NETWORK, GENESIS)
    const GENESIS_FACTORY = createFactoryAtAddress(web3, GENESIS_ARTIFACT.abi, GENESIS_ADDRESS)

// HolographRegistry
        const HOLOGRAPH_REGISTRY = 'HolographRegistry';
        const HOLOGRAPH_REGISTRY_ARTIFACT = getContractArtifact(HOLOGRAPH_REGISTRY)

        const holographRegistryDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_REGISTRY_ARTIFACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['bytes32[]'],
                [[]]
            ) // bytes memory initCode
        ).send (defaultTXOptions).catch(web3Error);

        let holographRegistryAddress = generateExpectedAddress({
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_REGISTRY_ARTIFACT.bin
        })

        if (!holographRegistryDeploymentResult.status) {
            throwError (JSON.stringify (holographRegistryDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_REGISTRY_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (holographRegistryAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographRegistryAddress');
        }

        saveContractResult(NETWORK, HOLOGRAPH_REGISTRY, holographRegistryAddress)

// HolographRegistryProxy
        const HOLOGRAPH_REGISTRY_PROXY = 'HolographRegistryProxy';
        const HOLOGRAPH_REGISTRY_PROXY_ARTIFACT = getContractArtifact(HOLOGRAPH_REGISTRY_PROXY)

        const holographRegistryProxyDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_REGISTRY_PROXY_ARTIFACT.bin, // bytes memory sourceCode
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
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_REGISTRY_PROXY_ARTIFACT.bin
        })

        if (!holographRegistryProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographRegistryProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_REGISTRY_PROXY_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (holographRegistryProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographRegistryProxyAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_REGISTRY_PROXY, holographRegistryProxyAddress)

// HolographFactory
        const HOLOGRAPH_FACTORY = 'HolographFactory';
        const HOLOGRAPH_FACTORY_ARTIFACT = getContractArtifact(HOLOGRAPH_FACTORY)
        const holographFactoryDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_FACTORY_ARTIFACT.bin, // bytes memory sourceCode
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
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_FACTORY_ARTIFACT.bin
        })

        if (!holographFactoryDeploymentResult.status) {
            throwError (JSON.stringify (holographFactoryDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_FACTORY_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (holographFactoryAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographFactoryAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_FACTORY, holographFactoryAddress)

// SecureStorage
        const SECURE_STORAGE = 'SecureStorage';
        const SECURE_STORAGE_ARTIFACT = getContractArtifact(SECURE_STORAGE)
        const secureStorageDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + SECURE_STORAGE_ARTIFACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address'],
                ['0x0000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send (defaultTXOptions).catch(web3Error);

        let secureStorageAddress = generateExpectedAddress({
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: SECURE_STORAGE_ARTIFACT.bin
        })

        if (!secureStorageDeploymentResult.status) {
            throwError (JSON.stringify (secureStorageDeploymentResult, null, 4));
        }
        if ('0x' + SECURE_STORAGE_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (secureStorageAddress)) {
            throwError ('Could not properly compute CREATE2 address for secureStorageAddress');
        }
        saveContractResult(NETWORK, SECURE_STORAGE, secureStorageAddress)

// SecureStorageProxy
        const SECURE_STORAGE_PROXY = 'SecureStorageProxy';
        const SECURE_STORAGE_PROXY_ARTIFACT = getContractArtifact(SECURE_STORAGE_PROXY)
        const secureStorageProxyDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + SECURE_STORAGE_PROXY_ARTIFACT.bin, // bytes memory sourceCode
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
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: SECURE_STORAGE_PROXY_ARTIFACT.bin
        })


        if (!secureStorageProxyDeploymentResult.status) {
            throwError (JSON.stringify (secureStorageProxyDeploymentResult, null, 4));
        }
        if ('0x' + SECURE_STORAGE_PROXY_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (secureStorageProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for secureStorageProxyAddress');
        }
        saveContractResult(NETWORK, SECURE_STORAGE_PROXY, secureStorageProxyAddress)

// HolographFactoryProxy
        const HOLOGRAPH_FACTORY_PROXY = 'HolographFactoryProxy';
        const HOLOGRAPH_FACTORY_PROXY_ARTIFACT = getContractArtifact(HOLOGRAPH_FACTORY_PROXY)
        const holographFactoryProxyDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_FACTORY_PROXY_ARTIFACT.bin, // bytes memory sourceCode
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
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_FACTORY_PROXY_ARTIFACT.bin
        })

        if (!holographFactoryProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographFactoryProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_FACTORY_PROXY_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (holographFactoryProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographFactoryProxyAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_FACTORY_PROXY, holographFactoryProxyAddress)

// HolographBridge
        const HOLOGRAPH_BRIDGE = 'HolographBridge';
        const HOLOGRAPH_BRIDGE_ARTIFACT = getContractArtifact(HOLOGRAPH_BRIDGE)
        const holographBridgeDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_BRIDGE_ARTIFACT.bin, // bytes memory sourceCode
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
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_BRIDGE_ARTIFACT.bin
        })

        if (!holographBridgeDeploymentResult.status) {
            throwError (JSON.stringify (holographBridgeDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_BRIDGE_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (holographBridgeAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographBridgeAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_BRIDGE, holographBridgeAddress)

// HolographBridgeProxy
        const HOLOGRAPH_BRIDGE_PROXY = 'HolographBridgeProxy';
        const HOLOGRAPH_BRIDGE_PROXY_ARTIFACT = getContractArtifact(HOLOGRAPH_BRIDGE_PROXY)
        const holographBridgeProxyDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_BRIDGE_PROXY_ARTIFACT.bin, // bytes memory sourceCode
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
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_BRIDGE_PROXY_ARTIFACT.bin
        })

        if (!holographBridgeProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographBridgeProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_BRIDGE_PROXY_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (holographBridgeProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographBridgeProxyAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH_BRIDGE_PROXY, holographBridgeProxyAddress)

// Holograph
        const HOLOGRAPH = 'Holograph';
        const HOLOGRAPH_ARTIFACT = getContractArtifact(HOLOGRAPH)
        const holographDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_ARTIFACT.bin, // bytes memory sourceCode
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
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_ARTIFACT.bin
        })
        if (!holographDeploymentResult.status) {
            throwError (JSON.stringify (holographDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (holographAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographAddress');
        }
        saveContractResult(NETWORK, HOLOGRAPH, holographAddress)

// PA1D
        const PA1D = 'PA1D';
        const PA1D_ARTIFACT = getContractArtifact(PA1D)
        const pa1dDeploymentResult = await GENESIS_FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + PA1D_ARTIFACT.bin, // bytes memory sourceCode
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
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: PA1D_ARTIFACT.bin
        })

        if (!pa1dDeploymentResult.status) {
            throwError (JSON.stringify (pa1dDeploymentResult, null, 4));
        }
        if ('0x' + PA1D_ARTIFACT ['bin-runtime'] != await web3.eth.getCode (pa1dAddress)) {
            throwError ('Could not properly compute CREATE2 address for pa1dAddress');
        }
        saveContractResult(NETWORK, PA1D, pa1dAddress)

    process.exit ();
}

main ();
