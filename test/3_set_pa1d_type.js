'use strict';
const fs = require ('fs');
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {throwError, web3Error, createNetworkPropsForUser, createFactoryAtAddress
} = require("./helpers/utils");
const {getHolographRegistryProxyContract, getHolographRegistryContract, getPA1DContract} = require("./helpers/contracts");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)

    const HOLOGRAPH_REGISTRY_PROXY = getHolographRegistryProxyContract(web3, NETWORK)
    const HOLOGRAPH_REGISTRY = getHolographRegistryContract(web3, NETWORK)
    const PA1D = getPA1DContract(web3, NETWORK)

    const HOLOGRAPH_REGISTRY_FACTORY = createFactoryAtAddress(web3, HOLOGRAPH_REGISTRY.artifact.abi, HOLOGRAPH_REGISTRY_PROXY.address)

    const setContractTypeAddressResult2 = await HOLOGRAPH_REGISTRY_FACTORY.methods.setContractTypeAddress('0x0000000000000000000000000000000000000000000000000000000050413144', PA1D.address).send ({
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
