declare var global: any;
import { BigNumber } from 'ethers';
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
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { NetworkType, networks } from '@holographxyz/networks';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';
import { Environment, getEnvironment } from '@holographxyz/environment';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const accounts = await hre.ethers.getSigners();
  let deployer: SignerWithAddress | SuperColdStorageSigner = accounts[0];

  const network = networks[hre.networkName];
  const environment: Environment = getEnvironment();
  const currentNetworkType: NetworkType = network.type;

  // Salt is used for deterministic address generation
  const salt = hre.deploymentSalt;

  // =================================
  // Setup DropsPriceOracle
  // =================================

  const definedOracleNames = {
    avalanche: 'Avalanche',
    avalancheTestnet: 'AvalancheTestnet',
    binanceSmartChain: 'BinanceSmartChain',
    binanceSmartChainTestnet: 'BinanceSmartChainTestnet',
    ethereum: 'Ethereum',
    ethereumTestnetGoerli: 'EthereumTestnetGoerli',
    polygon: 'Polygon',
    polygonTestnet: 'PolygonTestnet',
    optimism: 'Optimism',
    optimismTestnetGoerli: 'OptimismTestnetGoerli',
    arbitrumNova: 'ArbitrumNova',
    arbitrumOne: 'ArbitrumOne',
    arbitrumTestnetGoerli: 'ArbitrumTestnetGoerli',
    mantle: 'Mantle',
    mantleTestnet: 'MantleTestnet',
    base: 'Base',
    baseTestnetGoerli: 'BaseTestnetGoerli',
    zora: 'Zora',
    zoraTestnetGoerli: 'ZoraTestnetGoerli',
  };

  let targetDropsPriceOracle = 'DummyDropsPriceOracle';
  if (network.key in definedOracleNames) {
    targetDropsPriceOracle = 'DropsPriceOracle' + definedOracleNames[network.key];
  } else {
    if (environment == Environment.mainnet || (network.key != 'localhost' && network.key != 'hardhat')) {
      throw new Error('Drops price oracle not created for network yet!');
    }
  }

  hre.deployments.log('targetDropsPriceOracle is', targetDropsPriceOracle);

  // Deploy network specific DropsPriceOracle source contract
  const futureDropsPriceOracleAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    targetDropsPriceOracle,
    generateInitCode([], [])
  );
  hre.deployments.log('the future "' + targetDropsPriceOracle + '" address is', futureDropsPriceOracleAddress);

  // Get DropsPriceOracle source contract code to see if it already exists
  let dropsPriceOracleDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsPriceOracleAddress,
    'latest',
  ]);

  // If DropsPriceOracle source contract is not deployed, deploy it
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

  // Get DropsPriceOracleProxy source contract code to see if it already exists
  let dropsPriceOracleProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsPriceOracleProxyAddress,
    'latest',
  ]);

  // If DropsPriceOracleProxy source contract is not deployed, deploy it
  if (dropsPriceOracleProxyDeployedCode == '0x' || dropsPriceOracleProxyDeployedCode == '') {
    hre.deployments.log('"DropsPriceOracleProxy" bytecode not found, need to deploy"');
    let dropsPriceOracleProxy = await genesisDeployHelper(
      hre,
      salt,
      'DropsPriceOracleProxy',
      generateInitCode(['address', 'bytes'], [futureDropsPriceOracleAddress, generateInitCode([], [])]),
      futureDropsPriceOracleProxyAddress
    );
  } else {
    // If DropsPriceOracleProxy source contract is deployed, check if it references the correct DropsPriceOracle
    hre.deployments.log('"DropsPriceOracleProxy" is already deployed.');
    hre.deployments.log('Checking for reference to correct "' + targetDropsPriceOracle + '" deployment.');
    // need to check here if source reference is correct
    futureDropsPriceOracleProxyAddress;
    const dropsPriceOracleProxy = await hre.ethers.getContract('DropsPriceOracleProxy', deployer);
    let priceOracleSource = await dropsPriceOracleProxy.getDropsPriceOracle();

    // If DropsPriceOracleProxy source contract does not reference the correct DropsPriceOracle, update it
    if (priceOracleSource != futureDropsPriceOracleAddress) {
      hre.deployments.log('"DropsPriceOracleProxy" references incorrect version of "' + targetDropsPriceOracle + '".');
      const setDropsPriceOracleTx = await MultisigAwareTx(
        hre,
        deployer,
        'DropsPriceOracleProxy',
        dropsPriceOracleProxy,
        await dropsPriceOracleProxy.populateTransaction.setDropsPriceOracle(futureDropsPriceOracleAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: dropsPriceOracleProxy,
            data: dropsPriceOracleProxy.populateTransaction.setDropsPriceOracle(futureDropsPriceOracleAddress),
          })),
        })
      );
      hre.deployments.log('Transaction hash:', setDropsPriceOracleTx.hash);
      await setDropsPriceOracleTx.wait();
      hre.deployments.log('"DropsPriceOracleProxy" reference updated.');
    } else {
      hre.deployments.log('"DropsPriceOracleProxy" references correct version of "' + targetDropsPriceOracle + '".');
    }
  }

  // Verify
  let contracts: string[] = ['DropsPriceOracleProxy', targetDropsPriceOracle];
  for (let i: number = 0, l: number = contracts.length; i < l; i++) {
    let contract: string = contracts[i];
    try {
      await hre1.run('verify:verify', {
        address: (await hre.ethers.getContract(contract)).address,
        contract: targetDropsPriceOracle + '.sol:' + targetDropsPriceOracle,
        constructorArguments: [],
      });
    } catch (error) {
      hre.deployments.log(`Failed to verify ""${contract}" -> ${error}`);
    }
  }
};

export default func;
func.tags = ['TEMP_DROPS_PRICE_ORACLE_UPGRADE'];
func.dependencies = [];
