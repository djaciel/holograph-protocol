declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  genesisDeployHelper,
  generateInitCode,
  genesisDeriveFutureAddress,
  zeroAddress,
  getGasPrice,
  getGasLimit,
} from '../scripts/utils/helpers';
import { HolographERC721Event, ConfigureEvents } from '../scripts/utils/events';
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
  const futureErc721DropAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographERC721Drop',
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'bool', 'bytes'],
      [
        'Holograph ERC721 Drop', // contractName
        'hNFT', // contractSymbol
        1000, // contractBps == 0%
        ConfigureEvents([]), // eventConfig
        true, // skipInit
        generateInitCode(['address'], [deployer.address]), // initCode -> Update this to use DropInitializer
      ]
    )
  );
  hre.deployments.log('the future "HolographERC721Drop" address is', futureErc721DropAddress);
  // HolographERC721Drop
  let erc721DropDeployedCode: string = await hre.provider.send('eth_getCode', [futureErc721DropAddress, 'latest']);
  if (erc721DropDeployedCode == '0x' || erc721DropDeployedCode == '') {
    hre.deployments.log('"HolographERC721Drop" bytecode not found, need to deploy"');
    let holographErc721Drop = await genesisDeployHelper(
      hre,
      salt,
      'HolographERC721Drop',
      generateInitCode(
        ['string', 'string', 'uint16', 'uint256', 'bool', 'bytes'],
        [
          'Holograph ERC721 Drop Collection', // contractName
          'hNFT', // contractSymbol
          1000, // contractBps == 0%
          ConfigureEvents([]), // eventConfig
          true, // skipInit
          generateInitCode(['tuple(string,uint256,address)'], [['string', 'uint256', 'address']]), // initCode
        ]
      ),
      futureErc721DropAddress
    );
  } else {
    hre.deployments.log('"HolographERC721Drop" is already deployed.');
  }
};

// export default func;
func.tags = ['HolographERC721', 'HolographERC721Drop', 'CxipERC721', 'DeployERC721'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
