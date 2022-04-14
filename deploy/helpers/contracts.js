const {getContractArtifact, getContractAddress, createFactoryAtAddress} = require("./utils");

function getContractByName(web3, networkName, name) {
    const artifact = getContractArtifact(name)
    const address = getContractAddress(networkName, name)
    const contract = createFactoryAtAddress(web3, artifact.abi, address)
    return {
        name,
        artifact,
        address,
        contract
    }
}

function getGenesisContract(web3, networkName) {
    const name = 'HolographGenesis';
    return getContractByName(web3, networkName, name)
}

function getHolographRegistryContract(web3, networkName) {
    const name = 'HolographRegistry';
    return getContractByName(web3, networkName, name)
}

function getHolographRegistryProxyContract(web3, networkName) {
    const name = 'HolographRegistryProxy';
    return getContractByName(web3, networkName, name)
}

function getHolographFactoryContract(web3, networkName) {
    const name = 'HolographFactory';
    return getContractByName(web3, networkName, name)
}

function getSecureStorageContract(web3, networkName) {
    const name = 'SecureStorage';
    return getContractByName(web3, networkName, name)
}

function getSecureStorageProxyContract(web3, networkName) {
    const name = 'SecureStorageProxy';
    return getContractByName(web3, networkName, name)
}

function getHolographFactoryProxyContract(web3, networkName) {
    const name = 'HolographFactoryProxy';
    return getContractByName(web3, networkName, name)
}

function getHolographBridgeContract(web3, networkName) {
    const name = 'HolographBridge';
    return getContractByName(web3, networkName, name)
}

function getHolographBridgeProxyContract(web3, networkName) {
    const name = 'HolographBridgeProxy';
    return getContractByName(web3, networkName, name)
}

function getHolographContract(web3, networkName) {
    const name = 'Holograph';
    return getContractByName(web3, networkName, name)
}

function getPA1DContract(web3, networkName) {
    const name = 'PA1D';
    return getContractByName(web3, networkName, name)
}

function getHolographERC721Contract(web3, networkName) {
    const name = 'HolographERC721';
    return getContractByName(web3, networkName, name)
}



module.exports = {
    getContractByName,
    getGenesisContract,
    getHolographRegistryContract,
    getHolographContract,
    getHolographRegistryProxyContract,
    getHolographFactoryContract,
    getSecureStorageContract,
    getSecureStorageProxyContract,
    getHolographFactoryProxyContract,
    getHolographBridgeContract,
    getHolographBridgeProxyContract,
    getPA1DContract,
    getHolographERC721Contract
}