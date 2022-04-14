'use strict';
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    WALLET1,
    WALLET2,
} = require ('../config/env');
const {throwError, web3Error, getContractArtifact, getNetworkInfo, getContractAddress} = require("./helpers/utils");

async function main () {
    const network = getNetworkInfo(NETWORK)
    const provider = new HDWalletProvider ([WALLET1, WALLET2], network.rpc, 0, 2);
    const web3 = new Web3 (provider);

    const SAMPLE_ERC721 = 'SampleERC721';
    const SAMPLE_ERC721_ARTIFACT = getContractArtifact(SAMPLE_ERC721)
    const SAMPLE_ERC721_ADDRESS = getContractAddress(NETWORK, SAMPLE_ERC721)

    const HOLOGRAPHER = 'Holographer';
    const HOLOGRAPHER_ARTIFACT = getContractArtifact(HOLOGRAPHER)

    const HOLOGRAPH_ERC721 = 'HolographERC721';
    const HOLOGRAPH_ERC721_ARTIFACT = getContractArtifact(HOLOGRAPH_ERC721)

    const HOLOGRAPH_ERC721_CONTRACT_FACTORY = new web3.eth.Contract (
        SAMPLE_ERC721_ARTIFACT.abi.concat (HOLOGRAPHER_ARTIFACT.abi).concat (HOLOGRAPH_ERC721_ARTIFACT.abi),
        SAMPLE_ERC721_ADDRESS
    );

    let tokenId = NETWORK == 'local' ? 1 : '0xFFFFFFFE00000000000000000000000000000000000000000000000000000001';

    console.log ("\n");

    console.log ('ownerOf', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.ownerOf (tokenId).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    const transferResult = await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.transferFrom (provider.addresses [0], provider.addresses [1], tokenId).send ({
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

    console.log ('ownerOf', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.ownerOf (tokenId).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    const transferBackResult = await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.transferFrom (provider.addresses [1], provider.addresses [0], tokenId).send ({
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
