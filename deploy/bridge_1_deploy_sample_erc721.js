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

// we expect a 32 * 8 array of booleans or 0-1 integers
const setEvents = function (events) {
    if (events.length < (32 * 8)) {
        let add = (32 * 8) - events.length;
        events = events.concat (Array.from (
            {
                length: add
            },
            function (_, i) {
                return false;
            }
        ));
    }
    let binary = '';
    for (let i = 0, l = (32 * 8); i < l; i++) {
        let e = events [i];
        if (!e && e != 1 && e != '1' && e != 'true') {
            binary = '0' + binary;
        } else {
            binary = '1' + binary;
        }
    }
    return '0x' + parseInt (binary, 2).toString (16).padStart (64, '0');
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

    const FACTORY2 = new web3_2.eth.Contract (
        HOLOGRAPH_BRIDGE_CONTRACT.abi.concat (HOLOGRAPH_FACTORY_CONTRACT.abi),
        HOLOGRAPH_BRIDGE_PROXY_ADDRESS
    );

    let config = [
        '0x0000000000000000000000000000000000486f6c6f6772617068455243373231', // bytes32 contractType
        // we config the holographId to be for network 1
        hexify ((network1.holographId).toString (16).padStart (8, '0'), true), // uint32 chainType
        // we use current timestamp to create a guaranteed unique config
        hexify (Date.now ().toString (16).padStart (64, '0'), true), // bytes32 salt
        hexify (SAMPLE_ERC721_CONTRACT.bin, true), // bytes byteCode
        web3_1.eth.abi.encodeParameters (
            ['string', 'string', 'uint16', 'uint256', 'bytes'],
            [
                'Multichain ERC721 collection', // string memory contractName
                'MULTI', // string memory contractSymbol
                hexify ((1000).toString (16).padStart (4, '0'), true), // uint16 contractBps
                setEvents ([
                    false, // empty
                    true, // event id = 1
                    true, // event id = 2
                    true, // event id = 3
                    true, // event id = 4
                    true, // event id = 5
                    true, // event id = 6
                    true, // event id = 7
                    true, // event id = 8
                    true, // event id = 9
                    true, // event id = 10
                    true, // event id = 11
                    true, // event id = 12
                    true, // event id = 13
                    true, // event id = 14
                    false // empty
                ]), // uint256 eventConfig
                web3_1.eth.abi.encodeParameters (
                    ['address'],
                    [provider1.addresses [0]]
                )
            ]
        ) // bytes initCode
    ];

    let hash = web3_1.utils.keccak256 (
        '0x' +
        removeX (config [0]) + // contractType
        removeX (config [1]) + // chainType
        removeX (config [2]) + // salt
        removeX (web3_1.utils.keccak256 (config [3])) + // byteCode
        removeX (web3_1.utils.keccak256 (config [4])) + // initCode
        removeX (provider1.addresses [0]) // signer
    );

    const SIGNATURE = await web3_1.eth.sign (hash, provider1.addresses [0]);
    let signature = [
        hexify (removeX (SIGNATURE).substring (0, 64), true),
        hexify (removeX (SIGNATURE).substring (64, 128), true),
        hexify (removeX (SIGNATURE).substring (128, 130), true)
    ];
    if (parseInt (signature [2], 16) < 27) {
        signature [2] = '0x' + (parseInt (signature [2], 16) + 27).toString (16);
    }
//     console.log (
//         config,
//         signature,
//         provider1.addresses [0]
//     );

    const deploySampleErc721Result = await FACTORY1.methods.deployIn (web3_1.eth.abi.encodeParameters (
        ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
        [config, signature, provider1.addresses [0]]
    )).send ({
        chainId: network1.chain,
        from: provider1.addresses [0],
        gas: web3_1.utils.toHex (7000000),
        gasPrice: web3_1.utils.toHex (web3_1.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!deploySampleErc721Result.status) {
        throwError (JSON.stringify (deploySampleErc721Result, null, 4));
    } else {
        let sampleErc721Address = deploySampleErc721Result.events.BridgeableContractDeployed.returnValues.contractAddress;
        fs.writeFileSync (
            './data/' + NETWORK + '.' + MULTICHAIN_ERC721 + '.address',
            sampleErc721Address
        );
        console.log ('Deployed', NETWORK, 'SampleERC721', sampleErc721Address);
    }

    const deploySampleErc721Result2 = await FACTORY2.methods.deployIn (web3_2.eth.abi.encodeParameters (
        ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
        [config, signature, provider1.addresses [0]]
    )).send ({
        chainId: network2.chain,
        from: provider2.addresses [0],
        gas: web3_2.utils.toHex (7000000),
        gasPrice: web3_2.utils.toHex (web3_2.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!deploySampleErc721Result2.status) {
        throwError (JSON.stringify (deploySampleErc721Result2, null, 4));
    } else {
        let sampleErc721Address2 = deploySampleErc721Result2.events.BridgeableContractDeployed.returnValues.contractAddress;
        fs.writeFileSync (
            './data/' + NETWORK2 + '.' + MULTICHAIN_ERC721 + '.address',
            sampleErc721Address2
        );
        console.log ('Deployed', NETWORK2, 'SampleERC721', sampleErc721Address2);
    }

    process.exit ();

}

main ();
