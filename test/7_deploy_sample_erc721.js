'use strict';
const fs = require ('fs');
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {removeX, hexify, throwError, web3Error, getContractArtifact, createNetworkPropsForUser, saveContractResult,
    getContractAddress, createFactoryAtAddress
} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)

    const SAMPLE_ERC721 = 'token/SampleERC721';
    const SAMPLE_ERC721_CONTRACT = getContractArtifact(SAMPLE_ERC721)

    const HOLOGRAPH_FACTORY = 'HolographFactory';
    const HOLOGRAPH_FACTORY_CONTRACT = getContractArtifact(HOLOGRAPH_FACTORY)

    const HOLOGRAPH_FACTORY_PROXY = 'proxy/HolographFactoryProxy';
    const HOLOGRAPH_FACTORY_PROXY_ADDRESS = getContractAddress(NETWORK, HOLOGRAPH_FACTORY_PROXY)
    const HOLOGRAPH_FACTORY_PROXY_FACTORY = createFactoryAtAddress(web3, HOLOGRAPH_FACTORY_CONTRACT.abi, HOLOGRAPH_FACTORY_PROXY_ADDRESS)

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

    const deploySampleErc721Result = await HOLOGRAPH_FACTORY_PROXY_FACTORY.methods.deployHolographableContract (config, signature, provider.addresses [0]).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (5000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!deploySampleErc721Result.status) {
        throwError (JSON.stringify (deploySampleErc721Result, null, 4));
    } else {
        let sampleErc721Address = deploySampleErc721Result.events.BridgeableContractDeployed.returnValues.contractAddress;
        saveContractResult(NETWORK, SAMPLE_ERC721, sampleErc721Address)
    }

    process.exit ();

}

main ();
