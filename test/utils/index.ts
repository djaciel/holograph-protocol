import fs from 'fs';
import { expect, assert } from 'chai';
import { ethers, artifacts, deployments } from 'hardhat';
import { Artifacts, HardhatRuntimeEnvironment } from 'hardhat/types';
import Web3 from 'web3';
import { BigNumberish, BytesLike, ContractFactory, Contract } from 'ethers';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {
  CxipERC721,
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
  HolographRegistry,
  HolographRegistryProxy,
  HToken,
  MockERC721Receiver,
  PA1D,
  SampleERC20,
  SampleERC721,
  SecureStorage,
  SecureStorageProxy,
} from '../../typechain-types';
import { utf8ToBytes32, ZERO_ADDRESS, sha256, getHolographedContractHash, generateInitCode } from '../../scripts/utils/helpers';

const hre: HardhatRuntimeEnvironment = require('hardhat');
const networks: Networks = JSON.parse(fs.readFileSync('./config/networks.json', 'utf8')) as Networks;
const network: Network = networks[hre.network.name];
const web3 = new Web3();
const chainId = '0x' + network.holographId.toString(16).padStart(8, '0');

export interface Network {
  chain: number;
  rpc: string;
  holographId: number;
  tokenName: string;
  tokenSymbol: string;
};

export interface Networks {
  [key: string]: Network;
};

export interface PreTest {
  hre: HardhatRuntimeEnvironment;
  artifacts: Artifacts;
  networks: Networks;
  network: Network;
  web3: Web3;
  chainId: BytesLike;
  deployer: SignerWithAddress;
  wallet1: SignerWithAddress;
  wallet2: SignerWithAddress;
  wallet3: SignerWithAddress;
  wallet4: SignerWithAddress;
  wallet5: SignerWithAddress;
  wallet6: SignerWithAddress;
  wallet7: SignerWithAddress;
  wallet8: SignerWithAddress;
  wallet9: SignerWithAddress;
  wallet10: SignerWithAddress;
  cxipErc721: CxipERC721;
  erc20Mock: ERC20Mock;
  holograph: Holograph;
  holographBridge: HolographBridge;
  holographBridgeProxy: HolographBridgeProxy;
  holographer: Holographer;
  holographErc20: HolographERC20;
  holographErc721: HolographERC721;
  holographFactory: HolographFactory;
  holographFactoryProxy: HolographFactoryProxy;
  holographGenesis: HolographGenesis;
  holographRegistry: HolographRegistry;
  holographRegistryProxy: HolographRegistryProxy;
  hToken: HToken;
  mockErc721Receiver: MockERC721Receiver;
  pa1d: PA1D;
  sampleErc20: SampleERC20;
  sampleErc721: SampleERC721;
  secureStorage: SecureStorage;
  secureStorageProxy: SecureStorageProxy;
  registry: HolographRegistry;
  factory: HolographFactory;
  bridge: HolographBridge;
  hTokenHolographer: Holographer;
  hTokenEnforcer: HolographERC20;
  sampleErc20Holographer: Holographer;
  sampleErc20Enforcer: HolographERC20;
  sampleErc721Holographer: Holographer;
  sampleErc721Enforcer: HolographERC721;
  cxipErc721Holographer: Holographer;
  cxipErc721Enforcer: HolographERC721;
};

export default async function(): Promise<PreTest> {
  await deployments.fixture([
    'HolographGenesis',
    'HolographRegistry',
    'HolographRegistryProxy',
    'SecureStorage',
    'SecureStorageProxy',
    'HolographFactory',
    'HolographFactoryProxy',
    'HolographBridge',
    'HolographBridgeProxy',
    'Holograph',
    'PA1D',
    'HolographERC20',
    'HolographERC721',
    'ERC20Mock',
    'MockERC721Receiver',
    'RegisterTemplates',
    'hToken',
    'SampleERC20',
    'SampleERC721',
    'CxipERC721'
  ]);

  const accounts = await ethers.getSigners();
  const deployer: SignerWithAddress = accounts[0];
  const wallet1: SignerWithAddress = accounts[1];
  const wallet2: SignerWithAddress = accounts[2];
  const wallet3: SignerWithAddress = accounts[3];
  const wallet4: SignerWithAddress = accounts[4];
  const wallet5: SignerWithAddress = accounts[5];
  const wallet6: SignerWithAddress = accounts[6];
  const wallet7: SignerWithAddress = accounts[7];
  const wallet8: SignerWithAddress = accounts[8];
  const wallet9: SignerWithAddress = accounts[9];
  const wallet10: SignerWithAddress = accounts[10];

  let cxipErc721: CxipERC721;
  let erc20Mock: ERC20Mock;
  let holograph: Holograph;
  let holographBridge: HolographBridge;
  let holographBridgeProxy: HolographBridgeProxy;
  let holographer: Holographer;
  let holographErc20: HolographERC20;
  let holographErc721: HolographERC721;
  let holographFactory: HolographFactory;
  let holographFactoryProxy: HolographFactoryProxy;
  let holographGenesis: HolographGenesis;
  let holographRegistry: HolographRegistry;
  let holographRegistryProxy: HolographRegistryProxy;
  let hToken: HToken;
  let mockErc721Receiver: MockERC721Receiver;
  let pa1d: PA1D;
  let sampleErc20: SampleERC20;
  let sampleErc721: SampleERC721;
  let secureStorage: SecureStorage;
  let secureStorageProxy: SecureStorageProxy;

  let registry: HolographRegistry;
  let factory: HolographFactory;
  let bridge: HolographBridge;

  let hTokenHolographer: Holographer;
  let hTokenEnforcer: HolographERC20;
  let sampleErc20Holographer: Holographer;
  let sampleErc20Enforcer: HolographERC20;
  let sampleErc721Holographer: Holographer;
  let sampleErc721Enforcer: HolographERC721;
  let cxipErc721Holographer: Holographer;
  let cxipErc721Enforcer: HolographERC721;

  let hTokenHash: BytesLike;
  let sampleErc20Hash: BytesLike;
  let sampleErc721Hash: BytesLike;
  let cxipErc721Hash: BytesLike;

  cxipErc721 = (await ethers.getContractOrNull('CxipERC721')) as CxipERC721;
  erc20Mock = (await ethers.getContract('ERC20Mock')) as ERC20Mock;
  holograph = (await ethers.getContract('Holograph')) as Holograph;
  holographBridge = (await ethers.getContract('HolographBridge')) as HolographBridge;
  holographBridgeProxy = (await ethers.getContract('HolographBridgeProxy')) as HolographBridgeProxy;
  // holographer = (await ethers.getContractOrNull('Holographer')) as Holographer;
  holographErc20 = (await ethers.getContract('HolographERC20')) as HolographERC20;
  holographErc721 = (await ethers.getContract('HolographERC721')) as HolographERC721;
  holographFactory = (await ethers.getContract('HolographFactory')) as HolographFactory;
  holographFactoryProxy = (await ethers.getContract('HolographFactoryProxy')) as HolographFactoryProxy;
  holographGenesis = (await ethers.getContract('HolographGenesis')) as HolographGenesis;
  holographRegistry = (await ethers.getContract('HolographRegistry')) as HolographRegistry;
  holographRegistryProxy = (await ethers.getContract('HolographRegistryProxy')) as HolographRegistryProxy;
  // hToken = (await ethers.getContractOrNull('hToken')) as HToken;
  mockErc721Receiver = (await ethers.getContract('MockERC721Receiver')) as MockERC721Receiver;
  pa1d = (await ethers.getContract('PA1D')) as PA1D;
  // sampleErc20 = (await ethers.getContractOrNull('SampleERC20')) as SampleERC20;
  // sampleErc721 = (await ethers.getContractOrNull('SampleERC721')) as SampleERC721;
  secureStorage = (await ethers.getContract('SecureStorage')) as SecureStorage;
  secureStorageProxy = (await ethers.getContract('SecureStorageProxy')) as SecureStorageProxy;

  bridge = holographBridge.attach(await holograph.getBridge()) as HolographBridge;
  factory = holographFactory.attach(await holograph.getFactory()) as HolographFactory;
  registry = holographRegistry.attach(await holograph.getRegistry()) as HolographRegistry;

  holographer = (await ethers.getContractAt('Holographer', await registry.getHToken(chainId))) as Holographer;

  hTokenHash = await getHolographedContractHash(
    deployer.address,
    'hToken', // contractName
    'HolographERC20', // contractType
    chainId, // chainId
    '0x' + '00'.repeat(32), // salt
    generateInitCode(
      ['string', 'string', 'uint8', 'uint256', 'bytes'],
      [
        network.tokenName + ' (Holographed)', // string memory contractName
        'h' + network.tokenSymbol, // string memory contractSymbol
        18, // uint8 contractDecimals
        '0x' + '00'.repeat(32), // uint256 eventConfig
        generateInitCode(
          ['address', 'uint16'],
          [
            deployer.address, // owner
            0, // fee (bps)
          ]
        )
      ]
    )
  );
  hTokenHolographer = (await ethers.getContractAt('Holographer', await registry.getHolographedHashAddress(hTokenHash))) as Holographer;
  hTokenEnforcer = (await ethers.getContractAt('HolographERC20', await hTokenHolographer.getHolographEnforcer())) as HolographERC20;
  hToken = (await ethers.getContractAt('hToken', await hTokenHolographer.getSourceContract())) as HToken;

  sampleErc20Hash = await getHolographedContractHash(
    deployer.address,
    'SampleERC20', // contractName
    'HolographERC20', // contractType
    chainId, // chainId
    '0x' + '00'.repeat(32), // salt
    generateInitCode(
      ['string', 'string', 'uint8', 'uint256', 'bytes'],
      [
        'Sample ERC20 Token', // string memory contractName
        'SMPL', // string memory contractSymbol
        18, // uint8 contractDecimals
        '0x' + '00'.repeat(32), // uint256 eventConfig
        generateInitCode(
          ['address', 'uint16'],
          [
            deployer.address, // owner
            0, // fee (bps)
          ]
        )
      ]
    )
  );
  sampleErc20Holographer = (await ethers.getContractAt('Holographer', await registry.getHolographedHashAddress(sampleErc20Hash))) as Holographer;
  sampleErc20Enforcer = (await ethers.getContractAt('HolographERC20', await sampleErc20Holographer.getHolographEnforcer())) as HolographERC20;
  sampleErc20 = (await ethers.getContractAt('SampleERC20', await sampleErc20Holographer.getSourceContract())) as SampleERC20;

  sampleErc721Hash = await getHolographedContractHash(
    deployer.address,
    'SampleERC721', // contractName
    'HolographERC721', // contractType
    chainId, // chainId
    '0x' + '00'.repeat(32), // salt
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'bytes'],
      [
        'Sample ERC721 Contract', // string memory contractName
        'SMPLR', // string memory contractSymbol
        1000, // uint16 contractBps
        '0x' + '00'.repeat(32), // uint256 eventConfig
        generateInitCode(
          ['address'],
          [
            deployer.address // owner
          ]
        )
      ]
    )
  );
  sampleErc721Holographer = (await ethers.getContractAt('Holographer', await registry.getHolographedHashAddress(sampleErc721Hash))) as Holographer;
  sampleErc721Enforcer = (await ethers.getContractAt('HolographERC721', await sampleErc721Holographer.getHolographEnforcer())) as HolographERC721;
  sampleErc721 = (await ethers.getContractAt('SampleERC721', await sampleErc721Holographer.getSourceContract())) as SampleERC721;

  cxipErc721Hash = await getHolographedContractHash(
    deployer.address,
    'CxipERC721', // contractName
    'HolographERC721', // contractType
    chainId, // chainId
    '0x' + '00'.repeat(32), // salt
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'bytes'],
      [
        'CXIP ERC721 Collection', // string memory contractName
        'CXIP', // string memory contractSymbol
        1000, // uint16 contractBps
        '0x' + '00'.repeat(32), // uint256 eventConfig
        generateInitCode(
          ['address'],
          [
            deployer.address // owner
          ]
        )
      ]
    )
  );
  cxipErc721Holographer = (await ethers.getContractAt('Holographer', await registry.getHolographedHashAddress(cxipErc721Hash))) as Holographer;
  cxipErc721Enforcer = (await ethers.getContractAt('HolographERC721', await cxipErc721Holographer.getHolographEnforcer())) as HolographERC721;
  cxipErc721 = (await ethers.getContractAt('CxipERC721', await cxipErc721Holographer.getSourceContract())) as CxipERC721;

  return {
    hre,
    artifacts,
    networks,
    network,
    web3,
    chainId,
    deployer,
    wallet1,
    wallet2,
    wallet3,
    wallet4,
    wallet5,
    wallet6,
    wallet7,
    wallet8,
    wallet9,
    wallet10,
    cxipErc721,
    erc20Mock,
    holograph,
    holographBridge,
    holographBridgeProxy,
    holographer,
    holographErc20,
    holographErc721,
    holographFactory,
    holographFactoryProxy,
    holographGenesis,
    holographRegistry,
    holographRegistryProxy,
    hToken,
    mockErc721Receiver,
    pa1d,
    sampleErc20,
    sampleErc721,
    secureStorage,
    secureStorageProxy,
    registry,
    factory,
    bridge,
    hTokenHolographer,
    hTokenEnforcer,
    sampleErc20Holographer,
    sampleErc20Enforcer,
    sampleErc721Holographer,
    sampleErc721Enforcer,
    cxipErc721Holographer,
    cxipErc721Enforcer
  } as PreTest;

};
