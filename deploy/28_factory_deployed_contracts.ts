declare var global: any;
import { BigNumber, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Holographer, CxipERC721Proxy } from '../typechain-types';
import { hreSplit, txParams } from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
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

  const salt = hre.deploymentSalt;

  const currentNetworkType: NetworkType = networks[hre.networkName].type;

  if (currentNetworkType != NetworkType.local) {
    const holographer: Contract | null = await hre.ethers.getContractOrNull('Holographer', deployer);
    if (holographer == null) {
      await hre.deployments.deploy('Holographer', {
        ...(await txParams({
          hre,
          from: deployer,
          to: '0x0000000000000000000000000000000000000000',
          gasLimit: await hre.ethers.provider.estimateGas(
            (await hre.ethers.getContractFactory('Holographer')).getDeployTransaction()
          ),
        })),
        args: [],
        log: true,
        waitConfirmations: 1,
      });
      hre.deployments.log('Deployed a "Holographer" empty contract for block explorer verification purposes.');
    }

    const cxipERC721Proxy: Contract | null = await hre.ethers.getContractOrNull('CxipERC721Proxy', deployer);
    if (cxipERC721Proxy == null) {
      await hre.deployments.deploy('CxipERC721Proxy', {
        ...(await txParams({
          hre,
          from: deployer,
          to: '0x0000000000000000000000000000000000000000',
          gasLimit: await hre.ethers.provider.estimateGas(
            (await hre.ethers.getContractFactory('CxipERC721Proxy')).getDeployTransaction()
          ),
        })),
        args: [],
        log: true,
        waitConfirmations: 1,
      });
      hre.deployments.log('Deployed a "CxipERC721Proxy" empty contract for block explorer verification purposes.');
    }

    const holographDropERC721Proxy: Contract | null = await hre.ethers.getContractOrNull(
      'holographDropERC721Proxy',
      deployer
    );
    if (holographDropERC721Proxy == null) {
      await hre.deployments.deploy('HolographDropERC721Proxy', {
        ...(await txParams({
          hre,
          from: deployer,
          to: '0x0000000000000000000000000000000000000000',
          gasLimit: await hre.ethers.provider.estimateGas(
            (await hre.ethers.getContractFactory('HolographDropERC721Proxy')).getDeployTransaction()
          ),
        })),
        args: [],
        log: true,
        waitConfirmations: 1,
      });
      hre.deployments.log(
        'Deployed a "holographDropERC721Proxy" empty contract for block explorer verification purposes.'
      );
    }

    const holographUtilityToken: Contract | null = await hre.ethers.getContractOrNull(
      'HolographUtilityToken',
      deployer
    );
    if (holographUtilityToken == null) {
      await hre.deployments.deploy('HolographUtilityToken', {
        ...(await txParams({
          hre,
          from: deployer,
          to: '0x0000000000000000000000000000000000000000',
          gasLimit: await hre.ethers.provider.estimateGas(
            (await hre.ethers.getContractFactory('HolographUtilityToken')).getDeployTransaction()
          ),
        })),
        args: [],
        log: true,
        waitConfirmations: 1,
      });
      hre.deployments.log(
        'Deployed a "HolographUtilityToken" empty contract for block explorer verification purposes.'
      );
    }

    const hToken: Contract | null = await hre.ethers.getContractOrNull('hToken', deployer);
    if (hToken == null) {
      await hre.deployments.deploy('hToken', {
        ...(await txParams({
          hre,
          from: deployer,
          to: '0x0000000000000000000000000000000000000000',
          gasLimit: await hre.ethers.provider.estimateGas(
            (await hre.ethers.getContractFactory('hToken')).getDeployTransaction()
          ),
        })),
        args: [],
        log: true,
        waitConfirmations: 1,
      });
      hre.deployments.log('Deployed a "hToken" empty contract for block explorer verification purposes.');
    }
  }
};

export default func;
func.tags = [
  'Holographer4verify',
  'CxipERC721Proxy4verify',
  'HolographDropERC721Proxy4verify',
  'HolographUtilityToken4verify',
  'hToken4verify',
];
func.dependencies = [];
