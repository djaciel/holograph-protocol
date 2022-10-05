declare var global: any;
import { Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {
  hreSplit,
  genesisDeployHelper,
  genesisDeriveFutureAddress,
  generateErc20Config,
  generateInitCode,
} from '../scripts/utils/helpers';
import { HolographERC20Event, ConfigureEvents } from '../scripts/utils/events';
import networks from '../config/networks';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);

  const accounts = await hre.ethers.getSigners();
  const deployer: SignerWithAddress = accounts[0];

  const network = networks[hre.networkName];

  const salt = hre.deploymentSalt;

  const holographRegistryProxy = await hre.ethers.getContract('HolographRegistryProxy');
  const holographRegistry = ((await hre.ethers.getContract('HolographRegistry')) as Contract).attach(
    holographRegistryProxy.address
  );

  let sampleErc20Config = await generateErc20Config(
    network,
    deployer.address,
    'SampleERC20',
    'Sample ERC20 Token (' + hre.networkName + ')',
    'SMPL',
    'Sample ERC20 Token',
    '1',
    18,
    ConfigureEvents([HolographERC20Event.bridgeIn, HolographERC20Event.bridgeOut]),
    generateInitCode(['address', 'uint16'], [deployer.address, 0]),
    salt
  );
  let sampleErc20Address = await holographRegistry.getHolographedHashAddress(sampleErc20Config.erc20ConfigHash);

  const futureFaucetAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'Faucet',
    generateInitCode(['address', 'address'], [deployer.address, sampleErc20Address])
  );
  hre.deployments.log('the future "Faucet" address is', futureFaucetAddress);

  // Faucet
  let faucetDeployedCode: string = await hre.provider.send('eth_getCode', [futureFaucetAddress, 'latest']);
  if (faucetDeployedCode == '0x' || faucetDeployedCode == '') {
    hre.deployments.log('"Faucet" bytecode not found, need to deploy"');
    let faucet = await genesisDeployHelper(
      hre,
      salt,
      'Faucet',
      generateInitCode(['address', 'address'], [deployer.address, sampleErc20Address]),
      futureFaucetAddress
    );
  } else {
    hre.deployments.log('"Faucet" is already deployed.');
  }
};

export default func;
func.tags = ['Faucet'];
func.dependencies = ['SampleERC20'];
