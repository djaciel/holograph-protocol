'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {web3Error, createNetworkPropsForUser} = require("./helpers/utils");
const {getHolographERC20Contract} = require("./helpers/contracts");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)

    const HOLOGRAPH_ERC20 = getHolographERC20Contract(web3, NETWORK)

    console.log ('name', await HOLOGRAPH_ERC20.contract.methods.name ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('symbol', await HOLOGRAPH_ERC20.contract.methods.symbol ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('decimals', await HOLOGRAPH_ERC20.contract.methods.decimals ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    process.exit ();

}

main ();
