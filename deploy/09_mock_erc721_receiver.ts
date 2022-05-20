import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const mockErc721Receiver = await deploy('MockERC721Receiver', {
    from: deployer,
    args: [],
    log: true,
  });
};
export default func;
func.tags = ['MockERC721Receiver'];
func.dependencies = ['HolographGenesis'];
