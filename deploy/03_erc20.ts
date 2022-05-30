declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  genesisDeployHelper,
  generateInitCode,
} from '../scripts/utils/helpers';
import { HolographERC20Event, ConfigureEvents } from '../scripts/utils/events';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const salt: string = '0x' + '00'.repeat(12);

  // HolographERC20
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
    )
  );
};

export default func;
func.tags = ['HolographERC20', 'DeployERC20'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
