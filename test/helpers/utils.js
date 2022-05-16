const fs = require('fs')
const HDWalletProvider = require('truffle-hdwallet-provider')
const Web3 = require('web3')

function cleanupContractName(name) {
    const split = name.split('/');
    if (split.length > 1) {
        name = split[split.length - 1];
    }
    return name;
}

function getContractArtifact(name) {
    const originalName = name;
    name = cleanupContractName(name);
    return JSON.parse (fs.readFileSync ('./build/combined.json')).contracts[originalName + '.sol:' + name];
}

function getContractAddress(networkName, name) {
    name = cleanupContractName(name);
    try {
        return fs.readFileSync ('./data/' + networkName + '.' + name + '.address', 'utf8').trim();
    } catch (ex) {
        return '0x0000000000000000000000000000000000000000';
    }
}

function getNetworkInfo(name) {
    return JSON.parse (fs.readFileSync ('./networks.json', 'utf8')) [name];
}

function createProvider(privateKey, rpc) {
    let length = 1;
    if (typeof(privateKey) !== 'string') {
        // we are enabling support for multiple private keys
        length = privateKey.length;
    }
    // disabling nonce-sharing in order to prevent local testing nonce desynchronisation
    return new HDWalletProvider (privateKey, rpc, 0, length, false);
}

function createWeb3(provider) {
    return new Web3 (provider);
}

function createProviderAndWeb3(privateKey, rpc) {
    const provider = createProvider(privateKey, rpc)
    const web3 = createWeb3(provider)
    return {
        provider,
        web3,
    }
}

function createNetworkPropsForUser(privateKey, networkName) {
    const network = getNetworkInfo(networkName)
    const { provider, web3 } = createProviderAndWeb3(privateKey, network.rpc)
    return {
        network,
        provider,
        web3
    }
}

function createFactoryFromABI(web3, abi) {
    return new web3.eth.Contract (abi);
}

function createFactoryAtAddress(web3, abi, address) {
    return new web3.eth.Contract (
        abi,
        address
    );
}

function createCombinedFactoryAtAddress(web3, artifacts, address) {
    if(artifacts.length > 2) {
        throw new Error(`Cannot combine more than two ABI's at a time`)
    }
    const result = artifacts[0].abi.concat(artifacts[1].abi)
    return new web3.eth.Contract(
        result,
        address
    )
}

function saveContractResult(networkName, contractName, contractAddress) {
    const split = contractName.split('/');
    if (split.length > 1) {
        contractName = split[split.length - 1];
    }
    fs.writeFileSync (
        './data/' + networkName + '.' + contractName + '.address',
        contractAddress
    );
    console.log(`Deployed ${contractName} Contract: ${contractAddress}`)
}


const removeX = function (input) {
    if (input.startsWith ('0x')) {
        return input.substring (2);
    } else {
        return input;
    }
};

const hexify = function (input, prepend) {
    input = input.toLowerCase ().trim ();
    if (input.startsWith ('0x')) {
        input = input.substring (2);
    }
    input = input.replace (/[^0-9a-f]/g, '');
    if (prepend) {
        input = '0x' + input;
    }
    return input;
};

const throwError = function (err) {
    process.stderr.write (err + '\n');
    process.exit (1);
};

const web3Error = function (err) {
    throwError (err.toString ())
};

const generateExpectedAddress = function({genesisAddress, web3, senderAddress, salt, contractByteCode}) {
    return '0x' + removeX (web3.utils.keccak256 (
        '0xff'
        + removeX (genesisAddress)
        + removeX (senderAddress) + removeX (salt)
        + removeX (web3.utils.keccak256 ('0x' + contractByteCode))
    )).substring (24);
}

const setEvents = function (events) {
    if (events.length < (32 * 8)) {
        let add = (32 * 8) - events.length;
        events = events.concat (Array.from (
            {
                length: add
            },
            function (_, i) {
                return false;
            }
        ));
    }
    let binary = '';
    for (let i = 0, l = (32 * 8); i < l; i++) {
        let e = events [i];
        if (!e && e != 1 && e != '1' && e != 'true') {
            binary = '0' + binary;
        } else {
            binary = '1' + binary;
        }
    }
    return '0x' + parseInt (binary, 2).toString (16).padStart (64, '0');
};



module.exports = {
    cleanupContractName,
    getContractArtifact,
    getContractAddress,
    getNetworkInfo,
    createProvider,
    createWeb3,
    createProviderAndWeb3,
    createNetworkPropsForUser,
    createFactoryFromABI,
    createFactoryAtAddress,
    createCombinedFactoryAtAddress,
    saveContractResult,
    removeX,
    hexify,
    throwError,
    web3Error,
    generateExpectedAddress,
    setEvents
}