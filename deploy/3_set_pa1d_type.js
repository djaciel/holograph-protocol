'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');

const HOLOGRAPH_REGISTRY = 'HolographRegistry';
const HOLOGRAPH_REGISTRY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_REGISTRY + '.sol:' + HOLOGRAPH_REGISTRY];

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

const throwError = function (err) {
    process.stderr.write (err + '\n');
    process.exit (1);
};

const web3Error = function (err) {
    throwError (err.toString ())
};

async function main () {

    const HOLOGRAPH_REGISTRY_PROXY_ADDRESS = fs.readFileSync ('./data/' + NETWORK + '.' + HOLOGRAPH_REGISTRY_PROXY + '.address', 'utf8').trim ();

    const PA1D = 'PA1D';
    const PA1D_ADDRESS = fs.readFileSync ('./data/' + NETWORK + '.' + PA1D + '.address', 'utf8').trim ();

    const FACTORY = new web3.eth.Contract (
        HOLOGRAPH_REGISTRY_CONTRACT.abi,
        HOLOGRAPH_REGISTRY_PROXY_ADDRESS
    );

    const setContractTypeAddressResult2 = await FACTORY.methods.setContractTypeAddress('0x0000000000000000000000000000000000000000000000000000000050413144', PA1D_ADDRESS).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!setContractTypeAddressResult2.status) {
        throwError (JSON.stringify (setContractTypeAddressResult2, null, 4));
    } else {
        console.log ('Set PA1D address to address type 0x0000000000000000000000000000000000000000000000000000000050413144');
    }

    process.exit ();

}

main ();
