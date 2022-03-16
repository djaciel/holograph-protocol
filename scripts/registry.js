'use strict';

const fs = require ('fs');
const crypto = require ('crypto');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const web3 = new Web3 ();

const removeX = function (input) {
    if (input.startsWith ('0x')) {
        return input.substring (2);
    } else {
        return input;
    }
};

const hexify = function (input, prepend) {
	input = input.toLowerCase ().trim ();
	input = removeX (input);
	input = input.replace (/[^0-9a-f]/g, '');
	if (prepend) {
	    input = '0x' + input;
	}
	return input;
};

const sha256 = x => crypto.createHash('sha256').update(x, 'utf8').digest('hex');

async function main (input) {
    let registrySlot = hexify (
        sha256 (
            input
        ),
        true
    );
    console.log (input);
    console.log (registrySlot);
    process.exit ();
}

main (process.argv [2]);
