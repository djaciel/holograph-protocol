'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {web3Error, createNetworkPropsForUser} = require("./helpers/utils");
const {getHolographERC721Contract} = require("./helpers/contracts");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)

    const HOLOGRAPH_ERC721 = getHolographERC721Contract(web3, NETWORK)

    console.log ("\n");

    console.log ('contractURI', await HOLOGRAPH_ERC721.contract.methods.contractURI ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('name', await HOLOGRAPH_ERC721.contract.methods.name ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('symbol', await HOLOGRAPH_ERC721.contract.methods.symbol ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ("\n");

    process.exit ();

}

main ();
