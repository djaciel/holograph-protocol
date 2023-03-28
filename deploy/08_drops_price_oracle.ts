declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction, DeployOptions } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  hreSplit,
  txParams,
  genesisDeployHelper,
  generateInitCode,
  genesisDeriveFutureAddress,
  zeroAddress,
} from '../scripts/utils/helpers';
import { NetworkType, networks } from '@holographxyz/networks';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';
import { Environment, getEnvironment } from '@holographxyz/environment';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const accounts = await hre.ethers.getSigners();
  let deployer: SignerWithAddress | SuperColdStorageSigner = accounts[0];
  if (global.__superColdStorage) {
    // address, domain, authorization, ca
    const coldStorage = global.__superColdStorage;
    deployer = new SuperColdStorageSigner(
      coldStorage.address,
      'https://' + coldStorage.domain,
      coldStorage.authorization,
      deployer.provider,
      coldStorage.ca
    );
  }

  const network = networks[hre.networkName];
  const environment: Environment = getEnvironment();
  const currentNetworkType: NetworkType = network.type;

  // Salt is used for deterministic address generation
  const salt = hre.deploymentSalt;

  const definedOracleNames = {
    avalanche: 'Avalanche',
    avalancheTestnet: 'AvalancheTestnet',
    binanceSmartChain: 'BinanceSmartChain',
    binanceSmartChainTestnet: 'BinanceSmartChainTestnet',
    ethereum: 'Ethereum',
    ethereumTestnetGoerli: 'EthereumTestnetGoerli',
    polygon: 'Polygon',
    polygonTestnet: 'PolygonTestnet',
    optimismTestnetGoerli: 'EthereumTestnetGoerli',
  };

  let targetDropsPriceOracle = 'DummyDropsPriceOracle';
  if (network.key in definedOracleNames) {
    targetDropsPriceOracle = 'DropsPriceOracle' + definedOracleNames[network.key];
  } else {
    if (environment == Environment.mainnet || (network.key != 'localhost' && network.key != 'hardhat')) {
      throw new Error('Drops price oracle not created for network yet!');
    }
  }
  // Deploy network specific DropsPriceOracle source contract
  const futureDropsPriceOracleAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    targetDropsPriceOracle,
    generateInitCode([], [])
  );
  hre.deployments.log('the future "' + targetDropsPriceOracle + '" address is', futureDropsPriceOracleAddress);
  let dropsPriceOracleDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsPriceOracleAddress,
    'latest',
  ]);
  if (dropsPriceOracleDeployedCode == '0x' || dropsPriceOracleDeployedCode == '') {
    definedOracleNames;
    hre.deployments.log('"' + targetDropsPriceOracle + '" bytecode not found, need to deploy"');
    let dropsPriceOracle = await genesisDeployHelper(
      hre,
      salt,
      targetDropsPriceOracle,
      generateInitCode([], []),
      futureDropsPriceOracleAddress
    );
  } else {
    hre.deployments.log('"' + targetDropsPriceOracle + '" is already deployed.');
  }

  // Deploy DropsPriceOracleProxy source contract
  const futureDropsPriceOracleProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'DropsPriceOracleProxy',
    generateInitCode([], [])
  );
  hre.deployments.log('the future "DropsPriceOracleProxy" address is', futureDropsPriceOracleProxyAddress);
  let dropsPriceOracleProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsPriceOracleProxyAddress,
    'latest',
  ]);
  if (dropsPriceOracleProxyDeployedCode == '0x' || dropsPriceOracleProxyDeployedCode == '') {
    definedOracleNames;
    hre.deployments.log('"DropsPriceOracleProxy" bytecode not found, need to deploy"');
    let dropsPriceOracleProxy = await genesisDeployHelper(
      hre,
      salt,
      'DropsPriceOracleProxy',
      generateInitCode(['address', 'bytes'], [futureDropsPriceOracleAddress, generateInitCode([], [])]),
      futureDropsPriceOracleProxyAddress
    );
  } else {
    hre.deployments.log('"DropsPriceOracleProxy" is already deployed.');
    hre.deployments.log('Checking for reference to correct "' + targetDropsPriceOracle + '" deployment.');
    // need to check here if source reference is correct
    futureDropsPriceOracleProxyAddress;
    const dropsPriceOracleProxy = await hre.ethers.getContract('DropsPriceOracleProxy', deployer);
    let priceOracleSource = await dropsPriceOracleProxy.getDropsPriceOracle();
    if (priceOracleSource != futureDropsPriceOracleAddress) {
      hre.deployments.log('"DropsPriceOracleProxy" references incorrect version of "' + targetDropsPriceOracle + '".');
      const setDropsPriceOracleTx = await dropsPriceOracleProxy
        .setDropsPriceOracle(futureDropsPriceOracleAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: dropsPriceOracleProxy,
            data: dropsPriceOracleProxy.populateTransaction.setDropsPriceOracle(futureDropsPriceOracleAddress),
          })),
        })
        .catch(error);
      hre.deployments.log('Transaction hash:', setDropsPriceOracleTx.hash);
      await setDropsPriceOracleTx.wait();
      hre.deployments.log('"DropsPriceOracleProxy" reference updated.');
    } else {
      hre.deployments.log('"DropsPriceOracleProxy" references correct version of "' + targetDropsPriceOracle + '".');
    }
  }
};

export default func;
func.tags = ['DropsPriceOracleProxy', 'DropsPriceOracle'];
func.dependencies = ['HolographGenesis'];
