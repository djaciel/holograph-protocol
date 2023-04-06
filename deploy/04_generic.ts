declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  hreSplit,
  genesisDeployHelper,
  genesisDeriveFutureAddress,
  generateInitCode,
  txParams,
} from '../scripts/utils/helpers';
import { ConfigureEvents } from '../scripts/utils/events';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';

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

  const salt = hre.deploymentSalt;

  const futureGenericAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographGeneric',
    generateInitCode(
      ['uint256', 'bool', 'bytes'],
      [
        ConfigureEvents([]), // eventConfig
        true, // skipInit
        '0x', // initCode
      ]
    )
  );
  hre.deployments.log('the future "HolographGeneric" address is', futureGenericAddress);

  // HolographGeneric
  let genericDeployedCode: string = await hre.provider.send('eth_getCode', [futureGenericAddress, 'latest']);
  if (genericDeployedCode == '0x' || genericDeployedCode == '') {
    hre.deployments.log('"HolographGeneric" bytecode not found, need to deploy"');
    let holographGeneric = await genesisDeployHelper(
      hre,
      salt,
      'HolographGeneric',
      generateInitCode(
        ['uint256', 'bool', 'bytes'],
        [
          ConfigureEvents([]), // eventConfig
          true, // skipInit
          '0x', // initCode
        ]
      ),
      futureGenericAddress
    );
  } else {
    hre.deployments.log('"HolographGeneric" is already deployed.');
  }
};

export default func;
func.tags = ['HolographGeneric', 'DeployGeneric'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
