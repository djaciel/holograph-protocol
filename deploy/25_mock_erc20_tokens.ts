declare var global: any;
import { BigNumber } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { LeanHardhatRuntimeEnvironment, hreSplit, txParams } from '../scripts/utils/helpers';
import { NetworkType, networks } from '@holographxyz/networks';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const accounts = await hre.ethers.getSigners();
  let deployer: SignerWithAddress | SuperColdStorageSigner = accounts[0];

  if (global.__superColdStorage) {
    // address, domain, authorization, ca
    const coldStorage = global.__superColdStorage;
    deployer = new SuperColdStorageSigner(
      coldStorage.address,
      'https://' + coldStorage.domain,
      coldStorage.authorization,
      deployer.provider,
      coldStorage.ca
    );
  }

  const currentNetworkType: NetworkType = networks[hre.networkName].type;

  if (currentNetworkType == NetworkType.local) {
    const mockErc20Tokens = await hre.deployments.deploy('ERC20Mock', {
      ...(await txParams({
        hre,
        from: deployer,
        to: '0x0000000000000000000000000000000000000000',
        gasLimit: await hre.ethers.provider.estimateGas(
          (
            await hre.ethers.getContractFactory('ERC20Mock')
          ).getDeployTransaction('Wrapped ETH (MOCK)', 'WETHmock', 18, 'ERC20Mock', '1')
        ),
      })),
      args: ['Wrapped ETH (MOCK)', 'WETHmock', 18, 'ERC20Mock', '1'],
      log: true,
      waitConfirmations: 1,
    } as any);
  }
};

export default func;
func.tags = ['ERC20Mock', 'MockERC720Tokens'];
func.dependencies = ['HolographGenesis'];
