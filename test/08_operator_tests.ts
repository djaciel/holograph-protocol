declare var global: any;
import Web3 from 'web3';
import { AbiItem } from 'web3-utils';
import { expect, assert } from 'chai';
import { PreTest } from './utils';
import setup from './utils';
import { BigNumberish, BytesLike, BigNumber, ContractFactory } from 'ethers';
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
} from '../scripts/utils/helpers';
import {
  HolographERC20Event,
  HolographERC721Event,
  HolographERC1155Event,
  ConfigureEvents,
  AllEventsEnabled,
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
  HolographRegistry,
  HolographRegistryProxy,
  HToken,
  Interfaces,
  MockERC721Receiver,
  Owner,
  PA1D,
  SampleERC20,
  SampleERC721,
} from '../typechain-types';
import { DeploymentConfigStruct } from '../typechain-types/HolographFactory';

describe('Testing Operator functionality (L1)', async function () {
  const lzReceiveABI = {
    inputs: [
      {
        internalType: 'uint16',
        name: '',
        type: 'uint16',
      },
      {
        internalType: 'bytes',
        name: '_srcAddress',
        type: 'bytes',
      },
      {
        internalType: 'uint64',
        name: '',
        type: 'uint64',
      },
      {
        internalType: 'bytes',
        name: '_payload',
        type: 'bytes',
      },
    ],
    name: 'lzReceive',
    outputs: [],
    stateMutability: 'payable',
    type: 'function',
  } as AbiItem;
  const lzReceive = function (web3: Web3, params: any[]): BytesLike {
    return web3.eth.abi.encodeFunctionCall(lzReceiveABI, params);
  };

  let l1: PreTest;

  before(async function () {
    l1 = await setup();
  });

  after(async function () {});

  beforeEach(async function () {});

  afterEach(async function () {});

  describe('Test Operator bonding', async function () {
    it('should fail bonding less than minimum', async function () {
      process.stdout.write('\n0 ' + (await l1.operator.getPodBondAmount(0)) + '\n');
      process.stdout.write('\n1 ' + (await l1.operator.getPodBondAmount(1)) + '\n');
      process.stdout.write('\n2 ' + (await l1.operator.getPodBondAmount(2)) + '\n');
      process.stdout.write('\n3 ' + (await l1.operator.getPodBondAmount(3)) + '\n');
      process.stdout.write('\n4 ' + (await l1.operator.getPodBondAmount(4)) + '\n');
      process.stdout.write('\n5 ' + (await l1.operator.getPodBondAmount(5)) + '\n');
      await expect(
        l1.operator.bondUtilityToken(l1.deployer.address, BigNumber.from('100000000000000000'), 0)
      ).to.be.revertedWith('HOLOGRAPH: bond amount too small');
      await expect(
        l1.operator.bondUtilityToken(l1.deployer.address, BigNumber.from('1000000000000000000'), 1)
      ).to.be.revertedWith('HOLOGRAPH: bond amount too small');
    });
    it('should bond to pod index 0', async function () {
      await expect(l1.operator.bondUtilityToken(l1.deployer.address, BigNumber.from('1000000000000000000'), 0)).to.not
        .be.reverted;
      expect(await l1.operator.getPodOperators(0)).to.deep.equal([zeroAddress(), l1.deployer.address]);
      // expect(await l1.operator.getPodOperators(1)).to.deep.equal([zeroAddress()]);
      // expect(await l1.operator.getPodOperators(2)).to.deep.equal([zeroAddress()]);
      // expect(await l1.operator.getPodOperators(3)).to.deep.equal([zeroAddress()]);
      await expect(l1.operator.getPodOperators(4)).to.be.reverted;
    });
    it('should bond 10 wallets to pods', async function () {
      await expect(l1.operator.bondUtilityToken(l1.wallet1.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet2.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet3.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet4.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet5.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet6.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet7.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet8.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet9.address, BigNumber.from('1000000000000000000'), 0)).to.not.be
        .reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet10.address, BigNumber.from('1000000000000000000'), 0)).to.not
        .be.reverted;
      for (let i = 0, l = 100; i < l; i++) {
        await l1.operator.bondUtilityToken(randomHex(20), BigNumber.from('1000000000000000000'), 0);
      }
      /*
      await expect(l1.operator.bondUtilityToken(l1.wallet1.address, BigNumber.from('1000000000000000000'), 0)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet2.address, BigNumber.from('1000000000000000000'), 0)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet3.address, BigNumber.from('4000000000000000000'), 1)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet4.address, BigNumber.from('4000000000000000000'), 1)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet5.address, BigNumber.from('16000000000000000000'), 2)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet6.address, BigNumber.from('16000000000000000000'), 2)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet7.address, BigNumber.from('64000000000000000000'), 3)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet8.address, BigNumber.from('64000000000000000000'), 3)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet9.address, BigNumber.from('4000000000000000000'), 1)).to.not.be.reverted;
      await expect(l1.operator.bondUtilityToken(l1.wallet10.address, BigNumber.from('4000000000000000000'), 1)).to.not.be.reverted;
*/
    });
    it('should fail double-bonding', async function () {
      await expect(
        l1.operator.bondUtilityToken(l1.deployer.address, BigNumber.from('4000000000000000000'), 1)
      ).to.be.revertedWith('HOLOGRAPH: operator is bonded');
    });
  });
  describe('Test new job generation', async function () {
    it('should choose an operator for a job', async function () {
      for (let i = 0, l = 20; i < l; i++) {
        let payload: BytesLike = randomHex(4) + randomHex(256, false);

        await expect(
          l1.mockLZEndpoint
            .connect(l1.lzEndpoint)
            .adminCall(
              l1.operator.address,
              lzReceive(l1.web3, [ChainId.hlg2lz(l1.network.holographId), l1.operator.address, 0, payload])
            )
        )
          .to.emit(l1.operator, 'AvailableOperatorJob')
          .withArgs(l1.web3.utils.keccak256(payload as string), payload);

        let blockNumber: number = await l1.hre.ethers.provider.getBlockNumber();
        let transactionHash = (await l1.hre.ethers.provider.getBlockWithTransactions(blockNumber)).transactions[0].hash;
        let transaction = await l1.hre.ethers.provider.getTransactionReceipt(transactionHash);
        let hash = transaction.logs[1].data.substring(0, 66);
        let jobArray = await l1.operator.getJobDetails(hash);
        let job = {
          pod: jobArray[0],
          blockTimes: jobArray[1],
          operator: jobArray[2],
          startBlock: jobArray[3].toNumber(),
          fallbackOperators: [
            jobArray[4][0].toNumber(),
            jobArray[4][1].toNumber(),
            jobArray[4][2].toNumber(),
            jobArray[4][3].toNumber(),
            jobArray[4][4].toNumber(),
          ],
        };
        process.stdout.write('\n\n' + JSON.stringify(job, undefined, 2) + '\n\n');
      }
    });
  });
});
