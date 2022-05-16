'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {web3Error, getContractArtifact, createNetworkPropsForUser, getContractAddress} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)

    const H_TOKEN = 'token/hToken';
    const H_TOKEN_ARTIFACT = getContractArtifact(H_TOKEN)
    const H_TOKEN_ADDRESS = getContractAddress(NETWORK, H_TOKEN)

    const HOLOGRAPH_ERC20 = 'HolographERC20';
    const HOLOGRAPH_ERC20_ARTIFACT = getContractArtifact(HOLOGRAPH_ERC20)

    const HOLOGRAPHER = 'Holographer';
    const HOLOGRAPHER_ARTIFACT = getContractArtifact(HOLOGRAPHER)

    const HOLOGRAPH_ERC20_CONTRACT_FACTORY = new web3.eth.Contract (
        H_TOKEN_ARTIFACT.abi.concat (HOLOGRAPHER_ARTIFACT.abi).concat (HOLOGRAPH_ERC20_ARTIFACT.abi),
        H_TOKEN_ADDRESS
    );

    const ERC20_MOCK = 'mock/ERC20Mock';
    const ERC20_MOCK_ADDRESS = getContractAddress(NETWORK, ERC20_MOCK)

    const supportMockTokenResult = await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.updateSupportedWrapper ('0x0000000000000000000000000000000000000000', ERC20_MOCK_ADDRESS, true).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!supportMockTokenResult.status) {
        throwError (JSON.stringify (supportMockTokenResult, null, 4));
    }
    console.log ('Enabled support for Mock ERC20 token use with hToken');

    console.log ('getHolographEnforcer', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.getHolographEnforcer ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('getSecureStorage', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.getSecureStorage ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('getSourceContract', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.getSourceContract ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('test', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.test ('0x0000000000000000000000000000000000000000').call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('name', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.name ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('symbol', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.symbol ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('decimals', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.decimals ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('getOriginChain', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.getOriginChain ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    process.exit ();

}

main ();
