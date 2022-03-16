'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const { NETWORK, GAS, WALLET } = require ('../config/env');

const rpc = JSON.parse (fs.readFileSync ('./rpc.json', 'utf8'));
const provider = new HDWalletProvider (WALLET, rpc[NETWORK]);
const web3 = new Web3 (provider);

const error = function (err) {
    console.log (err);
    process.exit ();
};
const from = {
    from: provider.addresses [0],
};

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
    const wallet = provider.addresses [0];

    const ABI = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['BridgeFactory.sol:BridgeFactory'].abi;
    const CONTRACT = fs.readFileSync ('./data/' + NETWORK + '.BridgeFactory.address', 'utf8').trim ();

    console.log ('CONTRACT', CONTRACT);

    const contract = new web3.eth.Contract (
        ABI,
        CONTRACT
    );

    console.log ({
        chain: await contract.methods.getChainType ().call (from).catch (error),
        registry: await contract.methods.getRegistry ().call (from).catch (error),
        storage: await contract.methods.getSecureStorage ().call (from).catch (error)
    });

//     console.log (
//         await contract.methods.mint ('Lorem ipsum doral').send ({
//             from: provider.addresses[0],
//             value: web3.utils.toHex (web3.utils.toWei ('0.1', 'ether'))
//         }).catch (error)
//     );
//
//     console.log (
//         await contract.methods.tokensOfOwner (provider.addresses[0]).call (from).catch (error)
//     );
//
//     console.log (
//         await contract.methods.tokenURI (1).call (from).catch (error)
//     );

    process.exit ();
}

main ();
