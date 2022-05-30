declare var global: any;
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
  HolographRegistry,
  HolographRegistryProxy,
  HToken,
  Interfaces,
  MockERC721Receiver,
  Owner,
  PA1D,
  SampleERC20,
  SampleERC721,
  SecureStorage,
  SecureStorageProxy,
} from '../typechain-types';
import { DeploymentConfigStruct } from '../typechain-types/HolographFactory';

describe('Testing cross-chain minting (L1 & L2)', async function () {
  let l1: PreTest;
  let l2: PreTest;

  let totalNFTs: number = 2;
  let firstNFTl1: BigNumber = BigNumber.from(1);
  let firstNFTl2: BigNumber = BigNumber.from(1);
  let secondNFTl1: BigNumber = BigNumber.from(2);
  let secondNFTl2: BigNumber = BigNumber.from(2);
  let thirdNFTl1: BigNumber = BigNumber.from(3);
  let thirdNFTl2: BigNumber = BigNumber.from(3);

  let payloadThirdNFTl1: BytesLike;
  let payloadThirdNFTl2: BytesLike;

  let contractName: string = 'Sample ERC721 Contract ';
  let contractSymbol: string = 'SMPLR';
  const contractBps: number = 1000;
  const contractImage: string = '';
  const contractExternalLink: string = '';
  const tokenURIs: string[] = [
    'undefined',
    'https://holograph.xyz/sample1.json',
    'https://holograph.xyz/sample2.json',
    'https://holograph.xyz/sample3.json',
  ];
  // let l1ContractName = contractName + '(' + l1.hre.networkName + ')';
  // let l2ContractName = contractName + '(' + l2.hre.networkName + ')';

  before(async function () {
    l1 = await setup();
    l2 = await setup(true);

    firstNFTl2 = BigNumber.from('0x' + l2.network.holographId.toString(16).padStart(8, '0') + '00'.repeat(28)).add(
      firstNFTl1
    );
    secondNFTl2 = BigNumber.from('0x' + l2.network.holographId.toString(16).padStart(8, '0') + '00'.repeat(28)).add(
      secondNFTl1
    );
    thirdNFTl2 = BigNumber.from('0x' + l2.network.holographId.toString(16).padStart(8, '0') + '00'.repeat(28)).add(
      thirdNFTl1
    );

    payloadThirdNFTl1 =
      functionHash('erc721in(uint32,address,address,address,uint256,bytes)') +
      generateInitCode(
        ['uint32', 'address', 'address', 'address', 'uint256', 'bytes'],
        [
          l1.network.holographId,
          l1.sampleErc721Holographer.address,
          l1.deployer.address,
          l2.deployer.address,
          thirdNFTl1.toHexString(),
          generateInitCode(['bytes'], [hexToBytes(stringToHex(tokenURIs[3]))]),
        ]
      ).substring(2);

    payloadThirdNFTl2 =
      functionHash('erc721in(uint32,address,address,address,uint256,bytes)') +
      generateInitCode(
        ['uint32', 'address', 'address', 'address', 'uint256', 'bytes'],
        [
          l2.network.holographId,
          l1.sampleErc721Holographer.address,
          l2.deployer.address,
          l1.deployer.address,
          thirdNFTl2.toHexString(),
          generateInitCode(['bytes'], [hexToBytes(stringToHex(tokenURIs[3]))]),
        ]
      ).substring(2);
  });

  after(async function () {});

  beforeEach(async function () {});

  afterEach(async function () {});

  describe('Deploy cross-chain contracts via bridge deploy', async function () {
    describe('hToken', async function () {
      it('deploy l1 equivalent on l2', async function () {
        let { erc20Config, erc20ConfigHash, erc20ConfigHashBytes } = await generateErc20Config(
          l1.network,
          l1.deployer.address,
          'hToken',
          l1.network.tokenName + ' (Holographed)',
          'h' + l1.network.tokenSymbol,
          l1.network.tokenName + ' (Holographed)',
          '1',
          18,
          ConfigureEvents([]),
          generateInitCode(['address', 'uint16'], [l1.deployer.address, 0]),
          '0x' + '00'.repeat(32)
        );

        let hTokenErc20Address = await l2.registry.getHolographedHashAddress(erc20ConfigHash);

        expect(hTokenErc20Address).to.equal(zeroAddress());

        hTokenErc20Address = await l1.registry.getHolographedHashAddress(erc20ConfigHash);

        let sig = await l1.deployer.signMessage(erc20ConfigHashBytes);
        let signature: Signature = StrictECDSA({
          r: '0x' + sig.substring(2, 66),
          s: '0x' + sig.substring(66, 130),
          v: '0x' + sig.substring(130, 132),
        } as Signature);

        let payload: BytesLike =
          functionHash('deployIn(bytes)') +
          generateInitCode(
            ['bytes'],
            [
              generateInitCode(
                ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
                [
                  [
                    erc20Config.contractType,
                    erc20Config.chainType,
                    erc20Config.salt,
                    erc20Config.byteCode,
                    erc20Config.initCode,
                  ],
                  [signature.r, signature.s, signature.v],
                  l1.deployer.address,
                ]
              ),
            ]
          ).substring(2);

        await expect(l1.bridge.deployOut(l2.network.holographId, erc20Config, signature, l1.deployer.address))
          .to.emit(l1.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l2.network.holographId), l1.operator.address.toLowerCase(), payload);

        await expect(
          l2.operator
            .connect(l2.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l1.network.holographId), l1.operator.address, 0, payload)
        )
          .to.emit(l2.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(l2.operator.executeJob(payload))
          .to.emit(l2.factory, 'BridgeableContractDeployed')
          .withArgs(hTokenErc20Address, erc20ConfigHash);

        expect(await l2.registry.getHolographedHashAddress(erc20ConfigHash)).to.equal(hTokenErc20Address);
      });

      it('deploy l2 equivalent on l1', async function () {
        let { erc20Config, erc20ConfigHash, erc20ConfigHashBytes } = await generateErc20Config(
          l2.network,
          l2.deployer.address,
          'hToken',
          l2.network.tokenName + ' (Holographed)',
          'h' + l2.network.tokenSymbol,
          l2.network.tokenName + ' (Holographed)',
          '1',
          18,
          ConfigureEvents([]),
          generateInitCode(['address', 'uint16'], [l2.deployer.address, 0]),
          '0x' + '00'.repeat(32)
        );

        let hTokenErc20Address = await l1.registry.getHolographedHashAddress(erc20ConfigHash);

        expect(hTokenErc20Address).to.equal(zeroAddress());

        hTokenErc20Address = await l2.registry.getHolographedHashAddress(erc20ConfigHash);

        let sig = await l2.deployer.signMessage(erc20ConfigHashBytes);
        let signature: Signature = StrictECDSA({
          r: '0x' + sig.substring(2, 66),
          s: '0x' + sig.substring(66, 130),
          v: '0x' + sig.substring(130, 132),
        } as Signature);

        let payload: BytesLike =
          functionHash('deployIn(bytes)') +
          generateInitCode(
            ['bytes'],
            [
              generateInitCode(
                ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
                [
                  [
                    erc20Config.contractType,
                    erc20Config.chainType,
                    erc20Config.salt,
                    erc20Config.byteCode,
                    erc20Config.initCode,
                  ],
                  [signature.r, signature.s, signature.v],
                  l1.deployer.address,
                ]
              ),
            ]
          ).substring(2);

        await expect(l2.bridge.deployOut(l1.network.holographId, erc20Config, signature, l2.deployer.address))
          .to.emit(l2.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l1.network.holographId), l2.operator.address.toLowerCase(), payload);

        await expect(
          l1.operator
            .connect(l1.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l2.network.holographId), l2.operator.address, 0, payload)
        )
          .to.emit(l1.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(l1.operator.executeJob(payload))
          .to.emit(l1.factory, 'BridgeableContractDeployed')
          .withArgs(hTokenErc20Address, erc20ConfigHash);

        expect(await l1.registry.getHolographedHashAddress(erc20ConfigHash)).to.equal(hTokenErc20Address);
      });
    });

    describe('SampleERC20', async function () {
      it('deploy l1 equivalent on l2', async function () {
        let { erc20Config, erc20ConfigHash, erc20ConfigHashBytes } = await generateErc20Config(
          l1.network,
          l1.deployer.address,
          'SampleERC20',
          'Sample ERC20 Token (' + l1.hre.networkName + ')',
          'SMPL',
          'Sample ERC20 Token',
          '1',
          18,
          ConfigureEvents([HolographERC20Event.bridgeIn, HolographERC20Event.bridgeOut]),
          generateInitCode(['address', 'uint16'], [l1.deployer.address, 0]),
          '0x' + '00'.repeat(32)
        );

        let sampleErc20Address = await l2.registry.getHolographedHashAddress(erc20ConfigHash);

        expect(sampleErc20Address).to.equal(zeroAddress());

        sampleErc20Address = await l1.registry.getHolographedHashAddress(erc20ConfigHash);

        let sig = await l1.deployer.signMessage(erc20ConfigHashBytes);
        let signature: Signature = StrictECDSA({
          r: '0x' + sig.substring(2, 66),
          s: '0x' + sig.substring(66, 130),
          v: '0x' + sig.substring(130, 132),
        } as Signature);

        let payload: BytesLike =
          functionHash('deployIn(bytes)') +
          generateInitCode(
            ['bytes'],
            [
              generateInitCode(
                ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
                [
                  [
                    erc20Config.contractType,
                    erc20Config.chainType,
                    erc20Config.salt,
                    erc20Config.byteCode,
                    erc20Config.initCode,
                  ],
                  [signature.r, signature.s, signature.v],
                  l1.deployer.address,
                ]
              ),
            ]
          ).substring(2);

        await expect(l1.bridge.deployOut(l2.network.holographId, erc20Config, signature, l1.deployer.address))
          .to.emit(l1.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l2.network.holographId), l1.operator.address.toLowerCase(), payload);

        await expect(
          l2.operator
            .connect(l2.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l1.network.holographId), l1.operator.address, 0, payload)
        )
          .to.emit(l2.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(l2.operator.executeJob(payload))
          .to.emit(l2.factory, 'BridgeableContractDeployed')
          .withArgs(sampleErc20Address, erc20ConfigHash);

        expect(await l2.registry.getHolographedHashAddress(erc20ConfigHash)).to.equal(sampleErc20Address);
      });

      it('deploy l2 equivalent on l1', async function () {
        let { erc20Config, erc20ConfigHash, erc20ConfigHashBytes } = await generateErc20Config(
          l2.network,
          l2.deployer.address,
          'SampleERC20',
          'Sample ERC20 Token (' + l2.hre.networkName + ')',
          'SMPL',
          'Sample ERC20 Token',
          '1',
          18,
          ConfigureEvents([HolographERC20Event.bridgeIn, HolographERC20Event.bridgeOut]),
          generateInitCode(['address', 'uint16'], [l1.deployer.address, 0]),
          '0x' + '00'.repeat(32)
        );

        let sampleErc20Address = await l1.registry.getHolographedHashAddress(erc20ConfigHash);

        expect(sampleErc20Address).to.equal(zeroAddress());

        sampleErc20Address = await l2.registry.getHolographedHashAddress(erc20ConfigHash);

        let sig = await l2.deployer.signMessage(erc20ConfigHashBytes);
        let signature: Signature = StrictECDSA({
          r: '0x' + sig.substring(2, 66),
          s: '0x' + sig.substring(66, 130),
          v: '0x' + sig.substring(130, 132),
        } as Signature);

        let payload: BytesLike =
          functionHash('deployIn(bytes)') +
          generateInitCode(
            ['bytes'],
            [
              generateInitCode(
                ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
                [
                  [
                    erc20Config.contractType,
                    erc20Config.chainType,
                    erc20Config.salt,
                    erc20Config.byteCode,
                    erc20Config.initCode,
                  ],
                  [signature.r, signature.s, signature.v],
                  l1.deployer.address,
                ]
              ),
            ]
          ).substring(2);

        await expect(l2.bridge.deployOut(l1.network.holographId, erc20Config, signature, l2.deployer.address))
          .to.emit(l2.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l1.network.holographId), l2.operator.address.toLowerCase(), payload);

        await expect(
          l1.operator
            .connect(l1.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l2.network.holographId), l2.operator.address, 0, payload)
        )
          .to.emit(l1.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(l1.operator.executeJob(payload))
          .to.emit(l1.factory, 'BridgeableContractDeployed')
          .withArgs(sampleErc20Address, erc20ConfigHash);

        expect(await l1.registry.getHolographedHashAddress(erc20ConfigHash)).to.equal(sampleErc20Address);
      });
    });

    describe('SampleERC721', async function () {
      it('deploy l1 equivalent on l2', async function () {
        let { erc721Config, erc721ConfigHash, erc721ConfigHashBytes } = await generateErc721Config(
          l1.network,
          l1.deployer.address,
          'SampleERC721',
          'Sample ERC721 Contract (' + l1.hre.networkName + ')',
          'SMPLR',
          1000,
          ConfigureEvents([
            HolographERC721Event.bridgeIn,
            HolographERC721Event.bridgeOut,
            HolographERC721Event.afterBurn,
          ]),
          generateInitCode(['address'], [l1.deployer.address /*owner*/]),
          '0x' + '00'.repeat(32)
        );

        let sampleErc721Address = await l2.registry.getHolographedHashAddress(erc721ConfigHash);

        expect(sampleErc721Address).to.equal(zeroAddress());

        sampleErc721Address = await l1.registry.getHolographedHashAddress(erc721ConfigHash);

        let sig = await l1.deployer.signMessage(erc721ConfigHashBytes);
        let signature: Signature = StrictECDSA({
          r: '0x' + sig.substring(2, 66),
          s: '0x' + sig.substring(66, 130),
          v: '0x' + sig.substring(130, 132),
        } as Signature);

        let payload: BytesLike =
          functionHash('deployIn(bytes)') +
          generateInitCode(
            ['bytes'],
            [
              generateInitCode(
                ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
                [
                  [
                    erc721Config.contractType,
                    erc721Config.chainType,
                    erc721Config.salt,
                    erc721Config.byteCode,
                    erc721Config.initCode,
                  ],
                  [signature.r, signature.s, signature.v],
                  l1.deployer.address,
                ]
              ),
            ]
          ).substring(2);

        await expect(l1.bridge.deployOut(l2.network.holographId, erc721Config, signature, l1.deployer.address))
          .to.emit(l1.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l2.network.holographId), l1.operator.address.toLowerCase(), payload);

        await expect(
          l2.operator
            .connect(l2.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l1.network.holographId), l1.operator.address, 0, payload)
        )
          .to.emit(l2.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(l2.operator.executeJob(payload))
          .to.emit(l2.factory, 'BridgeableContractDeployed')
          .withArgs(sampleErc721Address, erc721ConfigHash);

        expect(await l2.registry.getHolographedHashAddress(erc721ConfigHash)).to.equal(sampleErc721Address);
      });

      it('deploy l2 equivalent on l1', async function () {
        let { erc721Config, erc721ConfigHash, erc721ConfigHashBytes } = await generateErc721Config(
          l2.network,
          l2.deployer.address,
          'SampleERC721',
          'Sample ERC721 Contract (' + l2.hre.networkName + ')',
          'SMPLR',
          1000,
          ConfigureEvents([
            HolographERC721Event.bridgeIn,
            HolographERC721Event.bridgeOut,
            HolographERC721Event.afterBurn,
          ]),
          generateInitCode(['address'], [l2.deployer.address /*owner*/]),
          '0x' + '00'.repeat(32)
        );

        let sampleErc721Address = await l1.registry.getHolographedHashAddress(erc721ConfigHash);

        expect(sampleErc721Address).to.equal(zeroAddress());

        sampleErc721Address = await l2.registry.getHolographedHashAddress(erc721ConfigHash);

        let sig = await l2.deployer.signMessage(erc721ConfigHashBytes);
        let signature: Signature = StrictECDSA({
          r: '0x' + sig.substring(2, 66),
          s: '0x' + sig.substring(66, 130),
          v: '0x' + sig.substring(130, 132),
        } as Signature);

        let payload: BytesLike =
          functionHash('deployIn(bytes)') +
          generateInitCode(
            ['bytes'],
            [
              generateInitCode(
                ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
                [
                  [
                    erc721Config.contractType,
                    erc721Config.chainType,
                    erc721Config.salt,
                    erc721Config.byteCode,
                    erc721Config.initCode,
                  ],
                  [signature.r, signature.s, signature.v],
                  l1.deployer.address,
                ]
              ),
            ]
          ).substring(2);

        await expect(l2.bridge.deployOut(l1.network.holographId, erc721Config, signature, l2.deployer.address))
          .to.emit(l2.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l1.network.holographId), l2.operator.address.toLowerCase(), payload);

        await expect(
          l1.operator
            .connect(l1.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l2.network.holographId), l2.operator.address, 0, payload)
        )
          .to.emit(l1.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(l1.operator.executeJob(payload))
          .to.emit(l1.factory, 'BridgeableContractDeployed')
          .withArgs(sampleErc721Address, erc721ConfigHash);

        expect(await l1.registry.getHolographedHashAddress(erc721ConfigHash)).to.equal(sampleErc721Address);
      });
    });

    describe('CxipERC721', async function () {
      it('deploy l1 equivalent on l2', async function () {
        let { erc721Config, erc721ConfigHash, erc721ConfigHashBytes } = await generateErc721Config(
          l1.network,
          l1.deployer.address,
          'CxipERC721',
          'CXIP ERC721 Collection (' + l1.hre.networkName + ')',
          'CXIP',
          1000,
          ConfigureEvents([
            HolographERC721Event.bridgeIn,
            HolographERC721Event.bridgeOut,
            HolographERC721Event.afterBurn,
          ]),
          generateInitCode(['address'], [l1.deployer.address /*owner*/]),
          '0x' + '00'.repeat(32)
        );

        let cxipErc721Address = await l2.registry.getHolographedHashAddress(erc721ConfigHash);

        expect(cxipErc721Address).to.equal(zeroAddress());

        cxipErc721Address = await l1.registry.getHolographedHashAddress(erc721ConfigHash);

        let sig = await l1.deployer.signMessage(erc721ConfigHashBytes);
        let signature: Signature = StrictECDSA({
          r: '0x' + sig.substring(2, 66),
          s: '0x' + sig.substring(66, 130),
          v: '0x' + sig.substring(130, 132),
        } as Signature);

        let payload: BytesLike =
          functionHash('deployIn(bytes)') +
          generateInitCode(
            ['bytes'],
            [
              generateInitCode(
                ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
                [
                  [
                    erc721Config.contractType,
                    erc721Config.chainType,
                    erc721Config.salt,
                    erc721Config.byteCode,
                    erc721Config.initCode,
                  ],
                  [signature.r, signature.s, signature.v],
                  l1.deployer.address,
                ]
              ),
            ]
          ).substring(2);

        await expect(l1.bridge.deployOut(l2.network.holographId, erc721Config, signature, l1.deployer.address))
          .to.emit(l1.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l2.network.holographId), l1.operator.address.toLowerCase(), payload);

        await expect(
          l2.operator
            .connect(l2.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l1.network.holographId), l1.operator.address, 0, payload)
        )
          .to.emit(l2.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(l2.operator.executeJob(payload))
          .to.emit(l2.factory, 'BridgeableContractDeployed')
          .withArgs(cxipErc721Address, erc721ConfigHash);

        expect(await l2.registry.getHolographedHashAddress(erc721ConfigHash)).to.equal(cxipErc721Address);
      });

      it('deploy l2 equivalent on l1', async function () {
        let { erc721Config, erc721ConfigHash, erc721ConfigHashBytes } = await generateErc721Config(
          l2.network,
          l2.deployer.address,
          'CxipERC721',
          'CXIP ERC721 Collection (' + l2.hre.networkName + ')',
          'CXIP',
          1000,
          ConfigureEvents([
            HolographERC721Event.bridgeIn,
            HolographERC721Event.bridgeOut,
            HolographERC721Event.afterBurn,
          ]),
          generateInitCode(['address'], [l2.deployer.address /*owner*/]),
          '0x' + '00'.repeat(32)
        );

        let cxipErc721Address = await l1.registry.getHolographedHashAddress(erc721ConfigHash);

        expect(cxipErc721Address).to.equal(zeroAddress());

        cxipErc721Address = await l2.registry.getHolographedHashAddress(erc721ConfigHash);

        let sig = await l2.deployer.signMessage(erc721ConfigHashBytes);
        let signature: Signature = StrictECDSA({
          r: '0x' + sig.substring(2, 66),
          s: '0x' + sig.substring(66, 130),
          v: '0x' + sig.substring(130, 132),
        } as Signature);

        let payload: BytesLike =
          functionHash('deployIn(bytes)') +
          generateInitCode(
            ['bytes'],
            [
              generateInitCode(
                ['tuple(bytes32,uint32,bytes32,bytes,bytes)', 'tuple(bytes32,bytes32,uint8)', 'address'],
                [
                  [
                    erc721Config.contractType,
                    erc721Config.chainType,
                    erc721Config.salt,
                    erc721Config.byteCode,
                    erc721Config.initCode,
                  ],
                  [signature.r, signature.s, signature.v],
                  l1.deployer.address,
                ]
              ),
            ]
          ).substring(2);

        await expect(l2.bridge.deployOut(l1.network.holographId, erc721Config, signature, l2.deployer.address))
          .to.emit(l2.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l1.network.holographId), l2.operator.address.toLowerCase(), payload);

        await expect(
          l1.operator
            .connect(l1.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l2.network.holographId), l2.operator.address, 0, payload)
        )
          .to.emit(l1.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(l1.operator.executeJob(payload))
          .to.emit(l1.factory, 'BridgeableContractDeployed')
          .withArgs(cxipErc721Address, erc721ConfigHash);

        expect(await l1.registry.getHolographedHashAddress(erc721ConfigHash)).to.equal(cxipErc721Address);
      });
    });
  });

  describe('SampleERC721', async function () {
    describe('check current state', async function () {
      it('l1 should have a total supply of 0 on l1', async function () {
        expect(await l1.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address).totalSupply()).to.equal(0);
      });

      it('l1 should have a total supply of 0 on l2', async function () {
        expect(await l2.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address).totalSupply()).to.equal(0);
      });

      it('l2 should have a total supply of 0 on l2', async function () {
        expect(await l2.sampleErc721Enforcer.attach(l2.sampleErc721Holographer.address).totalSupply()).to.equal(0);
      });

      it('l2 should have a total supply of 0 on l1', async function () {
        expect(await l1.sampleErc721Enforcer.attach(l2.sampleErc721Holographer.address).totalSupply()).to.equal(0);
      });
    });

    describe('validate mint functionality', async function () {
      it('l1 should mint token #1 as #1 on l1', async function () {
        await expect(
          l1.sampleErc721.attach(l1.sampleErc721Holographer.address).mint(l1.deployer.address, firstNFTl1, tokenURIs[1])
        )
          .to.emit(l1.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address), 'Transfer')
          .withArgs(zeroAddress(), l1.deployer.address, firstNFTl1);
      });

      it('l1 should mint token #1 not as #1 on l2', async function () {
        await expect(
          l2.sampleErc721.attach(l1.sampleErc721Holographer.address).mint(l1.deployer.address, firstNFTl1, tokenURIs[1])
        )
          .to.emit(l2.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address), 'Transfer')
          .withArgs(zeroAddress(), l1.deployer.address, firstNFTl2);
      });

      it('mint tokens #2 and #3 on l1 and l2', async function () {
        await expect(
          l1.sampleErc721
            .attach(l1.sampleErc721Holographer.address)
            .mint(l1.deployer.address, secondNFTl1, tokenURIs[2])
        )
          .to.emit(l1.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address), 'Transfer')
          .withArgs(zeroAddress(), l1.deployer.address, secondNFTl1);

        await expect(
          l2.sampleErc721
            .attach(l1.sampleErc721Holographer.address)
            .mint(l1.deployer.address, secondNFTl1, tokenURIs[2])
        )
          .to.emit(l2.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address), 'Transfer')
          .withArgs(zeroAddress(), l1.deployer.address, secondNFTl2);

        await expect(
          l1.sampleErc721.attach(l1.sampleErc721Holographer.address).mint(l1.deployer.address, thirdNFTl1, tokenURIs[3])
        )
          .to.emit(l1.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address), 'Transfer')
          .withArgs(zeroAddress(), l1.deployer.address, thirdNFTl1);

        await expect(
          l2.sampleErc721.attach(l1.sampleErc721Holographer.address).mint(l1.deployer.address, thirdNFTl1, tokenURIs[3])
        )
          .to.emit(l2.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address), 'Transfer')
          .withArgs(zeroAddress(), l1.deployer.address, thirdNFTl2);
      });
    });

    describe('validate bridge functionality', async function () {
      it('token #3 bridge out on l1 should succeed', async function () {
        let payload: BytesLike = payloadThirdNFTl1;

        await expect(
          l1.bridge.erc721out(
            l2.network.holographId,
            l1.sampleErc721Holographer.address,
            l1.deployer.address,
            l2.deployer.address,
            thirdNFTl1
          )
        )
          .to.emit(l1.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l2.network.holographId), l1.operator.address.toLowerCase(), payload);

        await expect(
          l2.operator
            .connect(l2.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l1.network.holographId), l1.operator.address, 0, payload)
        )
          .to.emit(l2.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(
          l1.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address).ownerOf(thirdNFTl1)
        ).to.be.revertedWith('ERC721: token does not exist');
      });

      it('token #3 bridge out on l2 should succeed', async function () {
        let payload: BytesLike = payloadThirdNFTl2;

        await expect(
          l2.bridge.erc721out(
            l1.network.holographId,
            l1.sampleErc721Holographer.address,
            l2.deployer.address,
            l1.deployer.address,
            thirdNFTl2
          )
        )
          .to.emit(l2.operator, 'LzEvent')
          .withArgs(ChainId.hlg2lz(l1.network.holographId), l2.operator.address.toLowerCase(), payload);

        await expect(
          l1.operator
            .connect(l1.lzEndpoint)
            .lzReceive(ChainId.hlg2lz(l2.network.holographId), l2.operator.address, 0, payload)
        )
          .to.emit(l1.operator, 'AvailableJob')
          .withArgs(payload);

        await expect(
          l2.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address).ownerOf(thirdNFTl2)
        ).to.be.revertedWith('ERC721: token does not exist');
      });

      it('token #3 bridge in on l2 should succeed', async function () {
        let payload: BytesLike = payloadThirdNFTl1;

        await expect(l2.operator.executeJob(payload))
          .to.emit(l2.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address), 'Transfer')
          .withArgs(l2.bridge.address, l2.deployer.address, thirdNFTl1.toHexString());

        expect(await l2.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address).ownerOf(thirdNFTl1)).to.equal(
          l2.deployer.address
        );
      });

      it('token #3 bridge in on l1 should succeed', async function () {
        let payload: BytesLike = payloadThirdNFTl2;

        await expect(l1.operator.executeJob(payload))
          .to.emit(l1.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address), 'Transfer')
          .withArgs(l1.bridge.address, l1.deployer.address, thirdNFTl2.toHexString());

        expect(await l1.sampleErc721Enforcer.attach(l1.sampleErc721Holographer.address).ownerOf(thirdNFTl2)).to.equal(
          l1.deployer.address
        );
      });

      it('bridge out token #3 bridge out on l1 should fail', async function () {
        let payload: BytesLike = payloadThirdNFTl1;

        await expect(
          l1.bridge.erc721out(
            l2.network.holographId,
            l1.sampleErc721Holographer.address,
            l1.deployer.address,
            l2.deployer.address,
            thirdNFTl1
          )
        ).to.be.revertedWith("HOLOGRAPH: token doesn't exist");
      });

      it('bridge out token #3 bridge out on l2 should fail', async function () {
        let payload: BytesLike = payloadThirdNFTl2;

        await expect(
          l2.bridge.erc721out(
            l1.network.holographId,
            l1.sampleErc721Holographer.address,
            l2.deployer.address,
            l1.deployer.address,
            thirdNFTl2
          )
        ).to.be.revertedWith("HOLOGRAPH: token doesn't exist");
      });

      it('bridged in token #3 bridge in on l2 should fail', async function () {
        let payload: BytesLike = payloadThirdNFTl1;

        await expect(l2.operator.executeJob(payload)).to.be.revertedWith('HOLOGRAPH: invalid job');
      });

      it('bridged in token #3 bridge in on l1 should fail', async function () {
        let payload: BytesLike = payloadThirdNFTl2;

        await expect(l1.operator.executeJob(payload)).to.be.revertedWith('HOLOGRAPH: invalid job');
      });
    });
  });
});
