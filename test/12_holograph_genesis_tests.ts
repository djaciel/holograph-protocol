import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { generateInitCode, zeroAddress } from '../scripts/utils/helpers';

describe('Holograph Genesis Contract', async () => {
  let HolographGenesis: any;
  let holographGenesis: any;
  let HolographGenesisChild: any;
  let holographGenesisChild: any;
  let Mock: any;
  let mock: any;
  let accounts: SignerWithAddress[];
  let deployer: SignerWithAddress;
  let newDeployer: SignerWithAddress;
  let anotherNewDeployer: SignerWithAddress;
  let mockSigner: SignerWithAddress;

  before(async () => {
    accounts = await ethers.getSigners();
    deployer = accounts[0];
    newDeployer = accounts[1];
    anotherNewDeployer = accounts[2];

    HolographGenesis = await ethers.getContractFactory('HolographGenesis');
    holographGenesis = await HolographGenesis.deploy();
    await holographGenesis.deployed();

    HolographGenesisChild = await ethers.getContractFactory('MockHolographGenesisChild');
    holographGenesisChild = await HolographGenesisChild.deploy();
    await holographGenesisChild.deployed();

    Mock = await ethers.getContractFactory('Mock');
    mock = await Mock.deploy();
    await mock.deployed();

    mockSigner = await ethers.getSigner(mock.address);
  });

  describe('constructor', async () => {
    it('should successfully deploy', async () => {
      const holographGenesisAddress = holographGenesis.address;
      const events = await holographGenesis.queryFilter('Message');

      if (events[0].args) {
        expect(events[0].args[0]).to.equal('The future of NFTs is Holograph.');
      } else {
        throw new Error('No events found after deployment of HolographGenesis');
      }

      expect(holographGenesisAddress).to.not.equal(zeroAddress);
      expect(events.length).to.equal(1);
    });
  });

  describe('deploy()', async () => {
    it('should succeed in deploying a contract', async () => {
      const chainId = (await ethers.provider.getNetwork()).chainId;

      await expect(
        holographGenesis.deploy(
          chainId,
          // while running tests, keep in mind that the blockchain might retain some of this data
          // because of that, keep incrementing/alternating salts for same contract types
          `0x${'00'.repeat(11) + '01'}`,
          Mock.bytecode,
          generateInitCode(['bytes32'], ['0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd'])
        )
      ).to.not.be.reverted;
    });

    it('should fail if chainId is not this blockchains chainId', async () => {
      const chainId = (await ethers.provider.getNetwork()).chainId;

      await expect(
        holographGenesis.deploy(
          chainId + 1,
          `0x${'00'.repeat(11) + '01'}`,
          Mock.bytecode,
          generateInitCode(['bytes32'], ['0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd'])
        )
      ).to.revertedWith('HOLOGRAPH: incorrect chain id');
    });

    it('should fail if contract was already deployed', async () => {
      const chainId = (await ethers.provider.getNetwork()).chainId;
      await expect(
        holographGenesis.deploy(
          chainId,
          `0x${'00'.repeat(11) + '01'}`,
          Mock.bytecode,
          generateInitCode(['bytes32'], ['0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd'])
        )
      ).to.revertedWith('HOLOGRAPH: already deployed');
    });

    it('should fail if the deployment failed', async () => {
      const chainId = (await ethers.provider.getNetwork()).chainId;
      await expect(
        holographGenesis.deploy(
          chainId,
          `0x${'00'.repeat(11) + '02'}`, // incrementing salt with last byte
          '0x',
          generateInitCode(['bytes32'], ['0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd'])
        )
      ).to.revertedWith('HOLOGRAPH: deployment failed');
    });

    it.skip('should fail if contract init code does not match the init selector', async () => {
      const chainId = (await ethers.provider.getNetwork()).chainId;
      await expect(
        holographGenesisChild.deploy(chainId, `0x${'00'.repeat(11) + '03'}`, Mock.bytecode, '0x')
      ).to.revertedWith('HOLOGRAPH: init code does not match init selector');
    });
  });

  describe(`approveDeployer()`, async () => {
    it('Should allow deployer wallet to add to approved deployers', async () => {
      const tx = await holographGenesis.approveDeployer(newDeployer.address, true);
      await tx.wait();
      const isApprovedDeployer = await holographGenesis.isApprovedDeployer(newDeployer.address);
      expect(isApprovedDeployer).to.equal(true);
    });

    it('should fail non-deployer wallet to add approved deployers', async () => {
      await expect(holographGenesis.connect(mockSigner).approveDeployer(newDeployer.address, true)).to.be.revertedWith(
        'HOLOGRAPH: deployer not approved'
      );
    });

    it.skip('Should allow external contract to call fn', async () => {
      let tx = await holographGenesis.approveDeployer(mockSigner.address, true);
      await tx.wait();
      expect(await holographGenesis.isApprovedDeployer(mockSigner.address)).to.equal(true);
      expect(await holographGenesis.connect(mockSigner).approveDeployer(anotherNewDeployer.address, true)).to.equal(
        true
      );
    });

    it('should allow inherited contract to call fn', async () => {
      let tx = await holographGenesisChild.approveDeployer(newDeployer.address, true);
      await tx.wait();
      const isApprovedDeployer = await holographGenesisChild.isApprovedDeployer(newDeployer.address);
      expect(isApprovedDeployer).to.equal(true);
    });
  });

  describe(`isApprovedDeployer()`, async () => {
    it('Should return true to approved deployer wallet', async () => {
      const isApprovedDeployer = await holographGenesis.isApprovedDeployer(deployer.address);
      expect(isApprovedDeployer).to.equal(true);
    });

    it('Should return false to non-approved deployer wallet', async () => {
      const isApprovedDeployer = await holographGenesis.isApprovedDeployer(accounts[10].address);
      expect(isApprovedDeployer).to.equal(false);
    });

    it('Should allow external contract to call fn', async () => {
      const isApprovedDeployer = await holographGenesis.connect(mockSigner).isApprovedDeployer(deployer.address);
      expect(isApprovedDeployer).to.equal(true);
    });

    it('should allow inherited contract to call fn', async () => {
      const isApprovedDeployer = await holographGenesisChild.isApprovedDeployerMock(deployer.address);
      expect(isApprovedDeployer).to.equal(true);
    });
  });

  describe.skip('_isContract()', async () => {
    it('should not be callable from an external contract', async () => {
      await expect(holographGenesis.connect(mock.address)['_isContract'](deployer.address)).to.be.revertedWith('TODO');
    });
  });
});
