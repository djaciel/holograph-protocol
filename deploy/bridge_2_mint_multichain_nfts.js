'use strict';
const {
    NETWORK,
    NETWORK2,
    GAS,
    WALLET1,
    WALLET2
} = require ('../config/env');
const {web3Error, hexify, throwError, getContractAddress, getContractArtifact,
    createCombinedFactoryAtAddress, createNetworkPropsForUser
} = require("./helpers/utils");

async function main () {
    const { network: network1, provider: provider1, web3: web3_1 } = createNetworkPropsForUser(WALLET1, NETWORK)
    const { network: network2, provider: provider2, web3: web3_2 } = createNetworkPropsForUser(WALLET2, NETWORK2)

    const SAMPLE_ERC721 = 'SampleERC721';
    const SAMPLE_ERC721_ARTIFACT = getContractArtifact(SAMPLE_ERC721)

    const MULTICHAIN_ERC721 = 'MultichainERC721';
    const MULTICHAIN_ERC721_ADDRESS = getContractAddress(NETWORK, MULTICHAIN_ERC721)

    const HOLOGRAPH_ERC721 = 'HolographERC721';
    const HOLOGRAPH_ERC721_CONTRACT = getContractArtifact(HOLOGRAPH_ERC721)

    const ERC721_1 = createCombinedFactoryAtAddress(web3_1, [HOLOGRAPH_ERC721_CONTRACT, SAMPLE_ERC721_ARTIFACT], MULTICHAIN_ERC721_ADDRESS)
    const ERC721_2 = createCombinedFactoryAtAddress(web3_2, [HOLOGRAPH_ERC721_CONTRACT, SAMPLE_ERC721_ARTIFACT], MULTICHAIN_ERC721_ADDRESS)

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

    process.exit ();

}

main ();
