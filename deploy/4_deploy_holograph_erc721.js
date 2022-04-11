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

const HOLOGRAPH_ERC721 = 'HolographERC721';
const HOLOGRAPH_ERC721_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_ERC721 + '.sol:' + HOLOGRAPH_ERC721];

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
        const holographErc721DeploymentResult = await FACTORY.methods.deploy (
            salt, // bytes12 saltHash
            '0x' + HOLOGRAPH_ERC721_CONTRACT.bin, // bytes memory sourceCode
            web3.eth.abi.encodeParameters (
                ['string', 'string', 'uint16', 'uint256', 'bytes'],
                [
                    'Sample Collection', // contractName
                    'SAMPLE', // contractSymbol
                    1000, // contractBps == 10%
                    0, // eventConfig
                    '0x' // initCode
                ]
            ) // bytes memory initCode
        ).send ({
            chainId: network.chain,
            from: provider.addresses [0],
            gas: web3.utils.toHex (5000000),
            gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
        }).catch (web3Error);
        let holographErc721Address = '0x' + removeX (web3.utils.keccak256 (
            '0xff'
            + removeX (GENESIS_ADDRESS)
            + removeX (provider.addresses [0]) + removeX (salt)
            + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_ERC721_CONTRACT.bin))
        )).substring (24);
        if (!holographErc721DeploymentResult.status) {
            throwError (JSON.stringify (holographErc721DeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_ERC721_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographErc721Address)) {
            throwError ('Could not properly compute CREATE2 address for holographErc721Address');
        }
        fs.writeFileSync (
            './data/' + NETWORK + '.' + HOLOGRAPH_ERC721 + '.address',
            holographErc721Address
        );
        console.log ('holographErc721Address', holographErc721Address);

    process.exit ();
}

main ();
