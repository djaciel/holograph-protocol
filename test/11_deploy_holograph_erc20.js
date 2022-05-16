'use strict';
const {
    NETWORK,
    GAS,
    DEPLOYER
} = require ('../config/env');
const {throwError, web3Error, createNetworkPropsForUser, saveContractResult, generateExpectedAddress
} = require("./helpers/utils");
const {getGenesisContract, getHolographERC20Contract} = require("./helpers/contracts");

async function main () {
    const { network, provider, web3 } = createNetworkPropsForUser(DEPLOYER, NETWORK)
    const salt = '0x000000000000000000000000';

    const GENESIS = getGenesisContract(web3, NETWORK)

// HolographERC20
    const HOLOGRAPH_ERC20 = getHolographERC20Contract(web3, NETWORK)

    const holographErc20DeploymentResult = await GENESIS.contract.methods.deploy (
        salt, // bytes12 saltHash
        '0x' + HOLOGRAPH_ERC20.artifact.bin, // bytes memory sourceCode
        web3.eth.abi.encodeParameters (
            ['string', 'string', 'uint16', 'uint256', 'bytes'],
            [
                'Sample ERC20 Token', // contractName
                'ERC20TOKEN', // contractSymbol
                18, // contractDecimals
                0, // eventConfig
                '0x' // initCode
            ]
        ) // bytes memory initCode
    ).send ({
        chainId: network.chain,
        from: provider.addresses [0],
        gas: web3.utils.toHex (6000000),
        gasPrice: web3.utils.toHex (web3.utils.toWei (GAS, 'gwei'))
    }).catch (web3Error);

    let holographErc20Address = generateExpectedAddress({
        genesisAddress: GENESIS.address,
        web3,
        senderAddress: provider.addresses[0],
        salt,
        contractByteCode: HOLOGRAPH_ERC20.artifact.bin
    })

    if (!holographErc20DeploymentResult.status) {
        throwError (JSON.stringify (holographErc20DeploymentResult, null, 4));
    }
    if ('0x' + HOLOGRAPH_ERC20.artifact['bin-runtime'] != await web3.eth.getCode (holographErc20Address)) {
        throwError ('Could not properly compute CREATE2 address for holographErc20Address');
    }
    saveContractResult(NETWORK, HOLOGRAPH_ERC20.name, holographErc20Address)

    process.exit ();
}

main ();
