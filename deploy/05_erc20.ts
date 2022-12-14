declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  genesisDeployHelper,
  genesisDeriveFutureAddress,
  generateInitCode,
  getGasPrice,
  getGasLimit,
} from '../scripts/utils/helpers';
import { HolographERC20Event, ConfigureEvents } from '../scripts/utils/events';
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

  const futureErc20Address = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographERC20',
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'string', 'string', 'bool', 'bytes'],
      [
        'Holograph ERC20 Token', // contractName
        'HolographERC20', // contractSymbol
        18, // contractDecimals
        ConfigureEvents([]), // eventConfig
        'HolographERC20', // domainSeperator
        '1', // domainVersion
        true, // skipInit
        '0x', // initCode
      ]
    )
  );
  hre.deployments.log('the future "HolographERC20" address is', futureErc20Address);

  // HolographERC20
  let erc20DeployedCode: string = await hre.provider.send('eth_getCode', [futureErc20Address, 'latest']);
  if (erc20DeployedCode == '0x' || erc20DeployedCode == '') {
    hre.deployments.log('"HolographERC20" bytecode not found, need to deploy"');
    let holographErc20 = await genesisDeployHelper(
      hre,
      salt,
      'HolographERC20',
      generateInitCode(
        ['string', 'string', 'uint16', 'uint256', 'string', 'string', 'bool', 'bytes'],
        [
          'Holograph ERC20 Token', // contractName
          'HolographERC20', // contractSymbol
          18, // contractDecimals
          ConfigureEvents([]), // eventConfig
          'HolographERC20', // domainSeperator
          '1', // domainVersion
          true, // skipInit
          '0x', // initCode
        ]
      ),
      futureErc20Address
    );
  } else {
    hre.deployments.log('"HolographERC20" is already deployed.');
  }
};

export default func;
func.tags = ['HolographERC20', 'DeployERC20'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
