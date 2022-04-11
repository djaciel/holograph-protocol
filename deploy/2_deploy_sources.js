'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');

const GENESIS = 'HolographGenesis';
const GENESIS_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [GENESIS + '.sol:' + GENESIS];

const HOLOGRAPH = 'Holograph';
const HOLOGRAPH_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH + '.sol:' + HOLOGRAPH];

const HOLOGRAPH_BRIDGE = 'HolographBridge';
const HOLOGRAPH_BRIDGE_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_BRIDGE + '.sol:' + HOLOGRAPH_BRIDGE];

const HOLOGRAPH_BRIDGE_PROXY = 'HolographBridgeProxy';
const HOLOGRAPH_BRIDGE_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + HOLOGRAPH_BRIDGE_PROXY + '.sol:' + HOLOGRAPH_BRIDGE_PROXY];

const HOLOGRAPH_FACTORY = 'HolographFactory';
const HOLOGRAPH_FACTORY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_FACTORY + '.sol:' + HOLOGRAPH_FACTORY];

const HOLOGRAPH_FACTORY_PROXY = 'HolographFactoryProxy';
const HOLOGRAPH_FACTORY_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + HOLOGRAPH_FACTORY_PROXY + '.sol:' + HOLOGRAPH_FACTORY_PROXY];

const HOLOGRAPH_REGISTRY = 'HolographRegistry';
const HOLOGRAPH_REGISTRY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_REGISTRY + '.sol:' + HOLOGRAPH_REGISTRY];

const HOLOGRAPH_REGISTRY_PROXY = 'HolographRegistryProxy';
const HOLOGRAPH_REGISTRY_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + HOLOGRAPH_REGISTRY_PROXY + '.sol:' + HOLOGRAPH_REGISTRY_PROXY];

const PA1D = 'PA1D';
const PA1D_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [PA1D + '.sol:' + PA1D];

const SECURE_STORAGE = 'SecureStorage';
const SECURE_STORAGE_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [SECURE_STORAGE + '.sol:' + SECURE_STORAGE];

const SECURE_STORAGE_PROXY = 'SecureStorageProxy';
const SECURE_STORAGE_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + SECURE_STORAGE_PROXY + '.sol:' + SECURE_STORAGE_PROXY];

const network = JSON.parse (fs.readFileSync ('./networks.json', 'utf8')) [NETWORK];
const provider = new HDWalletProvider (DEPLOYER, network.rpc);
const web3 = new Web3 (provider);

const removeX = function (input) {
    if (input.startsWith ('0x')) {
        return input.substring (2);
    } else {
        return input;
    }
};

const hexify = function (input, prepend) {
	input = input.toLowerCase ().trim ();
	if (input.startsWith ('0x')) {
		input = input.substring (2);
	}
	input = input.replace (/[^0-9a-f]/g, '');
	if (prepend) {
	    input = '0x' + input;
	}
	return input;
};

const throwError = function (err) {
    process.stderr.write (err + '\n');
    process.exit (1);
};

const web3Error = function (err) {
    throwError (err.toString ())
};

async function main () {

    const GENESIS_ADDRESS = fs.readFileSync ('./data/' + NETWORK + '.' + GENESIS + '.address', 'utf8').trim ();

    const FACTORY = new web3.eth.Contract (
        GENESIS_CONTRACT.abi,
        GENESIS_ADDRESS
    );

    const salt = '0x000000000000000000000000';

// HolographRegistry
        const holographRegistryDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_REGISTRY_CONTRACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['bytes32[]'],
                [[]]
            ) // bytes memory initCode
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (1000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let holographRegistryAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_REGISTRY_CONTRACT.bin))
        )).substring (24);
        if (!holographRegistryDeploymentResult.status) {
            throwError (JSON.stringify (holographRegistryDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_REGISTRY_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographRegistryAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographRegistryAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + HOLOGRAPH_REGISTRY + '.address',
            holographRegistryAddress
        );
        console.log ('holographRegistryAddress', holographRegistryAddress);

// HolographRegistryProxy
        const holographRegistryProxyDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_REGISTRY_PROXY_CONTRACT.bin, // bytes memory sourceCode
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
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (1000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let holographRegistryProxyAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_REGISTRY_PROXY_CONTRACT.bin))
        )).substring (24);
        if (!holographRegistryProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographRegistryProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_REGISTRY_PROXY_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographRegistryProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographRegistryProxyAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + HOLOGRAPH_REGISTRY_PROXY + '.address',
            holographRegistryProxyAddress
        );
        console.log ('holographRegistryProxyAddress', holographRegistryProxyAddress);

// HolographFactory
        const holographFactoryDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_FACTORY_CONTRACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'address'],
                ['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (3000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let holographFactoryAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_FACTORY_CONTRACT.bin))
        )).substring (24);
        if (!holographFactoryDeploymentResult.status) {
            throwError (JSON.stringify (holographFactoryDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_FACTORY_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographFactoryAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographFactoryAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + HOLOGRAPH_FACTORY + '.address',
            holographFactoryAddress
        );
        console.log ('holographFactoryAddress', holographFactoryAddress);

// SecureStorage
        const secureStorageDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + SECURE_STORAGE_CONTRACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address'],
                ['0x0000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (1000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let secureStorageAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + SECURE_STORAGE_CONTRACT.bin))
        )).substring (24);
        if (!secureStorageDeploymentResult.status) {
            throwError (JSON.stringify (secureStorageDeploymentResult, null, 4));
        }
        if ('0x' + SECURE_STORAGE_CONTRACT ['bin-runtime'] != await web3.eth.getCode (secureStorageAddress)) {
            throwError ('Could not properly compute CREATE2 address for secureStorageAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + SECURE_STORAGE + '.address',
            secureStorageAddress
        );
        console.log ('secureStorageAddress', secureStorageAddress);

// SecureStorageProxy
        const secureStorageProxyDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + SECURE_STORAGE_PROXY_CONTRACT.bin, // bytes memory sourceCode
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
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (1000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let secureStorageProxyAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + SECURE_STORAGE_PROXY_CONTRACT.bin))
        )).substring (24);
        if (!secureStorageProxyDeploymentResult.status) {
            throwError (JSON.stringify (secureStorageProxyDeploymentResult, null, 4));
        }
        if ('0x' + SECURE_STORAGE_PROXY_CONTRACT ['bin-runtime'] != await web3.eth.getCode (secureStorageProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for secureStorageProxyAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + SECURE_STORAGE_PROXY + '.address',
            secureStorageProxyAddress
        );
        console.log ('secureStorageProxyAddress', secureStorageProxyAddress);

// HolographFactoryProxy
        const holographFactoryProxyDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_FACTORY_PROXY_CONTRACT.bin, // bytes memory sourceCode
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
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (1000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let holographFactoryProxyAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_FACTORY_PROXY_CONTRACT.bin))
        )).substring (24);
        if (!holographFactoryProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographFactoryProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_FACTORY_PROXY_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographFactoryProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographFactoryProxyAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + HOLOGRAPH_FACTORY_PROXY + '.address',
            holographFactoryProxyAddress
        );
        console.log ('holographFactoryProxyAddress', holographFactoryProxyAddress);

// HolographBridge
        const holographBridgeDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_BRIDGE_CONTRACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'address'],
                ['0x0000000000000000000000000000000000000000', '0x0000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (1000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let holographBridgeAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_BRIDGE_CONTRACT.bin))
        )).substring (24);
        if (!holographBridgeDeploymentResult.status) {
            throwError (JSON.stringify (holographBridgeDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_BRIDGE_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographBridgeAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographBridgeAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + HOLOGRAPH_BRIDGE + '.address',
            holographBridgeAddress
        );
        console.log ('holographBridgeAddress', holographBridgeAddress);

// HolographBridgeProxy
        const holographBridgeProxyDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_BRIDGE_PROXY_CONTRACT.bin, // bytes memory sourceCode
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
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (1000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let holographBridgeProxyAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_BRIDGE_PROXY_CONTRACT.bin))
        )).substring (24);
        if (!holographBridgeProxyDeploymentResult.status) {
            throwError (JSON.stringify (holographBridgeProxyDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_BRIDGE_PROXY_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographBridgeProxyAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographBridgeProxyAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + HOLOGRAPH_BRIDGE_PROXY + '.address',
            holographBridgeProxyAddress
        );
        console.log ('holographBridgeProxyAddress', holographBridgeProxyAddress);

// Holograph
        const holographDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_CONTRACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['uint32', 'address', 'address', 'address', 'address'],
                ['0x00000000', holographRegistryProxyAddress, holographFactoryProxyAddress, holographBridgeProxyAddress, secureStorageProxyAddress]
            ) // bytes memory initCode
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (1000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let holographAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_CONTRACT.bin))
        )).substring (24);
        if (!holographDeploymentResult.status) {
            throwError (JSON.stringify (holographDeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographAddress)) {
            throwError ('Could not properly compute CREATE2 address for holographAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + HOLOGRAPH + '.address',
            holographAddress
        );
        console.log ('holographAddress', holographAddress);

// PA1D
        const pa1dDeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + PA1D_CONTRACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['address', 'uint256'],
                [provider.addresses [0], '0x0000000000000000000000000000000000000000000000000000000000000000']
            ) // bytes memory initCode
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (5000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let pa1dAddress = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + PA1D_CONTRACT.bin))
        )).substring (24);
        if (!pa1dDeploymentResult.status) {
            throwError (JSON.stringify (pa1dDeploymentResult, null, 4));
        }
        if ('0x' + PA1D_CONTRACT ['bin-runtime'] != await web3.eth.getCode (pa1dAddress)) {
            throwError ('Could not properly compute CREATE2 address for pa1dAddress');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + PA1D + '.address',
            pa1dAddress
        );
        console.log ('pa1dAddress', pa1dAddress);

    process.exit ();
}

main ();
