import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;

  if (hre.network.name != 'localhost' && hre.network.name != 'localhost2') {
    let contracts: string[] = [
      'Holograph',
      'HolographBridge',
      'HolographBridgeProxy',
      'Holographer',
      'HolographERC20',
      'HolographERC721',
      'HolographFactory',
      'HolographFactoryProxy',
      'HolographOperator',
      'HolographOperatorProxy',
      'HolographRegistry',
      'HolographRegistryProxy',
      'HolographTreasury',
      'HolographTreasuryProxy',
      'Interfaces',
      'PA1D',
      'CxipERC721',
      'CxipERC721Proxy',
      'PA1D',
    ];
    for (let i: number = 0, l: number = contracts.length; i < l; i++) {
      let contract: string = contracts[i];
      try {
        await hre.run('verify:verify', {
          address: (await hre.ethers.getContract(contract)).address,
          constructorArguments: [],
        });
      } catch (error) {
        hre.deployments.log(`Failed to verify ""${contract}" -> ${error}`);
      }
    }
  } else {
    hre.deployments.log('Not verifying contracts on localhost networks.');
  }
};
export default func;
func.tags = ['Verify'];
func.dependencies = [];
