import { expect } from 'chai';
import { ethers } from 'hardhat';

import { HolographRoyalties, MockExternalCall, MockExternalCall__factory } from '../typechain-types';
import { functionHash, generateInitCode } from '../scripts/utils/helpers';
import setup, { PreTest } from './utils';
import {
  HOLOGRAPHER_ALREADY_INITIALIZED_ERROR_MSG,
  ROYALTIES_ONLY_OWNER_ERROR_MSG,
  ROYALTIES_ALREADY_INITIALIZED_ERROR_MSG,
} from './utils/error_constants';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import Web3 from 'web3';

describe('HolographRoyalties Contract', async function () {
  let royalties: HolographRoyalties;
  let l1: PreTest;
  let mockExternalCall: MockExternalCall;
  let owner: SignerWithAddress;
  let notOwner: SignerWithAddress;

  const createRandomAddress = () => ethers.Wallet.createRandom().address;

  let anyAddress = createRandomAddress();

  before(async function () {
    l1 = await setup();

    owner = l1.deployer;
    notOwner = l1.wallet1;

    royalties = l1.royalties.attach(l1.sampleErc721Holographer.address);

    const mockExternalCallFactory = await ethers.getContractFactory<MockExternalCall__factory>('MockExternalCall');
    mockExternalCall = await mockExternalCallFactory.deploy();
    await mockExternalCall.deployed();
  });

  async function testExternalCallToFunction(fnAbi: string, fnName: string, args: any[] = []) {
    const ABI = [fnAbi];
    const iface = new ethers.utils.Interface(ABI);
    const encodedFunctionData = iface.encodeFunctionData(fnName, args);

    await expect(mockExternalCall.connect(notOwner).callExternalFn(royalties.address, encodedFunctionData)).to.not.be
      .reverted;
  }

  describe('init()', async function () {
    it('should fail if already initialized', async function () {
      const initCode = generateInitCode(['address'], [l1.wallet2.address]);
      await expect(royalties.connect(owner).init(initCode)).to.be.revertedWith(
        HOLOGRAPHER_ALREADY_INITIALIZED_ERROR_MSG
      );
    });
  });

  describe('initHolographRoyalties()', () => {
    it('should fail be initialized twice', async function () {
      const initCode = generateInitCode(['address', 'uint256'], [l1.wallet2.address, '100']);

      await expect(royalties.connect(owner).initHolographRoyalties(initCode)).to.be.revertedWith(
        ROYALTIES_ALREADY_INITIALIZED_ERROR_MSG
      );
    });
  });

  describe('owner()', async function () {
    it('should return the correct owner address', async function () {
      const ownerAddress = await royalties.owner();
      expect(ownerAddress).to.equal(owner.address);
    });

    it('should fail when comparing to wrong address', async function () {
      const ownerAddress = await royalties.owner();
      expect(ownerAddress).to.not.equal(notOwner);
    });

    it('should allow external contract to call fn', async function () {
      await testExternalCallToFunction('function owner() external view returns (address)', 'owner');
    });
  });

  describe('isOwner()', async function () {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner).isOwner).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('isOwner');
    });
  });

  describe('_getDefaultReceiver()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._getDefaultReceiver).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_getDefaultReceiver');
    });
  });

  describe('_setDefaultReceiver()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._setDefaultReceiver).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_setDefaultReceiver');
    });
  });

  describe('_getDefaultBp()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._getDefaultBp).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_getDefaultBp');
    });
  });

  describe('_setDefaultBp()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._setDefaultBp).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_setDefaultBp');
    });
  });

  describe('_getReceiver()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._getReceiver).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_getReceiver');
    });
  });

  describe('_setReceiver()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._setReceiver).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_setReceiver');
    });
  });

  describe('_getBp()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._getBp).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_getBp');
    });
  });

  describe('_setBp()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._setBp).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_setBp');
    });
  });

  describe('_getPayoutAddresses()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._getPayoutAddresses).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_getPayoutAddresses');
    });
  });

  describe('_setPayoutAddresses()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._setPayoutAddresses).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_setPayoutAddresses');
    });
  });

  describe('_getPayoutBps()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._getPayoutBps).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_getPayoutBps');
    });
  });

  describe('_setPayoutBps()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._setPayoutBps).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_setPayoutBps');
    });
  });

  describe('_getTokenAddress()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._getTokenAddress).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_getTokenAddress');
    });
  });

  describe('_setTokenAddress()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._setTokenAddress).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_setTokenAddress');
    });
  });

  describe('_payoutEth()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._payoutEth).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_payoutEth');
    });
  });

  describe('_payoutToken()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._payoutToken).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_payoutToken');
    });
  });

  describe('_payoutTokens()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._payoutTokens).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_payoutTokens');
    });
  });

  describe('_validatePayoutRequestor()', () => {
    it('is private function', async function () {
      //@ts-ignore
      expect(typeof royalties.connect(owner)._validatePayoutRequestor).to.equal('undefined');
      expect(royalties.connect(owner)).to.not.have.keys('_validatePayoutRequestor');
    });
  });

  describe('configurePayouts', () => {
    it('should be callable by the owner', async () => {
      const addresses = [owner.address, mockExternalCall.address];
      const bps = [5000, 5000];

      let data = (await royalties.populateTransaction.configurePayouts(addresses, bps)).data || '';

      const tx = await l1.factory.connect(owner).adminCall(royalties.address, data);
      await tx.wait();

      const payoutInfo = await royalties.getPayoutInfo();

      expect(addresses).deep.equal(payoutInfo.addresses);
      expect(bps).deep.equal(payoutInfo.bps.map((bg) => bg.toNumber()));
    });

    it('should fail if the arguments arrays have different lenghts', async () => {
      const addresses = [anyAddress];
      const bps = [1000, 9000];

      let data = (await royalties.populateTransaction.configurePayouts(addresses, bps)).data || '';

      await expect(l1.factory.connect(owner).adminCall(royalties.address, data)).to.be.revertedWith(
        'ROYALTIES: missmatched lenghts'
      );
    });

    it("should fail if the bps down't equal 10000", async () => {
      const addresses = [anyAddress];
      const bps = [100];

      let data = (await royalties.populateTransaction.configurePayouts(addresses, bps)).data || '';

      await expect(l1.factory.connect(owner).adminCall(royalties.address, data)).to.be.revertedWith(
        'ROYALTIES: bps must equal 10000'
      );
    });

    it('should fail if it is not the owner calling it', async () => {
      await expect(royalties.connect(notOwner).configurePayouts([createRandomAddress()], [1000])).to.be.revertedWith(
        ROYALTIES_ONLY_OWNER_ERROR_MSG
      );
    });
  });

  describe('getPayoutInfo()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.getPayoutInfo()).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function getPayoutInfo() public view returns (address[] memory addresses, uint256[] memory bps)',
        'getPayoutInfo'
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('getEthPayout()', () => {
    it.skip('the owner should be able to call the fn', async () => {
      //TODO: wait for contract changes, if the contract balance is less than the gasCost it should revert with a error msg
      let data = (await royalties.populateTransaction.getEthPayout()).data || '';

      const tx = await l1.factory.connect(owner).adminCall(royalties.address, data);
      await tx.wait();
    });

    it.skip('A authorized address should be able to call the fn', async () => {
      //TODO: wait for contract changes, if the contract balance is less than the gasCost it should revert with a error msg
      await testExternalCallToFunction('function getEthPayout() public ', 'getEthPayout');
    });

    it('Should fail if sender is not authorized', async () => {
      await expect(royalties.connect(notOwner).getEthPayout()).to.be.revertedWith('ROYALTIES: sender not authorized');
    });
  });

  describe('getTokenPayout()', () => {
    it.skip('the owner should be able to call the fn', async () => {
      //TODO: wait for contract changes, if the contract balance is less than the gasCost it should revert with a error msg
      let data = (await royalties.populateTransaction.getTokenPayout(owner.address)).data || '';

      const tx = await l1.factory.connect(owner).adminCall(royalties.address, data);
      await tx.wait();
    });

    it.skip('A authorized address should be able to call the fn', async () => {
      //TODO: wait for contract changes, if the contract balance is less than the gasCost it should revert with a error msg
      await testExternalCallToFunction('function getTokenPayout(address tokenAddress) public', 'getTokenPayout', [
        mockExternalCall.address,
      ]);
    });

    it('Should fail if sender is not authorized', async () => {
      await expect(royalties.connect(notOwner).getEthPayout()).to.be.revertedWith('ROYALTIES: sender not authorized');
    });
  });

  describe('getTokensPayout()', () => {
    it.skip('the owner should be able to call the fn', async () => {
      //TODO: wait for contract changes, if the contract balance is less than the gasCost it should revert with a error msg
      let data = (await royalties.populateTransaction.getTokensPayout([owner.address])).data || '';

      const tx = await l1.factory.connect(owner).adminCall(royalties.address, data);
      await tx.wait();
    });

    it.skip('A authorized address should be able to call the fn', async () => {
      //TODO: wait for contract changes, if the contract balance is less than the gasCost it should revert with a error msg
      await testExternalCallToFunction(
        'function getTokensPayout(address[] memory tokenAddresses) public',
        'getTokensPayout',
        [[mockExternalCall.address]]
      );
    });

    it('Should fail if sender is not authorized', async () => {
      await expect(royalties.connect(notOwner).getTokenPayout(owner.address)).to.be.revertedWith(
        'ROYALTIES: sender not authorized'
      );
    });
  });

  describe('setRoyalties', () => {
    it('should be callable by the owner', async () => {});

    it('should fail if it is not the owner calling it', async () => {
      await expect(royalties.connect(notOwner).setRoyalties(1, createRandomAddress(), 1000)).to.be.revertedWith(
        ROYALTIES_ONLY_OWNER_ERROR_MSG
      );
    });
  });

  describe('royaltyInfo()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.royaltyInfo(1, 10)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function royaltyInfo(uint256 tokenId, uint256 value) public view returns (address, uint256)',
        'royaltyInfo',
        [1, 10]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('getFeeBps()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.getFeeBps(1)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function getFeeBps(uint256 tokenId) public view returns (uint256[] memory)',
        'getFeeBps',
        [1]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('getFeeRecipients()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.getFeeRecipients(1)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function getFeeRecipients(uint256 tokenId) public view returns (address[] memory)',
        'getFeeRecipients',
        [1]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('getRoyalties()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.getRoyalties(1)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function getRoyalties(uint256 tokenId) public view returns (address[] memory, uint256[] memory)',
        'getRoyalties',
        [1]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('getFees()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.getFees(1)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function getFees(uint256 tokenId) public view returns (address[] memory, uint256[] memory)',
        'getFees',
        [1]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('tokenCreator()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.tokenCreators(0)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function tokenCreators(uint256 tokenId) public view returns (address)',
        'tokenCreators',
        [0]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('calculateRoyaltyFee()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.calculateRoyaltyFee(createRandomAddress(), 1, 1)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function calculateRoyaltyFee(address, uint256 tokenId, uint256 amount) public view returns (uint256)',
        'calculateRoyaltyFee',
        [createRandomAddress(), 1, 1]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('marketContract()', () => {
    it('anyone should be able to call the fn', async () => {
      expect(await royalties.marketContract()).to.equal(royalties.address);
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction('function marketContract() public view returns (address)', 'marketContract');
    });

    it('should allow inherited contract to call fn');
  });

  describe('tokenCreators()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.tokenCreators(1)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function tokenCreators(uint256 tokenId) public view returns (address)',
        'tokenCreators',
        [1]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('bidSharesForToken()', () => {
    it('anyone should be able to call the fn', async () => {
      await expect(royalties.bidSharesForToken(0)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function bidSharesForToken(uint256 tokenId) public view returns (((uint256),(uint256),(uint256)) memory bidShares)',
        'bidSharesForToken',
        [0]
      );
    });

    it('should allow inherited contract to call fn');
  });

  describe('getTokenAddress()', () => {
    const tokenName = `Sample ERC721 Contract (${l1.network.holographId.toString()})`;

    it('anyone should be able to call the fn', async () => {
      await expect(royalties.getTokenAddress(tokenName)).to.not.be.reverted;
    });

    it('should allow external contract to call fn', async () => {
      await testExternalCallToFunction(
        'function getTokenAddress(string memory tokenName) public view returns (address)',
        'getTokenAddress',
        [tokenName]
      );
    });

    it('should allow inherited contract to call fn');
  });
});
