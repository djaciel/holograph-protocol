'use strict';
const {
    NETWORK,
    NETWORK2,
    GAS,
    WALLET1,
    WALLET2,
    DEPLOYER
} = require ('../config/env');
const {hexify, removeX, throwError, web3Error, setEvents, getContractArtifact, getContractAddress,
    createFactoryAtAddress, createCombinedFactoryAtAddress, createNetworkPropsForUser, saveContractResult
} = require("./helpers/utils");

async function main () {
    const { network: network1, provider: provider1, web3: web3_1 } = createNetworkPropsForUser([WALLET1, DEPLOYER], NETWORK)
    const { network: network2, provider: provider2, web3: web3_2 } = createNetworkPropsForUser([WALLET2, DEPLOYER], NETWORK2)

    const HOLOGRAPH = 'Holograph';
    const HOLOGRAPH_ARTIFACT = getContractArtifact(HOLOGRAPH)
    const HOLOGRAPH_ADDRESS = getContractAddress(NETWORK, HOLOGRAPH)
    const HOLOGRAPH_FACTORY_WEB3_1 = createFactoryAtAddress(web3_1, HOLOGRAPH_ARTIFACT.abi, HOLOGRAPH_ADDRESS)

    const HOLOGRAPH_BRIDGE_PROXY_ADDRESS = await (HOLOGRAPH_FACTORY_WEB3_1).methods.getBridge().call ({
        chainId: network1.chain,
        from: provider1.addresses [0],
        gas: web3_1.utils.toHex (5000000),
        gasPrice: web3_1.utils.toHex (web3_1.utils.toWei (GAS, 'gwei'))
    }).catch(web3Error);

    const HOLOGRAPH_BRIDGE = 'HolographBridge';
    const HOLOGRAPH_BRIDGE_ARTIFACT = getContractArtifact(HOLOGRAPH_BRIDGE)

    const HOLOGRAPH_FACTORY = 'HolographFactory';
    const HOLOGRAPH_FACTORY_ARTIFACT = getContractArtifact(HOLOGRAPH_FACTORY)

    //NOTE HOLOGRAPH_BRIDGE_PROXY_ADDRESS has been deployed to both chains already
    const FACTORY1 = createCombinedFactoryAtAddress(web3_1, [HOLOGRAPH_BRIDGE_ARTIFACT, HOLOGRAPH_FACTORY_ARTIFACT], HOLOGRAPH_BRIDGE_PROXY_ADDRESS)
    const FACTORY2 = createCombinedFactoryAtAddress(web3_2, [HOLOGRAPH_BRIDGE_ARTIFACT, HOLOGRAPH_FACTORY_ARTIFACT], HOLOGRAPH_BRIDGE_PROXY_ADDRESS)

    const MULTICHAIN_ERC721 = 'MultichainERC721';
    const SAMPLE_ERC721 = 'token/SampleERC721';
    const SAMPLE_ERC721_ARTIFACT = getContractArtifact(SAMPLE_ERC721)

    let config = [
        '0x0000000000000000000000000000000000486f6c6f6772617068455243373231', // bytes32 contractType
        // we config the holographId to be for network 1
        hexify ((network1.holographId).toString (16).padStart (8, '0'), true), // uint32 chainType
        // we use current timestamp to create a guaranteed unique config
        hexify (Date.now ().toString (16).padStart (64, '0'), true), // bytes32 salt
        hexify (SAMPLE_ERC721_ARTIFACT.bin, true), // bytes byteCode
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
                    [provider1.addresses [1]]
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

        saveContractResult(NETWORK, MULTICHAIN_ERC721, sampleErc721Address)
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
        saveContractResult(NETWORK2, MULTICHAIN_ERC721, sampleErc721Address2)

    }

    process.exit ();

}

main ();
