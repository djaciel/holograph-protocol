'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    WALLET1,
    WALLET2,
    DEPLOYER
} = require ('../config/env');
const {throwError, web3Error, getContractArtifact, getNetworkInfo, getContractAddress} = require("./helpers/utils");

async function main () {
    const network = getNetworkInfo(NETWORK)
    const provider = new HDWalletProvider ([WALLET1, WALLET2, DEPLOYER], network.rpc, 0, 3);
    const web3 = new Web3 (provider);

    const SAMPLE_ERC721 = 'token/SampleERC721';
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

    const mintResult = await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.mint ('0x0000000000000000000000000000000000000000', provider.addresses [0], "https://sample.url/my.jpg").send ({
        chainId: network.chain,
        from: provider.addresses [2],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!mintResult.status) {
        throwError (JSON.stringify (mintResult, null, 4));
    }
    console.log ('Token id', mintResult.events.Transfer.returnValues._tokenId, 'minted.');

    console.log ('tokenURI', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.tokenURI (tokenId).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('exists', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.exists (tokenId).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('ownerOf', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.ownerOf (tokenId).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    process.exit ();

}

main ();
