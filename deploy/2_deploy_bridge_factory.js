'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const { NETWORK, GAS, WALLET } = require ('../config/env');

const FACTORY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['BridgeFactory.sol:BridgeFactory'];

const rpc = JSON.parse (fs.readFileSync ('./rpc.json', 'utf8'));
const provider = new HDWalletProvider (WALLET, rpc[NETWORK]);
const web3 = new Web3 (provider);

// Contract object and account info
let FACTORY = new web3.eth.Contract (FACTORY_CONTRACT.abi);

let bytecode = FACTORY_CONTRACT.bin;

// Function Parameter
let payload = {
    data: bytecode,
    arguments: []
};

let parameter = {
    from: provider.addresses [0],
    gas: web3.utils.toHex (6000000),
    gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
};

// Function Call
FACTORY.deploy (payload)
    .send (parameter, function (err, transactionHash) {
        console.log ('Transaction Hash :', transactionHash);
    })
    .then (function (newContractInstance) {
        fs.writeFileSync (
            './data/' + NETWORK + '.BridgeFactory.address',
            newContractInstance.options.address
        );
        console.log (
            'Deployed BridgeFactory Contract : ' + newContractInstance.options.address
        );
        newContractInstance.methods
            .setChainType (1)
            .send (parameter)
            .then (function () {
                console.log ('Chain Type set');
                newContractInstance.methods
                    .setBridgeRegistry (fs.readFileSync ('./data/' + NETWORK + '.BridgeRegistry.address', 'utf8').trim ())
                    .send (parameter)
                    .then (function () {
                        console.log ('Registry address set');
                        newContractInstance.methods
                            .setSecureStorage (fs.readFileSync ('./data/' + NETWORK + '.SecureStorage.address', 'utf8').trim ())
                            .send (parameter)
                            .then (function () {
                                console.log ('Secure Storage address set');
                                process.exit ();
                            })
                            .catch (console.error);
                    })
                    .catch (console.error);
            })
            .catch (console.error);
    });
