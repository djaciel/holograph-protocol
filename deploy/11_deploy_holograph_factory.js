'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const { NETWORK, GAS, WALLET } = require ('../config/env');

const network = JSON.parse (fs.readFileSync ('./networks.json', 'utf8')) [NETWORK];
const provider = new HDWalletProvider (WALLET, network.rpc);
const web3 = new Web3 (provider);

const error = function (err) {
    console.log (err);
    process.exit ();
};
const from = {
    chainId: network.chain,
    from: provider.addresses [0]
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
//     await web3.eth.getTransactionReceipt('0xc9a9a6dbe24b0e78c142a3c9f58e27c879cce330d33b9aa700223a27591a2cf2').then(console.log).catch(error);
//     await web3.eth.getTransactionReceipt('0xc9a9a6dbe24b0e78c142a3c9f58e27c879cce330d33b9aa700223a27591a2cf2').then(function (data) {
//         console.log (data);
//         console.log (data.events);
//     }).catch(error);
    const wallet = provider.addresses [0];

    const ABI = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['HolographGenesis.sol:HolographGenesis'].abi;
    const CONTRACT = fs.readFileSync ('./data/' + NETWORK + '.HolographGenesis.address', 'utf8').trim ();

    const FACTORY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['HolographFactory.sol:HolographFactory'];

    console.log ('CONTRACT', CONTRACT);

    const contract = new web3.eth.Contract (
        ABI,
        CONTRACT
    );

    console.log (await contract.methods.deploy('0x000000000000000000000000', hexify (FACTORY_CONTRACT.bin, true), provider.addresses [0]).send (from).catch (error));

//     console.log (
//         await contract.methods.mint ('Lorem ipsum doral').send ({
//             chainId: network.chain,
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
