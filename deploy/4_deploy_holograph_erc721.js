'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {throwError, web3Error, getContractArtifact, createNetworkPropsForUser, saveContractResult,
    getContractAddress, createFactoryAtAddress, generateExpectedAddress
} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)
    const salt = '0x000000000000000000000000';

    const GENESIS = 'HolographGenesis';
    const GENESIS_ARTIFACT = getContractArtifact(GENESIS)
    const GENESIS_ADDRESS = getContractAddress(NETWORK, GENESIS)
    const GENESIS_FACTORY = createFactoryAtAddress(web3, GENESIS_ARTIFACT.abi, GENESIS_ADDRESS)

// HolographERC721
        const HOLOGRAPH_ERC721 = 'HolographERC721';
        const HOLOGRAPH_ERC721_CONTRACT = getContractArtifact(HOLOGRAPH_ERC721)
        const holographErc721DeploymentResult = await GENESIS_FACTORY.methods.deploy (
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

        // let holographErc721Address = '0x' + removeX (web3.utils.keccak256 (
        //     '0xff'
        //     + removeX (GENESIS_ADDRESS)
        //     + removeX (provider.addresses [0]) + removeX (salt)
        //     + removeX (web3.utils.keccak256 ('0x' + HOLOGRAPH_ERC721_CONTRACT.bin))
        // )).substring (24);

        let holographErc721Address = generateExpectedAddress({
            genesisAddress: GENESIS_ADDRESS,
            web3,
            senderAddress: provider.addresses[0],
            salt,
            contractByteCode: HOLOGRAPH_ERC721_CONTRACT.bin
        })


        if (!holographErc721DeploymentResult.status) {
            throwError (JSON.stringify (holographErc721DeploymentResult, null, 4));
        }
        if ('0x' + HOLOGRAPH_ERC721_CONTRACT ['bin-runtime'] != await web3.eth.getCode (holographErc721Address)) {
            throwError ('Could not properly compute CREATE2 address for holographErc721Address');
        }
        saveContractResult(NETWORK, HOLOGRAPH_ERC721, holographErc721Address)

    process.exit ();
}

main ();
