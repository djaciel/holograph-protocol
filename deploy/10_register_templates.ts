import fs from 'fs';
import { ethers } from 'hardhat';
import { BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import Web3 from 'web3';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const error = function (err: string) {
    console.log(err);
    process.exit();
  };

  const web3 = new Web3();

  const holographRegistryProxy = await ethers.getContract('HolographRegistryProxy');
  const holographRegistry = ((await ethers.getContract('HolographRegistry')) as Contract).attach(
    holographRegistryProxy.address
  );

  const erc20 = await ethers.getContract('HolographERC20');
  const erc721 = await ethers.getContract('HolographERC721');
  const pa1d = await ethers.getContract('PA1D');

  const erc721Hash = '0x' + web3.utils.asciiToHex('HolographERC721').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(erc721Hash)) != erc721.address) {
    const erc721Tx = await holographRegistry.setContractTypeAddress(erc721Hash, erc721.address).catch(error);
    console.log('Transaction hash:', erc721Tx.hash);
    await erc721Tx.wait();
    console.log(`Registered erc721 to: ${await holographRegistry.getContractTypeAddress(erc721Hash)}`);
  } else {
    console.log('erc721 is already registered');
  }

  const erc20Hash = '0x' + web3.utils.asciiToHex('HolographERC20').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(erc20Hash)) != erc20.address) {
    const erc20Tx = await holographRegistry.setContractTypeAddress(erc20Hash, erc20.address).catch(error);
    console.log('Transaction hash:', erc20Tx.hash);
    await erc20Tx.wait();
    console.log(`Registered erc20 to: ${await holographRegistry.getContractTypeAddress(erc20Hash)}`);
  } else {
    console.log('erc20 is already registered');
  }

  const pa1dHash = '0x' + web3.utils.asciiToHex('PA1D').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(pa1dHash)) != pa1d.address) {
    const pa1dTx = await holographRegistry.setContractTypeAddress(pa1dHash, pa1d.address).catch(error);
    console.log('Transaction hash:', pa1dTx.hash);
    await pa1dTx.wait();
    console.log(`Registered pa1d to: ${await holographRegistry.getContractTypeAddress(pa1dHash)}`);
  } else {
    console.log('pa1d is already registered');
  }
};

export default func;
func.tags = ['RegisterTemplates'];
func.dependencies = ['HolographGenesis', 'DeploySources', 'DeployERC20', 'DeployERC721', 'DeployERC1155'];
