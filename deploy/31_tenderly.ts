declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { NetworkType, networks } from '@holographxyz/networks';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';

// ts-ignore because this is not a hardhat plugin
import { tenderly } from 'hardhat';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const currentNetworkType: NetworkType = networks[hre.network.name].type;

  if (currentNetworkType != NetworkType.local) {
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
      let contract: string = contracts[i];
      const contractAddress = await (await hre.deployments.get(contract)).address;

      try {
        console.log(contract, contractAddress);
        await tenderly.verify({
          address: contractAddress,
          name: contract,
        });
      } catch (error) {
        hre.deployments.log(`Failed to run tenderly verify ""${contract}" -> ${error}`);
      }
    }
  } else {
    hre.deployments.log('Not verifying contracts on localhost networks.');
  }
};
export default func;
func.tags = ['Tenderly'];
func.dependencies = [];
