declare var global: any;
import { Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction, Deployment } from 'hardhat-deploy-holographed/types';
import { LeanHardhatRuntimeEnvironment, hreSplit } from '../scripts/utils/helpers';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const { artifacts, deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  let holographGenesisContract: Contract | null = await hre.ethers.getContractOrNull('HolographGenesis');
  let holographGenesisDeployment: Deployment | null = null;
  if (holographGenesisContract == null) {
    try {
      holographGenesisDeployment = await deployments.get('HolographGenesis');
    } catch (ex: any) {
      // we do nothing
    }
  }
  if (holographGenesisContract == null && holographGenesisDeployment == null) {
    let holographGenesis = await deploy('HolographGenesis', {
      from: deployer,
      args: [],
      log: true,
      waitConfirmations: 1,
      nonce: await hre.ethers.provider.getTransactionCount(deployer),
    });
  }
};

export default func;
func.tags = ['HolographGenesis'];
func.dependencies = [];
