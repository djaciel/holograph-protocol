declare var global: any;
import fs from 'fs';
import Web3 from 'web3';
import { BigNumber, BytesLike } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  Admin,
  CxipERC721,
  CxipERC721Proxy,
  ERC20Mock,
  Holograph,
  HolographBridge,
  HolographBridgeProxy,
  Holographer,
  HolographERC20,
  HolographERC721,
  HolographFactory,
  HolographFactoryProxy,
  HolographGenesis,
  HolographOperator,
  HolographOperatorProxy,
  HolographRegistry,
  HolographRegistryProxy,
  HolographTreasury,
  HolographTreasuryProxy,
  HToken,
  HolographInterfaces,
  MockERC721Receiver,
  MockLZEndpoint,
  Owner,
  HolographRoyalties,
  SampleERC20,
  SampleERC721,
} from '../typechain-types';
import {
  genesisDeriveFutureAddress,
  genesisDeployHelper,
  generateInitCode,
  zeroAddress,
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  generateErc20Config,
  getHolographedContractHash,
  Signature,
  StrictECDSA,
  txParams,
} from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { reservedNamespaceHashes } from '../scripts/utils/reserved-namespaces';
import { HolographERC20Event, ConfigureEvents } from '../scripts/utils/events';
import { NetworkType, Network, networks } from '@holographxyz/networks';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';
import { Environment, getEnvironment } from '@holographxyz/environment';

import dotenv from 'dotenv';
dotenv.config();

const GWEI: BigNumber = BigNumber.from('1000000000');
const ZERO: BigNumber = BigNumber.from('0');

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const accounts = await hre.ethers.getSigners();
  let deployer: SignerWithAddress | SuperColdStorageSigner = accounts[0];

  const web3 = new Web3();
  const salt = hre.deploymentSalt;

  const futureTreasuryAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographTreasury',
    generateInitCode(['address', 'address', 'address', 'address'], [zeroAddress, zeroAddress, zeroAddress, zeroAddress])
  );
  hre.deployments.log('the future "HolographTreasury" address is', futureTreasuryAddress);

  // HolographTreasury
  let treasuryDeployedCode: string = await hre.provider.send('eth_getCode', [futureTreasuryAddress, 'latest']);
  if (treasuryDeployedCode == '0x' || treasuryDeployedCode == '') {
    hre.deployments.log('"HolographTreasury" bytecode not found, need to deploy"');
    let holographTreasury = await genesisDeployHelper(
      hre,
      salt,
      'HolographTreasury',
      generateInitCode(
        ['address', 'address', 'address', 'address'],
        [zeroAddress, zeroAddress, zeroAddress, zeroAddress]
      ),
      futureTreasuryAddress
    );
  } else {
    hre.deployments.log('"HolographTreasury" is already deployed.');
  }

  // Verify
  let contracts: string[] = ['HolographTreasury'];
  for (let i: number = 0, l: number = contracts.length; i < l; i++) {
    let contract: string = contracts[i];
    try {
      await hre1.run('verify:verify', {
        address: (await hre.ethers.getContract(contract)).address,
        constructorArguments: [],
      });
    } catch (error) {
      hre.deployments.log(`Failed to verify ""${contract}" -> ${error}`);
    }
  }
};

export default func;
func.tags = ['TEMP_TREASURY_UPGRADE'];
func.dependencies = [];

// NOTE: The example below is to deploy the contract via hardhat deploy using CREATE1 instead of deterministic CREATE2
// import { HardhatRuntimeEnvironment } from 'hardhat/types';
// import { DeployFunction } from 'hardhat-deploy/types';

// import {
//   genesisDeriveFutureAddress,
//   genesisDeployHelper,
//   generateInitCode,
//   zeroAddress,
//   LeanHardhatRuntimeEnvironment,
//   hreSplit,
//   generateErc20Config,
//   getHolographedContractHash,
//   Signature,
//   StrictECDSA,
//   txParams,
// } from '../scripts/utils/helpers';

// const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
//   const { ethers } = hre;
//   const [deployer] = await ethers.getSigners();

//   // Check if HolographTreasury is already deployed
//   let holographTreasuryFactory = await ethers.getContractFactory('HolographTreasury');
//   let holographTreasury;

//   try {
//     holographTreasury = await holographTreasuryFactory.deploy(zeroAddress, zeroAddress, zeroAddress, zeroAddress);
//     await holographTreasury.deployed();
//     console.log(`"HolographTreasury" deployed to: ${holographTreasury.address}`);
//   } catch (error) {
//     console.error(`Failed to deploy "HolographTreasury": ${error.message}`);
//   }

//   // Verify
//   let contracts: string[] = ['HolographTreasury'];
//   for (let contract of contracts) {
//     try {
//       await hre.run('verify:verify', {
//         address: (await ethers.getContract(contract)).address,
//         constructorArguments: [zeroAddress, zeroAddress, zeroAddress, zeroAddress],
//       });
//     } catch (error) {
//       console.error(`Failed to verify "${contract}" -> ${error}`);
//     }
//   }
// };

// export default func;
// func.tags = ['TEMP_TREASURY_UPGRADE'];
// func.dependencies = [];
