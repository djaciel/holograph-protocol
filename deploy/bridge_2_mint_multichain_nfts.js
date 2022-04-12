'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    NETWORK2,
    GAS,
    WALLET1,
    WALLET2
} = require ('../config/env');

const HOLOGRAPH = 'Holograph';
const HOLOGRAPH_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH + '.sol:' + HOLOGRAPH];

const HOLOGRAPH_BRIDGE = 'HolographBridge';
const HOLOGRAPH_BRIDGE_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_BRIDGE + '.sol:' + HOLOGRAPH_BRIDGE];

const HOLOGRAPH_FACTORY = 'HolographFactory';
const HOLOGRAPH_FACTORY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_FACTORY + '.sol:' + HOLOGRAPH_FACTORY];

const HOLOGRAPH_BRIDGE_PROXY = 'HolographBridgeProxy';
const HOLOGRAPH_BRIDGE_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + HOLOGRAPH_BRIDGE_PROXY + '.sol:' + HOLOGRAPH_BRIDGE_PROXY];

const SAMPLE_ERC721 = 'SampleERC721';
const SAMPLE_ERC721_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [SAMPLE_ERC721 + '.sol:' + SAMPLE_ERC721];

const MULTICHAIN_ERC721 = 'MultichainERC721';

const MULTICHAIN_ERC721_ADDRESS = fs.readFileSync ('./data/' + NETWORK + '.' + MULTICHAIN_ERC721 + '.address', 'utf8').trim ();

const HOLOGRAPH_ERC721 = 'HolographERC721';
const HOLOGRAPH_ERC721_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_ERC721 + '.sol:' + HOLOGRAPH_ERC721];

const network1 = JSON.parse (fs.readFileSync ('./networks.json', 'utf8')) [NETWORK];
const network2 = JSON.parse (fs.readFileSync ('./networks.json', 'utf8')) [NETWORK2];
const provider1 = new HDWalletProvider (WALLET1, network1.rpc);
const provider2 = new HDWalletProvider (WALLET2, network2.rpc);
const web3_1 = new Web3 (provider1);
const web3_2 = new Web3 (provider2);

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

    const HOLOGRAPH_BRIDGE_PROXY_ADDRESS = await (new web3_1.eth.Contract (
        HOLOGRAPH_CONTRACT.abi,
        fs.readFileSync ('./data/' + NETWORK + '.' + HOLOGRAPH + '.address', 'utf8').trim ()
    )).methods.getBridge ().call ({
        chainId: network1.chain,
        from: provider1.addresses [0],
        gas: web3_1.utils.toHex (5000000),
        gasPrice: web3_1.utils.toHex (web3_1.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);

    const FACTORY1 = new web3_1.eth.Contract (
        HOLOGRAPH_BRIDGE_CONTRACT.abi.concat (HOLOGRAPH_FACTORY_CONTRACT.abi),
        HOLOGRAPH_BRIDGE_PROXY_ADDRESS
    );

    const ERC721_1 = new web3_1.eth.Contract (
        HOLOGRAPH_ERC721_CONTRACT.abi.concat (SAMPLE_ERC721_CONTRACT.abi),
        MULTICHAIN_ERC721_ADDRESS
    );

    const FACTORY2 = new web3_2.eth.Contract (
        HOLOGRAPH_BRIDGE_CONTRACT.abi.concat (HOLOGRAPH_FACTORY_CONTRACT.abi),
        HOLOGRAPH_BRIDGE_PROXY_ADDRESS
    );

    const ERC721_2 = new web3_2.eth.Contract (
        HOLOGRAPH_ERC721_CONTRACT.abi.concat (SAMPLE_ERC721_CONTRACT.abi),
        MULTICHAIN_ERC721_ADDRESS
    );

//     let tokenId = NETWORK == 'local' ? 1 : '0xFFFFFFFE00000000000000000000000000000000000000000000000000000001';
    const mintResult = await ERC721_1.methods.mint (provider1.addresses [0], 'https://' + NETWORK + '.network/sampleNFT.jpg').send ({
        chainId: network1.chain,
        from: provider1.addresses [0],
        gas: web3_1.utils.toHex (1000000),
        gasPrice: web3_1.utils.toHex (web3_1.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!mintResult.status) {
        throwError (JSON.stringify (mintResult, null, 4));
    }
    const tokenId = hexify (hexify (web3_1.utils.numberToHex (web3_1.utils.toBN (mintResult.events.Transfer.returnValues._tokenId))).padStart (64, '0'), true);
    console.log ('Token id', tokenId, 'minted on', NETWORK);

    const mintResult2 = await ERC721_2.methods.mint (provider2.addresses [0], 'https://' + NETWORK2 + '.network/sampleNFT.jpg').send ({
        chainId: network2.chain,
        from: provider2.addresses [0],
        gas: web3_2.utils.toHex (1000000),
        gasPrice: web3_2.utils.toHex (web3_2.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!mintResult2.status) {
        throwError (JSON.stringify (mintResult2, null, 4));
    }
    const tokenId2 = hexify (hexify (web3_2.utils.numberToHex (web3_2.utils.toBN (mintResult2.events.Transfer.returnValues._tokenId))).padStart (64, '0'), true);
    console.log ('Token id', tokenId2, 'minted on', NETWORK2);

//     const deploySampleErc721Result = await FACTORY1.methods.deployIn (web3_1.eth.abi.encodeParameters (
//         ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
//         [config, signature, provider1.addresses [0]]
//     )).send ({
//         chainId: network1.chain,
//         from: provider1.addresses [0],
//         gas: web3_1.utils.toHex (7000000),
//         gasPrice: web3_1.utils.toHex (web3_1.utils.toWei (GAS, 'gwei'))
//     }).catch (web3Error);
//     if (!deploySampleErc721Result.status) {
//         throwError (JSON.stringify (deploySampleErc721Result, null, 4));
//     } else {
//         let sampleErc721Address = deploySampleErc721Result.events.BridgeableContractDeployed.returnValues.contractAddress;
//         fs.writeFileSync (
//             './data/' + NETWORK + '.' + MULTICHAIN_ERC721 + '.address',
//             sampleErc721Address
//         );
//         console.log ('Deployed', NETWORK, 'SampleERC721', sampleErc721Address);
//     }
//
//     const deploySampleErc721Result2 = await FACTORY2.methods.deployIn (web3_2.eth.abi.encodeParameters (
//         ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
//         [config, signature, provider1.addresses [0]]
//     )).send ({
//         chainId: network2.chain,
//         from: provider2.addresses [0],
//         gas: web3_2.utils.toHex (7000000),
//         gasPrice: web3_2.utils.toHex (web3_2.utils.toWei (GAS, 'gwei'))
//     }).catch (web3Error);
//     if (!deploySampleErc721Result2.status) {
//         throwError (JSON.stringify (deploySampleErc721Result2, null, 4));
//     } else {
//         let sampleErc721Address2 = deploySampleErc721Result2.events.BridgeableContractDeployed.returnValues.contractAddress;
//         fs.writeFileSync (
//             './data/' + NETWORK2 + '.' + MULTICHAIN_ERC721 + '.address',
//             sampleErc721Address2
//         );
//         console.log ('Deployed', NETWORK2, 'SampleERC721', sampleErc721Address2);
//     }

    process.exit ();

}

main ();
