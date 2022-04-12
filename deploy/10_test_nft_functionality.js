'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    WALLET1,
    WALLET2,
} = require ('../config/env');


const SAMPLE_ERC721 = 'SampleERC721';
const SAMPLE_ERC721_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [SAMPLE_ERC721 + '.sol:' + SAMPLE_ERC721];

const HOLOGRAPH_ERC721 = 'HolographERC721';
const HOLOGRAPH_ERC721_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_ERC721 + '.sol:' + HOLOGRAPH_ERC721];

const HOLOGRAPHER = 'Holographer';
const HOLOGRAPHER_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPHER + '.sol:' + HOLOGRAPHER];

const network = JSON.parse (fs.readFileSync ('./networks.json', 'utf8')) [NETWORK];
const provider = new HDWalletProvider ([WALLET1, WALLET2], network.rpc, 0, 2);
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

    const ERC721_ADDRESS = fs.readFileSync ('./data/' + NETWORK + '.' + SAMPLE_ERC721 + '.address', 'utf8').trim ();

    const FACTORY = new web3.eth.Contract (
        SAMPLE_ERC721_CONTRACT.abi.concat (HOLOGRAPHER_CONTRACT.abi).concat (HOLOGRAPH_ERC721_CONTRACT.abi),
        ERC721_ADDRESS
    );

    let tokenId = NETWORK == 'local' ? 1 : '0xFFFFFFFE00000000000000000000000000000000000000000000000000000001';

    console.log ("\n");

    console.log ('ownerOf', await FACTORY.methods.ownerOf (tokenId).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    const transferResult = await FACTORY.methods.transferFrom (provider.addresses [0], provider.addresses [1], tokenId).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!transferResult.status) {
        throwError (JSON.stringify (transferResult, null, 4));
    }
    console.log (
        "\n" + 'Token id',
        transferResult.events.Transfer.returnValues._tokenId,
        'transfered from',
        transferResult.events.Transfer.returnValues._from,
        'to',
        transferResult.events.Transfer.returnValues._to,
        "\n"
    );

    console.log ('ownerOf', await FACTORY.methods.ownerOf (tokenId).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    const transferBackResult = await FACTORY.methods.transferFrom (provider.addresses [1], provider.addresses [0], tokenId).send ({
        chainId: network.chain,
        from: provider.addresses [1],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!transferBackResult.status) {
        throwError (JSON.stringify (transferBackResult, null, 4));
    }
    console.log (
        "\n" + 'Token id',
        transferBackResult.events.Transfer.returnValues._tokenId,
        'transfered from',
        transferBackResult.events.Transfer.returnValues._from,
        'to',
        transferBackResult.events.Transfer.returnValues._to,
        "\n"
    );

    console.log ("\n");

    process.exit ();

}

main ();
