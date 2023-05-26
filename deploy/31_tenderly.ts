declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { NetworkType, Networks, networks } from '@holographxyz/networks';
import { tenderly } from 'hardhat';

function mapShortKeyToFullKey(networks: Networks, shortKey: string) {
  for (let key in networks) {
    if (networks[key]?.shortKey === shortKey) {
      return key;
    }
  }
  throw new Error(`Network with shortKey '${shortKey}' not found`);
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  hre.network.name = mapShortKeyToFullKey(networks, hre.network.name);

  const currentNetworkType: NetworkType = networks[hre.network.name].type;
  if (currentNetworkType == NetworkType.local) {
    hre.deployments.log('Not verifying contracts on localhost networks.');
    return;
  }

  let contracts: string[] = [
    'HolographUtilityToken',
    'hToken',
    'Holograph',
    'HolographBridge',
    'HolographBridgeProxy',
    'Holographer',
    'HolographERC20',
    'HolographERC721',
    'HolographDropERC721',
    'HolographDropERC721Proxy',
    'HolographFactory',
    'HolographFactoryProxy',
    'HolographGeneric',
    'HolographGenesis',
    'HolographOperator',
    'HolographOperatorProxy',
    'HolographRegistry',
    'HolographRegistryProxy',
    'HolographTreasury',
    'HolographTreasuryProxy',
    'HolographInterfaces',
    'HolographRoyalties',
    'CxipERC721',
    'CxipERC721Proxy',
    'Faucet',
    'LayerZeroModule',
    'EditionsMetadataRenderer',
    'EditionsMetadataRendererProxy',
    'OVM_GasPriceOracle',
  ];

  hre.deployments.log('Verifying contracts on Tenderly...');
  for (let i: number = 0, l: number = contracts.length; i < l; i++) {
    try {
      let contract: string = contracts[i];
      const contractAddress = await (await hre.deployments.get(contract)).address;
      console.log(contract, contractAddress);
      await tenderly.verify({
        address: contractAddress,
        name: contract,
      });
    } catch (error) {
      hre.deployments.log(`Failed to run tenderly verify -> ${error}`);
    }
  }
};

export default func;
func.tags = ['Tenderly'];
func.dependencies = [];
