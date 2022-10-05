declare var global: any;
import fs from 'fs';
import Web3 from 'web3';
import { BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import networks from '../config/networks';
import { Network, NetworkType } from '../scripts/utils/helpers';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  generateInitCode,
  genesisDeriveFutureAddress,
  zeroAddress,
} from '../scripts/utils/helpers';
import { ConfigureEvents } from '../scripts/utils/events';
import { HolographInterfaces } from '../typechain-types';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const { deployer } = await hre.getNamedAccounts();

  const web3 = new Web3();

  const salt = hre.deploymentSalt;

  const error = function (err: string) {
    hre.deployments.log(err);
    process.exit();
  };

  const futureHolographInterfacesAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographInterfaces',
    generateInitCode(['address'], [zeroAddress()])
  );
  hre.deployments.log('the future "HolographInterfaces" address is', futureHolographInterfacesAddress);

  const holographInterfaces: HolographInterfaces = (await hre.ethers.getContractAt(
    'HolographInterfaces',
    futureHolographInterfacesAddress
  )) as HolographInterfaces;
  const network: Network = networks[hre.networkName];
  const networkType: NetworkType = network.type;
  const networkKeys: string[] = Object.keys(networks);
  const networkValues: Network[] = Object.values(networks);
  let supportedNetworkNames: string[] = [];
  let supportedNetworks: Network[] = [];
  let needToMap: number[][] = [];
  for (let i = 0, l = networkKeys.length; i < l; i++) {
    const key: string = networkKeys[i];
    const value: Network = networkValues[i];
    if (value.type == networkType) {
      supportedNetworkNames.push(key);
      supportedNetworks.push(value);
      if (value.holographId > 0) {
        let evm2hlg: number = (await holographInterfaces.getChainId(1, value.chain, 2)).toNumber();
        if (evm2hlg != value.holographId) {
          needToMap.push([1, value.chain, 2, value.holographId]);
        }
        let hlg2evm: number = (await holographInterfaces.getChainId(2, value.holographId, 1)).toNumber();
        if (hlg2evm != value.chain) {
          needToMap.push([2, value.holographId, 1, value.chain]);
        }
        if (value.lzId > 0) {
          let lz2hlg: number = (await holographInterfaces.getChainId(3, value.lzId, 2)).toNumber();
          if (lz2hlg != value.holographId) {
            needToMap.push([3, value.lzId, 2, value.holographId]);
          }
          let hlg2lz: number = (await holographInterfaces.getChainId(2, value.holographId, 3)).toNumber();
          if (hlg2lz != value.lzId) {
            needToMap.push([2, value.holographId, 3, value.lzId]);
          }
        }
      }
    }
  }
  if (needToMap.length == 0) {
    hre.deployments.log('HolographInterfaces supports all currently configured networks');
  } else {
    hre.deployments.log('HolographInterfaces needs to have some network support configured');
    hre.deployments.log(JSON.stringify(needToMap));
    let fromChainType: number[] = [];
    let fromChainId: number[] = [];
    let toChainType: number[] = [];
    let toChainId: number[] = [];
    for (let chainMap of needToMap) {
      fromChainType.push(chainMap[0]);
      fromChainId.push(chainMap[1]);
      toChainType.push(chainMap[2]);
      toChainId.push(chainMap[3]);
    }
    let tx = await holographInterfaces.updateChainIdMaps(fromChainType, fromChainId, toChainType, toChainId, {
      nonce: await hre.ethers.provider.getTransactionCount(deployer),
    });
    await tx.wait();
  }
};

export default func;
func.tags = ['ValidateInterfaces'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
