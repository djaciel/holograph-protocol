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

const HOLOGRAPH_FACTORY = 'HolographFactory';
const HOLOGRAPH_FACTORY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_FACTORY + '.sol:' + HOLOGRAPH_FACTORY];

const HOLOGRAPH_REGISTRY = 'HolographRegistry';
const HOLOGRAPH_REGISTRY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_REGISTRY + '.sol:' + HOLOGRAPH_REGISTRY];

const HOLOGRAPH_BRIDGE_PROXY = 'HolographBridgeProxy';
const HOLOGRAPH_BRIDGE_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + HOLOGRAPH_BRIDGE_PROXY + '.sol:' + HOLOGRAPH_BRIDGE_PROXY];

const HOLOGRAPH_FACTORY_PROXY = 'HolographFactoryProxy';
const HOLOGRAPH_FACTORY_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + HOLOGRAPH_FACTORY_PROXY + '.sol:' + HOLOGRAPH_FACTORY_PROXY];

const HOLOGRAPH_REGISTRY_PROXY = 'HolographRegistryProxy';
const HOLOGRAPH_REGISTRY_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + HOLOGRAPH_REGISTRY_PROXY + '.sol:' + HOLOGRAPH_REGISTRY_PROXY];

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
        '0x' // bytes memory initCode
    ).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    });
    let holographRegistryAddress = '0x' + removeX (web3.utils.keccak256 (
        '0xff'
        + removeX (GENESIS_ADDRESS)
        + removeX (provider.addresses [0]) + removeX (salt)
        + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_REGISTRY_CONTRACT.bin))
    )).substring (24);
    if (!holographRegistryDeploymentResult.status) {
        throw new Error (holographRegistryDeploymentResult, JSON.stringify (holographRegistryDeploymentResult, null, 4));
    }
    console.log ('holographRegistryAddress', holographRegistryAddress);

    // HolographRegistryProxy
    const holographRegistryProxyDeploymentResult = await FACTORY.methods.deploy (
        salt, // bytes12 saltHash
        '0x' + HOLOGRAPH_REGISTRY_PROXY_CONTRACT.bin, // bytes memory sourceCode
        web3.eth.abi.encodeParameters (
            ['address'],
            [holographRegistryAddress]
        ) // bytes memory initCode
    ).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    });
    let holographRegistryProxyAddress = '0x' + removeX (web3.utils.keccak256 (
        '0xff'
        + removeX (GENESIS_ADDRESS)
        + removeX (provider.addresses [0]) + removeX (salt)
        + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_REGISTRY_PROXY_CONTRACT.bin))
    )).substring (24);
    if (!holographRegistryProxyDeploymentResult.status) {
        throw new Error (holographRegistryProxyDeploymentResult, JSON.stringify (holographRegistryProxyDeploymentResult, null, 4));
    }
    console.log ('holographRegistryProxyAddress', holographRegistryProxyAddress);

    // HolographFactory
    const holographFactoryDeploymentResult = await FACTORY.methods.deploy (
        salt, // bytes12 saltHash
        '0x' + HOLOGRAPH_FACTORY_CONTRACT.bin, // bytes memory sourceCode
        web3.eth.abi.encodeParameters (
            ['address', 'address'],
            [holographRegistryProxyAddress, '0x0000000000000000000000000000000000000000']
        ) // bytes memory initCode
    ).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    });
    let holographFactoryAddress = '0x' + removeX (web3.utils.keccak256 (
        '0xff'
        + removeX (GENESIS_ADDRESS)
        + removeX (provider.addresses [0]) + removeX (salt)
        + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_FACTORY_CONTRACT.bin))
    )).substring (24);
    if (!holographFactoryDeploymentResult.status) {
        throw new Error (holographFactoryDeploymentResult, JSON.stringify (holographFactoryDeploymentResult, null, 4));
    }
    console.log ('holographFactoryAddress', holographFactoryAddress);

    // HolographFactoryProxy
    const holographFactoryProxyDeploymentResult = await FACTORY.methods.deploy (
        salt, // bytes12 saltHash
        '0x' + HOLOGRAPH_FACTORY_PROXY_CONTRACT.bin, // bytes memory sourceCode
        web3.eth.abi.encodeParameters (
            ['address'],
            [holographFactoryAddress]
        ) // bytes memory initCode
    ).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    });
    let holographFactoryProxyAddress = '0x' + removeX (web3.utils.keccak256 (
        '0xff'
        + removeX (GENESIS_ADDRESS)
        + removeX (provider.addresses [0]) + removeX (salt)
        + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_FACTORY_PROXY_CONTRACT.bin))
    )).substring (24);
    if (!holographFactoryProxyDeploymentResult.status) {
        throw new Error (holographFactoryProxyDeploymentResult, JSON.stringify (holographFactoryProxyDeploymentResult, null, 4));
    }
    console.log ('holographFactoryProxyAddress', holographFactoryProxyAddress);

    // HolographBridge
    const holographBridgeDeploymentResult = await FACTORY.methods.deploy (
        salt, // bytes12 saltHash
        '0x' + HOLOGRAPH_BRIDGE_CONTRACT.bin, // bytes memory sourceCode
        web3.eth.abi.encodeParameters (
            ['address', 'address'],
            [holographRegistryProxyAddress, holographFactoryProxyAddress]
        ) // bytes memory initCode
    ).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    });
    let holographBridgeAddress = '0x' + removeX (web3.utils.keccak256 (
        '0xff'
        + removeX (GENESIS_ADDRESS)
        + removeX (provider.addresses [0]) + removeX (salt)
        + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_BRIDGE_CONTRACT.bin))
    )).substring (24);
    if (!holographBridgeDeploymentResult.status) {
        throw new Error (holographBridgeDeploymentResult, JSON.stringify (holographBridgeDeploymentResult, null, 4));
    }
    console.log ('holographBridgeAddress', holographBridgeAddress);

    // HolographBridgeProxy
    const holographBridgeProxyDeploymentResult = await FACTORY.methods.deploy (
        salt, // bytes12 saltHash
        '0x' + HOLOGRAPH_BRIDGE_PROXY_CONTRACT.bin, // bytes memory sourceCode
        web3.eth.abi.encodeParameters (
            ['address'],
            [holographBridgeAddress]
        ) // bytes memory initCode
    ).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    });
    let holographBridgeProxyAddress = '0x' + removeX (web3.utils.keccak256 (
        '0xff'
        + removeX (GENESIS_ADDRESS)
        + removeX (provider.addresses [0]) + removeX (salt)
        + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_BRIDGE_PROXY_CONTRACT.bin))
    )).substring (24);
    if (!holographBridgeProxyDeploymentResult.status) {
        throw new Error (holographBridgeProxyDeploymentResult, JSON.stringify (holographBridgeProxyDeploymentResult, null, 4));
    }
    console.log ('holographBridgeProxyAddress', holographBridgeProxyAddress);

    // Holograph
    const holographDeploymentResult = await FACTORY.methods.deploy (
        salt, // bytes12 saltHash
        '0x' + HOLOGRAPH_CONTRACT.bin, // bytes memory sourceCode
        web3.eth.abi.encodeParameters (
            ['uint32', 'address', 'address', 'address'],
            ['0x00000000', holographRegistryProxyAddress, holographFactoryProxyAddress, holographBridgeProxyAddress]
        ) // bytes memory initCode
    ).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    });
    let holographAddress = '0x' + removeX (web3.utils.keccak256 (
        '0xff'
        + removeX (GENESIS_ADDRESS)
        + removeX (provider.addresses [0]) + removeX (salt)
        + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_CONTRACT.bin))
    )).substring (24);
    if (!holographDeploymentResult.status) {
        throw new Error (holographDeploymentResult, JSON.stringify (holographDeploymentResult, null, 4));
    }
    console.log ('holographAddress', holographAddress);

    process.exit ();
}

main ();
