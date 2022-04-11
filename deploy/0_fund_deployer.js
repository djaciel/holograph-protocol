'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    WALLET,
    DEPLOYER
} = require ('../config/env');

const network = JSON.parse (fs.readFileSync ('./networks.json', 'utf8')) [NETWORK];
const provider = new HDWalletProvider (WALLET, network.rpc);
const web3 = new Web3 (provider);

const facadeProvider = new HDWalletProvider (DEPLOYER, network.rpc);

const ethAmount = '20';

web3.eth.sendTransaction (
    {
        chainId: network.chain,
        from: provider.addresses [0],
        to: facadeProvider.addresses [0],
        value: web3.utils.toWei (ethAmount, 'ether'),
    },
    function (error, result) {
        if (error) {
            console.log ('Could not fund ' + ethAmount + ' ETH to ' + facadeProvider.addresses [0], error);
            process.exit (1);
        }
        else {
            console.log ('Funded ' + ethAmount + ' ETH to ' + facadeProvider.addresses [0]);
            process.exit ();
        }
    }
);
