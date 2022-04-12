'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');

const HOLOGRAPH_FACTORY = 'HolographFactory';
const HOLOGRAPH_FACTORY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [HOLOGRAPH_FACTORY + '.sol:' + HOLOGRAPH_FACTORY];

const HOLOGRAPH_FACTORY_PROXY = 'HolographFactoryProxy';
const HOLOGRAPH_FACTORY_PROXY_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts ['proxy/' + HOLOGRAPH_FACTORY_PROXY + '.sol:' + HOLOGRAPH_FACTORY_PROXY];

const SAMPLE_ERC721 = 'SampleERC721';
const SAMPLE_ERC721_CONTRACT = JSON.parse (fs.readFileSync ('./build/combined.json')).contracts [SAMPLE_ERC721 + '.sol:' + SAMPLE_ERC721];

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

    const HOLOGRAPH_FACTORY_PROXY_ADDRESS = fs.readFileSync ('./data/' + NETWORK + '.' + HOLOGRAPH_FACTORY_PROXY + '.address', 'utf8').trim ();

    const FACTORY = new web3.eth.Contract (
        HOLOGRAPH_FACTORY_CONTRACT.abi,
        HOLOGRAPH_FACTORY_PROXY_ADDRESS
    );

    let config = [
        '0x0000000000000000000000000000000000486f6c6f6772617068455243373231', // bytes32 contractType
        // WE MANUALLY SET THIS TO LOCAL NETWORK HOLOGRAPH ID
        // this is to see the differences in how tokens are managed between chains
        hexify ((4294967295).toString (16).padStart (8, '0'), true), // uint32 chainType
        '0x0000000000000000000000000000000000000000000000000000000000000000', // bytes32 salt
        hexify (SAMPLE_ERC721_CONTRACT.bin, true), // bytes byteCode
        web3.eth.abi.encodeParameters (
            ['string', 'string', 'uint16', 'uint256', 'bytes'],
            [
                'Sample ERC721 Contract', // string memory contractName
                'SMPLR', // string memory contractSymbol
                '0x03e8', // uint16 contractBps
                '0x0000000000000000000000000000000000000000000000000000000000000000', // uint256 eventConfig
                web3.eth.abi.encodeParameters (
                    ['address'],
                    [provider.addresses [0]]
                )
            ]
        ) // bytes initCode
    ];

    let hash = web3.utils.keccak256 (
        '0x' +
        removeX (config [0]) +
        removeX (config [1]) +
        removeX (config [2]) +
        removeX (web3.utils.keccak256 (config [3])) +
        removeX (web3.utils.keccak256 (config [4])) +
        removeX (provider.addresses [0])
    );

    const SIGNATURE = await web3.eth.sign (hash, provider.addresses [0]);
    let signature = [
        hexify (removeX (SIGNATURE).substring (0, 64), true),
        hexify (removeX (SIGNATURE).substring (64, 128), true),
        hexify (removeX (SIGNATURE).substring (128, 130), true)
    ];
    if (parseInt (signature [2], 16) < 27) {
        signature [2] = '0x' + (parseInt (signature [2], 16) + 27).toString (16);
    }
    console.log (
        config,
        signature,
        provider.addresses [0]
    );

    const deploySampleErc721Result = await FACTORY.methods.deployHolographableContract (config, signature, provider.addresses [0]).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (5000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!deploySampleErc721Result.status) {
        throwError (JSON.stringify (deploySampleErc721Result, null, 4));
    } else {
        let sampleErc721Address = deploySampleErc721Result.events.BridgeableContractDeployed.returnValues.contractAddress;
        fs.writeFileSync (
            './data/' + NETWORK + '.' + SAMPLE_ERC721 + '.address',
            sampleErc721Address
        );
        console.log ('Deployed SampleERC721', sampleErc721Address);
    }

    process.exit ();

}

main ();
