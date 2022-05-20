import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import { genesisDeployHelper, generateInitCode } from '../scripts/utils/helpers';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const salt: string = '0x' + '00'.repeat(12);

  // HolographERC20
  let holographErc721 = await genesisDeployHelper(
    hre,
    salt,
    'HolographERC721',
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'bytes'],
      [
        'Holograph ERC721 Collection', // contractName
        'hNFT', // contractSymbol
        1000, // contractBps == 0%
        0, // eventConfig
        '0x', // initCode
      ]
    )
  );
};

export default func;
func.tags = ['HolographERC721', 'DeployERC721'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
