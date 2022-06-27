declare var global: any;
import fs from 'fs';
import { BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import { LeanHardhatRuntimeEnvironment, hreSplit, zeroAddress } from '../scripts/utils/helpers';
import networks from '../config/networks';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const salt = hre.deploymentSalt;

  let lzEndpoint = networks[hre.networkName].lzEndpoint;
  if (lzEndpoint == zeroAddress()) {
    lzEndpoint = (await hre.getNamedAccounts()).lzEndpoint;
    const mockLZEndpoint = await deploy('MockLZEndpoint', {
      from: lzEndpoint,
      args: [],
      log: true,
      waitConfirmations: 1,
      nonce: await hre.ethers.provider.getTransactionCount(lzEndpoint),
    });
    lzEndpoint = mockLZEndpoint.address;
  }

  const error = function (err: string) {
    hre.deployments.log(err);
    process.exit();
  };

  const holographOperatorProxy = await hre.ethers.getContract('HolographOperatorProxy');
  const holographOperator = ((await hre.ethers.getContract('HolographOperator')) as Contract).attach(
    holographOperatorProxy.address
  );

  if ((await holographOperator.getLZEndpoint()) != lzEndpoint) {
    const lzTx = await holographOperator
      .setLZEndpoint(lzEndpoint, { nonce: await hre.ethers.provider.getTransactionCount(deployer) })
      .catch(error);
    hre.deployments.log('Transaction hash:', lzTx.hash);
    await lzTx.wait();
    hre.deployments.log(`Registered lzEndpoint to: ${await holographOperator.getLZEndpoint()}`);
  } else {
    hre.deployments.log(`lzEndpoint is already registered to: ${await holographOperator.getLZEndpoint()}`);
  }
};

export default func;
func.tags = ['MockLZEndpoint', 'LayerZero'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
