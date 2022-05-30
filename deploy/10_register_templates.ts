declare var global: any;
import fs from 'fs';
import { BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import { LeanHardhatRuntimeEnvironment, hreSplit } from '../scripts/utils/helpers';
import Web3 from 'web3';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const { deployer } = await hre.getNamedAccounts();

  const error = function (err: string) {
    hre.deployments.log(err);
    process.exit();
  };

  const web3 = new Web3();

  const holographRegistryProxy = await hre.ethers.getContract('HolographRegistryProxy');
  const holographRegistry = ((await hre.ethers.getContract('HolographRegistry')) as Contract).attach(
    holographRegistryProxy.address
  );

  const erc20 = await hre.ethers.getContract('HolographERC20');
  const erc721 = await hre.ethers.getContract('HolographERC721');
  const pa1d = await hre.ethers.getContract('PA1D');

  const erc721Hash = '0x' + web3.utils.asciiToHex('HolographERC721').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(erc721Hash)) != erc721.address) {
    const erc721Tx = await holographRegistry
      .setContractTypeAddress(erc721Hash, erc721.address, {
        nonce: await hre.ethers.provider.getTransactionCount(deployer),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', erc721Tx.hash);
    await erc721Tx.wait();
    hre.deployments.log(`Registered erc721 to: ${await holographRegistry.getContractTypeAddress(erc721Hash)}`);
  } else {
    hre.deployments.log('erc721 is already registered');
  }

  const erc20Hash = '0x' + web3.utils.asciiToHex('HolographERC20').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(erc20Hash)) != erc20.address) {
    const erc20Tx = await holographRegistry
      .setContractTypeAddress(erc20Hash, erc20.address, {
        nonce: await hre.ethers.provider.getTransactionCount(deployer),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', erc20Tx.hash);
    await erc20Tx.wait();
    hre.deployments.log(`Registered erc20 to: ${await holographRegistry.getContractTypeAddress(erc20Hash)}`);
  } else {
    hre.deployments.log('erc20 is already registered');
  }

  const pa1dHash = '0x' + web3.utils.asciiToHex('PA1D').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(pa1dHash)) != pa1d.address) {
    const pa1dTx = await holographRegistry
      .setContractTypeAddress(pa1dHash, pa1d.address, {
        nonce: await hre.ethers.provider.getTransactionCount(deployer),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', pa1dTx.hash);
    await pa1dTx.wait();
    hre.deployments.log(`Registered pa1d to: ${await holographRegistry.getContractTypeAddress(pa1dHash)}`);
  } else {
    hre.deployments.log('pa1d is already registered');
  }
};

export default func;
func.tags = ['RegisterTemplates'];
func.dependencies = ['HolographGenesis', 'DeploySources', 'DeployERC20', 'DeployERC721', 'DeployERC1155'];
