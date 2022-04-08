'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const { NETWORK, GAS, WALLET } = require ('../config/env');

const NAME = 'HolographBridgeRegistry';

const FACTORY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [NAME + '.sol:' + NAME];

const network = JSON.parse (fs.readFileSync ('./networks.json', 'utf8')) [NETWORK];
const provider = new HDWalletProvider (WALLET, network.rpc);
const web3 = new Web3 (provider);

let FACTORY = new web3.eth.Contract (FACTORY_CONTRACT.abi);
let BYTECODE = FACTORY_CONTRACT.bin;

// Function Call
FACTORY.deploy ({
    data: BYTECODE,
    arguments: []
}).send ({
    chainId: network.chain,
    from: provider.addresses [0],
    gas: web3.utils.toHex (600000),
    gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
}, function (err, transactionHash) {
    console.log ('Transaction Hash :', transactionHash);
})
.then (function (newContractInstance) {
    fs.writeFileSync (
        './data/' + NETWORK + '.' + NAME + '.address',
        newContractInstance.options.address
    );
    console.log ('Deployed ' + NAME + ' Contract : ' + newContractInstance.options.address);
    process.exit ();
});
