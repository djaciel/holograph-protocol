'use strict';

const fs = require ('fs');
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    WALLET1,
    WALLET2,
} = require ('../config/env');
const {throwError, web3Error, getContractArtifact, getNetworkInfo} = require("./helpers/utils");

async function main () {
    const network = getNetworkInfo(NETWORK)
    const provider = new HDWalletProvider ([WALLET1, WALLET2], network.rpc, 0, 2);
    const web3 = new Web3 (provider);

    const SAMPLE_ERC721 = 'SampleERC721';
    const SAMPLE_ERC721_CONTRACT = getContractArtifact(SAMPLE_ERC721)
    const ERC721_ADDRESS = fs.readFileSync ('./data/' + NETWORK + '.' + SAMPLE_ERC721 + '.address', 'utf8').trim ();

    const HOLOGRAPHER = 'Holographer';
    const HOLOGRAPHER_CONTRACT = getContractArtifact(HOLOGRAPHER)
    const HOLOGRAPH_ERC721 = 'HolographERC721';
    const HOLOGRAPH_ERC721_CONTRACT = getContractArtifact(HOLOGRAPH_ERC721)

    const HOLOGRAPH_ERC721_CONTRACT_FACTORY = new web3.eth.Contract (
        SAMPLE_ERC721_CONTRACT.abi.concat (HOLOGRAPHER_CONTRACT.abi).concat (HOLOGRAPH_ERC721_CONTRACT.abi),
        ERC721_ADDRESS
    );

    let tokenId = NETWORK == 'local' ? 1 : '0xFFFFFFFE00000000000000000000000000000000000000000000000000000001';

    console.log ("\n");

    const mintResult = await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.mint (provider.addresses [0], "https://sample.url/my.jpg").send ({
        chainId: network.chain,
        from: provider.addresses [0],
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

    console.log ("\n");

    process.exit ();

}

main ();
