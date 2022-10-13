declare var global: any;
import Web3 from 'web3';
import { AbiItem } from 'web3-utils';
import { expect, assert } from 'chai';
import { PreTest } from './utils';
import setup from './utils';
import { BigNumberish, BytesLike, BigNumber, ContractFactory } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {
  Signature,
  StrictECDSA,
  zeroAddress,
  functionHash,
  XOR,
  hexToBytes,
  stringToHex,
  buildDomainSeperator,
  randomHex,
  generateInitCode,
  generateErc20Config,
  generateErc721Config,
  LeanHardhatRuntimeEnvironment,
  getGasUsage,
  remove0x,
  KeyOf,
  executeJobGas,
  adminCall,
} from '../scripts/utils/helpers';
import {
  HolographERC20Event,
  HolographERC721Event,
  HolographERC1155Event,
  ConfigureEvents,
} from '../scripts/utils/events';
import ChainId from '../scripts/utils/chain';
import {
  Admin,
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
  HolographOperator,
  HolographRegistry,
  HolographRegistryProxy,
  HToken,
  HolographUtilityToken,
  HolographInterfaces,
  MockERC721Receiver,
  Owner,
  PA1D,
  SampleERC20,
  SampleERC721,
} from '../typechain-types';
import { DeploymentConfigStruct } from '../typechain-types/HolographFactory';

describe('Holograph Operator Contract', async () => {
  const GWEI: BigNumber = BigNumber.from('1000000000');
  const TESTGASLIMIT: BigNumber = BigNumber.from('10000000');
  const GASPRICE: BigNumber = BigNumber.from('1000000000');

  let l1: PreTest;
  let l2: PreTest;

  let HLGL1: HolographERC20;
  let HLGL2: HolographERC20;

  let mockOperator: HolographOperator;

  let wallets: KeyOf<PreTest>[];

  before(async function () {
    l1 = await setup();
    l2 = await setup(true);

    HLGL1 = await l1.holographErc20.attach(l1.utilityTokenHolographer.address);
    HLGL2 = await l2.holographErc20.attach(l2.utilityTokenHolographer.address);

    wallets = [
      'wallet1',
      'wallet2',
      'wallet3',
      'wallet4',
      'wallet5',
      'wallet6',
      'wallet7',
      'wallet8',
      'wallet9',
      'wallet10',
    ];
  });

  after(async () => {});

  beforeEach(async () => {});

  afterEach(async () => {});

  describe('constructor', async () => {
    it('should successfully deploy', async () => {
      let operatorFactory: ContractFactory = await l1.hre.ethers.getContractFactory('HolographOperator');
      mockOperator = (await operatorFactory.deploy()) as HolographOperator;
      await mockOperator.deployed();
      assert(mockOperator.address != zeroAddress, 'zero address');
      let deployedCode = await l1.hre.ethers.provider.getCode(mockOperator.address);
      assert(deployedCode != '0x' && deployedCode != '', 'code not deployed');
    });
  });

  describe('init()', async () => {
    it('should successfully be initialized once', async () => {
      let initPayload = generateInitCode(
        ['address', 'address', 'address', 'address', 'address'],
        [
          await l1.operator.getBridge(),
          await l1.operator.getHolograph(),
          await l1.operator.getInterfaces(),
          await l1.operator.getRegistry(),
          await l1.operator.getUtilityToken(),
        ]
      );
      let tx = await mockOperator.init(initPayload);
      await tx.wait();
      expect(await mockOperator.getBridge()).to.equal(await l1.operator.getBridge());
      expect(await mockOperator.getHolograph()).to.equal(await l1.operator.getHolograph());
      expect(await mockOperator.getInterfaces()).to.equal(await l1.operator.getInterfaces());
      expect(await mockOperator.getRegistry()).to.equal(await l1.operator.getRegistry());
      expect(await mockOperator.getUtilityToken()).to.equal(await l1.operator.getUtilityToken());
    });
    it('should fail if already initialized', async () => {
      let initPayload = generateInitCode(
        ['address', 'address', 'address', 'address', 'address'],
        [zeroAddress, zeroAddress, zeroAddress, zeroAddress, zeroAddress]
      );
      await expect(mockOperator.init(initPayload)).to.be.revertedWith('HOLOGRAPH: already initialized');
    });
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('executeJob()', async () => {
    it.skip('Should fail if job hash is not in in _operatorJobs', async () => {});
    it.skip('Should fail non-operator address tries to execute job', async () => {}); // NOTE: "HOLOGRAPH: operator has time" error
    it.skip('Should fail if there has been a gas spike', async () => {});
    it.skip('Should fail if fallback is invalid', async () => {}); // NOTE: "HOLOGRAPH: invalid fallback"
    it.skip('Should fail if there is not enough gas', async () => {});
  });

  describe(`crossChainMessage()`, async () => {
    it.skip('Should successfully allow messaging address to call fn', async () => {});
    it.skip('Should fail to allow deployer address to call fn', async () => {});
    it.skip('Should fail to allow owner address to call fn', async () => {});
    it.skip('Should fail to allow non-owner address to call fn', async () => {});
  });

  describe('jobEstimator()', async () => {
    it.skip('should return expected estimated value', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
    it.skip('should be payable', async () => {});
  });

  describe('send()', async () => {
    it.skip('should fail if `toChainId` provided a string', async () => {});
    it.skip('should fail if `toChainId` provided a value larger than uint32', async () => {});
  });

  describe('getJobDetails()', async () => {
    it.skip('should return expected operatorJob from valid jobHash', async () => {});
    it.skip('should return expected operatorJob from INVALID jobHash', async () => {});
  });

  describe('getTotalPods()', async () => {
    it.skip('should return expected number of pods', async () => {});
  });

  describe('getPodOperatorsLength()', async () => {
    it.skip('should fail if pod does not exist', async () => {});
    it.skip('should return expected pod length', async () => {});
  });

  describe('getPodOperators(pod)', async () => {
    it.skip('should return expected operators for a valid pod', async () => {});
    it.skip('should fail to return operators for an INVALID pod', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('getPodOperators(pod, index, length)', async () => {
    it.skip('should return expected operators for a valid pod', async () => {});
    it.skip('should fail to return operators for an INVALID pod', async () => {});
    it.skip('should fail if index out of bounds', async () => {});
    it.skip('should fail if length is out of bounds', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('getPodBondAmounts()', async () => {
    it.skip('should return expected base and current value', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('getBondedPod()', async () => {
    it.skip('should return expected _bondedOperators', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('topupUtilityToken()', async () => {
    it.skip('should fail if operator is bonded', async () => {});
    it.skip('successfully top up utility tokens', async () => {});
  });

  describe('bondUtilityToken()', async () => {
    it.skip('should fail if the operator is already bonded', async () => {});
    it.skip('Should fail if the provided bond amount is too low', async () => {});
    it.skip('should fail if the pod operator limit has been reached', async () => {});
    it.skip('should fail if the token transfer failed', async () => {});
    it.skip('should successfully allow bonding', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('unbondUtilityToken()', async () => {
    it.skip('should fail if the operator has not bonded', async () => {});
    it.skip('Should fail if operator address is a contract', async () => {});
    it.skip('should fail if sender is not the owner', async () => {});
    it.skip('should fail if the token transfer failed', async () => {});
    it.skip('should successfully allow unbonding', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe(`getMessagingModule()`, async () => {
    it.skip('Should return valid _messagingModuleSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('setMessagingModule()', async () => {
    it.skip('should allow admin to alter _messagingModuleSlot', async () => {});
    it.skip('should fail to allow owner to alter _messagingModuleSlot', async () => {});
    it.skip('should fail to allow non-owner to alter _messagingModuleSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe(`getBridge()`, async () => {
    it.skip('Should return valid _bridgeSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('setBridge()', async () => {
    it.skip('should allow admin to alter _bridgeSlot', async () => {});
    it.skip('should fail to allow owner to alter _bridgeSlot', async () => {});
    it.skip('should fail to allow non-owner to alter _bridgeSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe(`getHolograph()`, async () => {
    it.skip('Should return valid _holographSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('setHolograph()', async () => {
    it.skip('should allow admin to alter _holographSlot', async () => {});
    it.skip('should fail to allow owner to alter _holographSlot', async () => {});
    it.skip('should fail to allow non-owner to alter _holographSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe(`getInterfaces()`, async () => {
    it.skip('Should return valid _interfacesSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('setInterfaces()', async () => {
    it.skip('should allow admin to alter _interfacesSlot', async () => {});
    it.skip('should fail to allow owner to alter _interfacesSlot', async () => {});
    it.skip('should fail to allow non-owner to alter _interfacesSlot', async () => {});
  });

  describe(`getRegistry()`, async () => {
    it.skip('Should return valid _registrySlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('setRegistry()', async () => {
    it.skip('should allow admin to alter _registrySlot', async () => {});
    it.skip('should fail to allow owner to alter _registrySlot', async () => {});
    it.skip('should fail to allow non-owner to alter _registrySlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe(`getUtilityToken()`, async () => {
    it.skip('Should return valid _utilityTokenSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('setUtilityToken()', async () => {
    it.skip('should allow admin to alter _utilityTokenSlot', async () => {});
    it.skip('should fail to allow owner to alter _utilityTokenSlot', async () => {});
    it.skip('should fail to allow non-owner to alter _utilityTokenSlot', async () => {});
    it.skip('Should allow external contract to call fn', async () => {});
    it.skip('should fail to allow inherited contract to call fn', async () => {});
  });

  describe('_bridge()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_holograph()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_interfaces()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_messagingModule()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_registry()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_utilityToken()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_jobNonce()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_popOperator()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_getBaseBondAmount()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_getCurrentBondAmount()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_randomBlockHash()', async () => {
    it.skip('is private function', async () => {});
  });

  describe('_isContract()', async () => {
    it.skip('should not be callable from an external contract', async () => {});
  });
});
