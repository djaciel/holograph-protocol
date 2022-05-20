import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import { genesisDeployHelper, generateInitCode } from '../scripts/utils/helpers';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // this is purposefully left empty, and is a placeholder for future use
};

export default func;
func.tags = ['DeployERC1155'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
