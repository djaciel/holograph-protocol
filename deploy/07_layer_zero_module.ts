declare var global: any;
import { Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  genesisDeriveFutureAddress,
  genesisDeployHelper,
  generateInitCode,
  zeroAddress,
  LeanHardhatRuntimeEnvironment,
  hreSplit,
} from '../scripts/utils/helpers';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const error = function (err: string) {
    hre.deployments.log(err);
    process.exit();
  };

  const salt = hre.deploymentSalt;

  const holograph = await hre.ethers.getContract('Holograph');

  const futureLayerZeroModuleAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'LayerZeroModule',
    generateInitCode(['address', 'address', 'address'], [zeroAddress(), zeroAddress(), zeroAddress()])
  );
  hre.deployments.log('the future "LayerZeroModule" address is', futureLayerZeroModuleAddress);

  // LayerZeroModule
  let layerZeroModuleDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureLayerZeroModuleAddress,
    'latest',
  ]);
  if (layerZeroModuleDeployedCode == '0x' || layerZeroModuleDeployedCode == '') {
    hre.deployments.log('"LayerZeroModule" bytecode not found, need to deploy"');
    let layerZeroModule = await genesisDeployHelper(
      hre,
      salt,
      'LayerZeroModule',
      generateInitCode(
        ['address', 'address', 'address'],
        [await holograph.getBridge(), await holograph.getInterfaces(), await holograph.getOperator()]
      ),
      futureLayerZeroModuleAddress
    );
  } else {
    hre.deployments.log('"LayerZeroModule" is already deployed..');
  }

  const holographOperator = ((await hre.ethers.getContract('HolographOperator')) as Contract).attach(
    await holograph.getOperator()
  );

  if ((await holographOperator.getMessagingModule()).toLowerCase() != futureLayerZeroModuleAddress.toLowerCase()) {
    const lzTx = await holographOperator
      .setMessagingModule(futureLayerZeroModuleAddress, {
        nonce: await hre.ethers.provider.getTransactionCount(deployer),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', lzTx.hash);
    await lzTx.wait();
    hre.deployments.log(`Registered MessagingModule to: ${await holographOperator.getMessagingModule()}`);
  } else {
    hre.deployments.log(`MessagingModule is already registered to: ${await holographOperator.getMessagingModule()}`);
  }
};

export default func;
func.tags = ['LayerZeroModule'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
