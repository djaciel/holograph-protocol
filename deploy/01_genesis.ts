import { ethers } from 'hardhat';
import { Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction, Deployment } from 'hardhat-deploy-holographed/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { artifacts, deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  let holographGenesisContract: Contract | null = await ethers.getContractOrNull('HolographGenesis');
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
    });
  }
};

export default func;
func.tags = ['HolographGenesis'];
func.dependencies = [];
