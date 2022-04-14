'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {throwError, web3Error, getContractArtifact, createNetworkPropsForUser,
    createFactoryAtAddress
} = require("./helpers/utils");
const {getHolographRegistryProxyContract, getHolographERC721Contract} = require("./helpers/contracts");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)


    const HOLOGRAPH_REGISTRY_PROXY = getHolographRegistryProxyContract(web3, NETWORK)

    const HOLOGRAPH_REGISTRY = 'HolographRegistry';
    const HOLOGRAPH_REGISTRY_ARTIFACT = getContractArtifact(HOLOGRAPH_REGISTRY)
    const HOLOGRAPH_REGISTRY_FACTORY = createFactoryAtAddress(web3, HOLOGRAPH_REGISTRY_ARTIFACT.abi, HOLOGRAPH_REGISTRY_PROXY.address) // NOTE: now how it uses the proxy address

    const HOLOGRAPH_ERC721 = getHolographERC721Contract(web3, NETWORK)

    const setContractTypeAddressResult = await HOLOGRAPH_REGISTRY_FACTORY.methods.setContractTypeAddress('0x0000000000000000000000000000000000486f6c6f6772617068455243373231', HOLOGRAPH_ERC721.address).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!setContractTypeAddressResult.status) {
        throwError (JSON.stringify (setContractTypeAddressResult, null, 4));
    } else {
        console.log ('Set HolographERC721 address to address type 0x0000000000000000000000000000000000486f6c6f6772617068455243373231');
    }

    process.exit ();

}

main ();
