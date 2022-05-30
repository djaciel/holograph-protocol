declare var global: any;
import { expect, assert } from 'chai';
import { PreTest } from './utils';
import setup from './utils';

describe('Validating the Holograph Protocol deployments (L1)', async () => {
  let l1: PreTest;

  before(async () => {
    l1 = await setup();
  });

  after(async () => {});

  beforeEach(async () => {});

  afterEach(async () => {});

  describe('Check that contract addresses are properly deployed', async () => {
    describe('Interfaces:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.interfaces.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('Interfaces')).deployedBytecode
        );
      });
    });

    describe('CxipERC721 Holographer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.cxipErc721Holographer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('Holographer')).deployedBytecode
        );
      });
    });

    describe('CxipERC721 Enforcer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.cxipErc721Enforcer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographERC721')).deployedBytecode
        );
      });
    });

    describe('CxipERC721:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.cxipErc721.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('CxipERC721')).deployedBytecode
        );
      });
    });

    describe('ERC20Mock:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.erc20Mock.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('ERC20Mock')).deployedBytecode
        );
      });
    });

    describe('Holograph:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holograph.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('Holograph')).deployedBytecode
        );
      });
    });

    describe('HolographBridge:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographBridge.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographBridge')).deployedBytecode
        );
      });
    });

    describe('HolographBridgeProxy:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographBridgeProxy.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographBridgeProxy')).deployedBytecode
        );
      });
    });

    describe('Holographer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('Holographer')).deployedBytecode
        );
      });
    });

    describe('HolographERC20:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographErc20.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographERC20')).deployedBytecode
        );
      });
    });

    describe('HolographERC721:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographErc721.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographERC721')).deployedBytecode
        );
      });
    });

    describe('HolographFactory:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographFactory.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographFactory')).deployedBytecode
        );
      });
    });

    describe('HolographFactoryProxy:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographFactoryProxy.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographFactoryProxy')).deployedBytecode
        );
      });
    });

    describe('HolographGenesis:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographGenesis.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographGenesis')).deployedBytecode
        );
      });
    });

    describe('HolographOperator:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographOperator.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographOperator')).deployedBytecode
        );
      });
    });

    describe('HolographOperatorProxy:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographOperatorProxy.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographOperatorProxy')).deployedBytecode
        );
      });
    });

    describe('HolographRegistry:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographRegistry.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographRegistry')).deployedBytecode
        );
      });
    });

    describe('HolographRegistryProxy:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.holographRegistryProxy.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographRegistryProxy')).deployedBytecode
        );
      });
    });

    describe('hToken Holographer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.hTokenHolographer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('Holographer')).deployedBytecode
        );
      });
    });

    describe('hToken Enforcer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.hTokenEnforcer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographERC20')).deployedBytecode
        );
      });
    });

    describe('hToken:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.hToken.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('hToken')).deployedBytecode
        );
      });
    });

    describe('MockERC721Receiver:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.mockErc721Receiver.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('MockERC721Receiver')).deployedBytecode
        );
      });
    });

    describe('PA1D:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.pa1d.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('PA1D')).deployedBytecode
        );
      });
    });

    describe('SampleERC20 Holographer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.sampleErc20Holographer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('Holographer')).deployedBytecode
        );
      });
    });

    describe('SampleERC20 Enforcer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.sampleErc20Enforcer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographERC20')).deployedBytecode
        );
      });
    });

    describe('SampleERC20:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.sampleErc20.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('SampleERC20')).deployedBytecode
        );
      });
    });

    describe('SampleERC721 Holographer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.sampleErc721Holographer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('Holographer')).deployedBytecode
        );
      });
    });

    describe('SampleERC721 Enforcer:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.sampleErc721Enforcer.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('HolographERC721')).deployedBytecode
        );
      });
    });

    describe('SampleERC721:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.sampleErc721.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('SampleERC721')).deployedBytecode
        );
      });
    });

    describe('SecureStorage:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.secureStorage.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('SecureStorage')).deployedBytecode
        );
      });
    });

    describe('SecureStorageProxy:', async function () {
      it('should return correct bytecode', async function () {
        expect(await l1.hre.provider.send('eth_getCode', [l1.secureStorageProxy.address])).to.equal(
          (await l1.hre.artifacts.readArtifact('SecureStorageProxy')).deployedBytecode
        );
      });
    });
  });
});
