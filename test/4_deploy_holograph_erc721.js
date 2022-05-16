'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {throwError, web3Error, createNetworkPropsForUser, saveContractResult, generateExpectedAddress
} = require("./helpers/utils");
const {getGenesisContract, getHolographERC721Contract} = require("./helpers/contracts");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)
    const salt = '0x000000000000000000000000';

    const GENESIS = getGenesisContract(web3, NETWORK)

// HolographERC721
    const HOLOGRAPH_ERC721 = getHolographERC721Contract(web3, NETWORK)

    const holographErc721DeploymentResult = await GENESIS.contract.methods.deploy (
        salt, // bytes12 saltHash
        '0x' + HOLOGRAPH_ERC721.artifact.bin, // bytes memory sourceCode
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
        gas: web3.utils.toHex (6000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);


    let holographErc721Address = generateExpectedAddress({
        genesisAddress: GENESIS.address,
        web3,
        senderAddress: provider.addresses[0],
        salt,
        contractByteCode: HOLOGRAPH_ERC721.artifact.bin
    })

    if (!holographErc721DeploymentResult.status) {
        throwError (JSON.stringify (holographErc721DeploymentResult, null, 4));
    }
    if ('0x' + HOLOGRAPH_ERC721.artifact['bin-runtime'] != await web3.eth.getCode (holographErc721Address)) {
        throwError ('Could not properly compute CREATE2 address for holographErc721Address');
    }
    saveContractResult(NETWORK, HOLOGRAPH_ERC721.name, holographErc721Address)

    process.exit ();
}

main ();
