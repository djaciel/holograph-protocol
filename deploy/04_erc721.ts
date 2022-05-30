declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  genesisDeployHelper,
  generateInitCode,
} from '../scripts/utils/helpers';
import { HolographERC721Event, ConfigureEvents } from '../scripts/utils/events';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const { getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  const salt: string = '0x' + '00'.repeat(12);

  // HolographERC20
  let holographErc721 = await genesisDeployHelper(
    hre,
    salt,
    'HolographERC721',
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'bool', 'bytes'],
      [
        'Holograph ERC721 Collection', // contractName
        'hNFT', // contractSymbol
        1000, // contractBps == 0%
        ConfigureEvents([]), // eventConfig
        true, // skipInit
        generateInitCode(['address'], [deployer]), // initCode
      ]
    )
  );
};

export default func;
func.tags = ['HolographERC721', 'DeployERC721'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
