'use strict';

const fs = require ('fs');
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

async function main (input) {
    const slot = '0x' + hexify (
        web3.utils.toHex (
            web3.utils.toBN (
                web3.utils.keccak256 (
                    input
                )
            ).sub (web3.utils.toBN (1))
        ),
        false
    ).padStart (64, '0');
//     console.log ('bytes32 slot = bytes32(uint256(keccak256(\'' + input + '\')) - 1);', '=', slot);
    console.log (input);
    console.log (slot);
    process.exit ();
}

main (process.argv [2]);
