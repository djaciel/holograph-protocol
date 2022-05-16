'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {web3Error, getContractArtifact, createNetworkPropsForUser, getContractAddress} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)

    const SAMPLE_ERC721 = 'token/SampleERC721';
    const SAMPLE_ERC721_ARTIFACT = getContractArtifact(SAMPLE_ERC721)
    const SAMPLE_ERC721_ADDRESS = getContractAddress(NETWORK, SAMPLE_ERC721)

    const HOLOGRAPH_ERC721 = 'HolographERC721';
    const HOLOGRAPH_ERC721_ARTIFACT = getContractArtifact(HOLOGRAPH_ERC721)

    const HOLOGRAPHER = 'Holographer';
    const HOLOGRAPHER_ARTIFACT = getContractArtifact(HOLOGRAPHER)

    const HOLOGRAPH_ERC721_CONTRACT_FACTORY = new web3.eth.Contract (
        SAMPLE_ERC721_ARTIFACT.abi.concat (HOLOGRAPHER_ARTIFACT.abi).concat (HOLOGRAPH_ERC721_ARTIFACT.abi),
        SAMPLE_ERC721_ADDRESS
    );

    console.log ('getHolographEnforcer', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.getHolographEnforcer ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('getSecureStorage', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.getSecureStorage ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('getSourceContract', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.getSourceContract ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('test', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.test ('0x0000000000000000000000000000000000000000').call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('contractURI', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.contractURI ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('name', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.name ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('symbol', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.symbol ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('getOriginChain', await HOLOGRAPH_ERC721_CONTRACT_FACTORY.methods.getOriginChain ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    process.exit ();

}

main ();
