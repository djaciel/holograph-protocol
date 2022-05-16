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
const {throwError, web3Error, getContractArtifact, getNetworkInfo, getContractAddress, createNetworkPropsForUser, createFactoryFromABI, saveContractResult} = require("./helpers/utils");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser([DEPLOYER, WALLET1, WALLET2], NETWORK)

    const ERC20_MOCK = 'mock/ERC20Mock';
    const ERC20_MOCK_ARTIFACT = getContractArtifact(ERC20_MOCK)
    const ERC20_MOCK_FACTORY = createFactoryFromABI(web3, ERC20_MOCK_ARTIFACT.abi)

    const ERC20_MOCK_CONTRACT = await ERC20_MOCK_FACTORY.deploy ({
        data: ERC20_MOCK_ARTIFACT.bin,
        arguments: [
            'Wrapped ETH (MOCK)',
            'WETHmock',
            18,
            'DomainSeperator',
            '1'
        ]
    }).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (6000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);

    saveContractResult(NETWORK, ERC20_MOCK, ERC20_MOCK_CONTRACT.options.address);

    console.log ('name', await ERC20_MOCK_CONTRACT.methods.name ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    const symbol = await ERC20_MOCK_CONTRACT.methods.symbol ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    console.log ('symbol', symbol);

    console.log ('decimals', await ERC20_MOCK_CONTRACT.methods.decimals ().call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error));

    let wallet1amount = '12.34';
    const mintResult1 = await ERC20_MOCK_CONTRACT.methods.mint (provider.addresses [1], web3.utils.toWei (wallet1amount, 'ether')).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!mintResult1.status) {
        throwError (JSON.stringify (mintResult1, undefined, 4));
    }
    console.log ('mint', wallet1amount, symbol, 'for', provider.addresses [1]);

    let wallet2amount = '43.21';
    const mintResult2 = await ERC20_MOCK_CONTRACT.methods.mint (provider.addresses [2], web3.utils.toWei (wallet2amount, 'ether')).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);
    if (!mintResult2.status) {
        throwError (JSON.stringify (mintResult2, undefined, 4));
    }
    console.log ('mint', wallet2amount, symbol, 'for', provider.addresses [2]);

    console.log ('balanceOf', provider.addresses [1], web3.utils.fromWei (await ERC20_MOCK_CONTRACT.methods.balanceOf (provider.addresses [1]).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error), 'ether'), symbol);

    console.log ('balanceOf', provider.addresses [2], web3.utils.fromWei (await ERC20_MOCK_CONTRACT.methods.balanceOf (provider.addresses [2]).call ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (1000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error), 'ether'), symbol);

    process.exit ();

}

main ();
