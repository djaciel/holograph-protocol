'use strict';
const fs = require ('fs');
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {web3Error, createNetworkPropsForUser, getContractArtifact, getContractAddress, createFactoryAtAddress} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)

    const HOLOGRAPH_ERC721 = 'HolographERC721';
    const HOLOGRAPH_ERC721_CONTRACT = getContractArtifact(HOLOGRAPH_ERC721)

    const HOLOGRAPH_ERC721_ADDRESS = getContractAddress(NETWORK, HOLOGRAPH_ERC721)
    const HOLOGRAPH_ERC721_FACTORY = createFactoryAtAddress(web3, HOLOGRAPH_ERC721_CONTRACT.abi, HOLOGRAPH_ERC721_ADDRESS)

    console.log ("\n");

    console.log ('contractURI', await HOLOGRAPH_ERC721_FACTORY.methods.contractURI ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('name', await HOLOGRAPH_ERC721_FACTORY.methods.name ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('symbol', await HOLOGRAPH_ERC721_FACTORY.methods.symbol ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ("\n");

    process.exit ();

}

main ();
