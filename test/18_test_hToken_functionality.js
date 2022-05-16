'use strict';
const HDWalletProvider = require ('truffle-hdwallet-provider');
const Web3 = require ('web3');
const {
    NETWORK,
    GAS,
    DEPLOYER,
    WALLET1,
    WALLET2
} = require ('../config/env');
const {throwError, web3Error, getContractArtifact, getNetworkInfo, getContractAddress, createNetworkPropsForUser} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser([DEPLOYER, WALLET1, WALLET2], NETWORK)

    const H_TOKEN = 'token/hToken';
    const H_TOKEN_ARTIFACT = getContractArtifact(H_TOKEN)
    const H_TOKEN_ADDRESS = getContractAddress(NETWORK, H_TOKEN)

    const HOLOGRAPHER = 'Holographer';
    const HOLOGRAPHER_ARTIFACT = getContractArtifact(HOLOGRAPHER)

    const HOLOGRAPH_ERC20 = 'HolographERC20';
    const HOLOGRAPH_ERC20_ARTIFACT = getContractArtifact(HOLOGRAPH_ERC20)

    const ERC20_MOCK = 'mock/ERC20Mock';
    const ERC20_MOCK_ARTIFACT = getContractArtifact(ERC20_MOCK)
    const ERC20_MOCK_ADDRESS = getContractAddress(NETWORK, ERC20_MOCK)
    const ERC20_MOCK_CONTRACT_FACTORY = new web3.eth.Contract (ERC20_MOCK_ARTIFACT.abi, ERC20_MOCK_ADDRESS);

    const HOLOGRAPH_ERC20_CONTRACT_FACTORY = new web3.eth.Contract (
        H_TOKEN_ARTIFACT.abi.concat (HOLOGRAPHER_ARTIFACT.abi).concat (HOLOGRAPH_ERC20_ARTIFACT.abi),
        H_TOKEN_ADDRESS
    );

    let firstWalletTokenBalance = await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.balanceOf (provider.addresses [1]).call ({
        chainId: network.chain,
        from: provider.addresses [1],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    console.log ('balanceOf', provider.addresses [1], '==', web3.utils.fromWei (firstWalletTokenBalance, 'ether'), 'hTokens');
    const transferResult = await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.transferFrom (provider.addresses [1], provider.addresses [2], firstWalletTokenBalance).send ({
        chainId: network.chain,
        from: provider.addresses [1],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!transferResult.status) {
        throwError (JSON.stringify (transferResult, null, 4));
    }
    console.log (
        "\n" + 'A total of',
        web3.utils.fromWei (transferResult.events.Transfer.returnValues._value, 'ether'), 'hTokens',
        'transfered from',
        transferResult.events.Transfer.returnValues._from,
        'to',
        transferResult.events.Transfer.returnValues._to
    );

    let secondWalletTokenBalance = await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.balanceOf (provider.addresses [2]).call ({
        chainId: network.chain,
        from: provider.addresses [1],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    console.log ('balanceOf', provider.addresses [1], '==', web3.utils.fromWei (secondWalletTokenBalance, 'ether'), 'hTokens');
    const transferBackResult = await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.transferFrom (provider.addresses [2], provider.addresses [1], secondWalletTokenBalance).send ({
        chainId: network.chain,
        from: provider.addresses [2],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!transferBackResult.status) {
        throwError (JSON.stringify (transferBackResult, null, 4));
    }
    console.log (
        "\n" + 'A total of',
        web3.utils.fromWei (transferBackResult.events.Transfer.returnValues._value, 'ether'), 'hTokens',
        'transfered from',
        transferBackResult.events.Transfer.returnValues._from,
        'to',
        transferBackResult.events.Transfer.returnValues._to
    );

    if (firstWalletTokenBalance != secondWalletTokenBalance) {
        throwError ('hToken amounts do not match!');
    }

    const SOURCE_CONTRACT_ADDRESS = await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.getSourceContract ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);

    const firstWalletMockBalance = await ERC20_MOCK_CONTRACT_FACTORY.methods.balanceOf (provider.addresses [1]).call ({
        chainId: network.chain,
        from: provider.addresses [1],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    console.log ('firstWalletMockBalance', firstWalletMockBalance);

    const approveOperatorResult = await ERC20_MOCK_CONTRACT_FACTORY.methods.approve (SOURCE_CONTRACT_ADDRESS, firstWalletMockBalance).send ({
        chainId: network.chain,
        from: provider.addresses [1],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!approveOperatorResult.status) {
        throwError (JSON.stringify (approveOperatorResult, null, 4));
    }

    const mintFromWrappedResult = await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.holographWrappedToken ('0x0000000000000000000000000000000000000000', ERC20_MOCK_ADDRESS, provider.addresses [1], firstWalletMockBalance).send ({
        chainId: network.chain,
        from: provider.addresses [1],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!mintFromWrappedResult.status) {
        throwError (JSON.stringify (mintFromWrappedResult, null, 4));
    }
    console.log ('Minted a total of', web3.utils.fromWei (mintFromWrappedResult.events.Transfer[0].returnValues._value, 'ether'), 'hTokens.');

    const secondWalletMockBalance = await ERC20_MOCK_CONTRACT_FACTORY.methods.balanceOf (provider.addresses [2]).call ({
        chainId: network.chain,
        from: provider.addresses [2],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    console.log ('secondWalletMockBalance', secondWalletMockBalance);

    const approveOperatorResult2 = await ERC20_MOCK_CONTRACT_FACTORY.methods.approve (SOURCE_CONTRACT_ADDRESS, secondWalletMockBalance).send ({
        chainId: network.chain,
        from: provider.addresses [2],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!approveOperatorResult2.status) {
        throwError (JSON.stringify (approveOperatorResult2, null, 4));
    }

    const mintFromWrappedResult2 = await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.holographWrappedToken ('0x0000000000000000000000000000000000000000', ERC20_MOCK_ADDRESS, provider.addresses [2], secondWalletMockBalance).send ({
        chainId: network.chain,
        from: provider.addresses [2],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!mintFromWrappedResult2.status) {
        throwError (JSON.stringify (mintFromWrappedResult2, null, 4));
    }
    console.log ('Minted a total of', web3.utils.fromWei (mintFromWrappedResult2.events.Transfer[0].returnValues._value, 'ether'), 'hTokens.');

    console.log ('balanceOf', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.balanceOf (provider.addresses [1]).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    console.log ('totalSupply', await HOLOGRAPH_ERC20_CONTRACT_FACTORY.methods.totalSupply ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    /*
     * TO DO: we need to include unwrapping functionality, test against native token, and against supported wrapped token
     * available balances can be retrieved via availableNativeTokens(msgSender) and availableWrappedTokens(msgSender,token)
     */

    process.exit ();

}

main ();
