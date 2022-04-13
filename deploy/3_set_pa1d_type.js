'use strict';
const fs = require ('fs');
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {throwError, web3Error, getContractArtifact, createNetworkPropsForUser,
    getContractAddress, createFactoryAtAddress
} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)

    const HOLOGRAPH_REGISTRY_PROXY = 'HolographRegistryProxy';
    const HOLOGRAPH_REGISTRY_PROXY_ADDRESS = getContractAddress(NETWORK, HOLOGRAPH_REGISTRY_PROXY)

    const HOLOGRAPH_REGISTRY = 'HolographRegistry';
    const HOLOGRAPH_REGISTRY_CONTRACT = getContractArtifact(HOLOGRAPH_REGISTRY)

    const PA1D = 'PA1D';
    const PA1D_ADDRESS = getContractAddress(NETWORK, PA1D)
    const HOLOGRAPH_REGISTRY_FACTORY = createFactoryAtAddress(web3, HOLOGRAPH_REGISTRY_CONTRACT.abi, HOLOGRAPH_REGISTRY_PROXY_ADDRESS)

    const setContractTypeAddressResult2 = await HOLOGRAPH_REGISTRY_FACTORY.methods.setContractTypeAddress('0x0000000000000000000000000000000000000000000000000000000050413144', PA1D_ADDRESS).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!setContractTypeAddressResult2.status) {
        throwError (JSON.stringify (setContractTypeAddressResult2, null, 4));
    } else {
        console.log ('Set PA1D address to address type 0x0000000000000000000000000000000000000000000000000000000050413144');
    }

    process.exit ();

}

main ();
