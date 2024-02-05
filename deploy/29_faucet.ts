declare var global: any;
import path from 'path';

import { Contract, BigNumber } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {
  hreSplit,
  genesisDeployHelper,
  genesisDeriveFutureAddress,
  generateErc20Config,
  generateInitCode,
  txParams,
  getDeployer,
} from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { HolographERC20Event, ConfigureEvents } from '../scripts/utils/events';
import { NetworkType, networks } from '@holographxyz/networks';
import { Environment, getEnvironment } from '@holographxyz/environment';

const ONE_MILLION_TOKENS = '1000000000000000000000000'; // 1 million tokens denominated in wei

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  console.log(`Starting deploy script: ${path.basename(__filename)} 👇`);

  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const deployer = await getDeployer(hre);
  const deployerAddress = await deployer.signer.getAddress();
  const network = networks[hre.networkName];

  const environment: Environment = getEnvironment();

  const salt = hre.deploymentSalt;

  const holograph = await hre.ethers.getContract('Holograph', deployerAddress);
  const hlgTokenAddress = await holograph.getUtilityToken();

  const currentNetworkType: NetworkType = network.type;

  if (currentNetworkType == NetworkType.testnet || currentNetworkType == NetworkType.local) {
    // Only deploy faucet on develop environment
    if (environment != Environment.mainnet && environment != Environment.testnet) {
      const hlgContract = (await hre.ethers.getContract('HolographERC20', deployerAddress)).attach(hlgTokenAddress);

      const futureFaucetAddress = await genesisDeriveFutureAddress(
        hre,
        salt,
        'Faucet',
        generateInitCode(['address', 'address'], [deployerAddress, hlgTokenAddress])
      );
      hre.deployments.log('the future "Faucet" address is', futureFaucetAddress);

      // Faucet
      let faucetDeployedCode: string = await hre.provider.send('eth_getCode', [futureFaucetAddress, 'latest']);
      if (faucetDeployedCode == '0x' || faucetDeployedCode == '') {
        hre.deployments.log('"Faucet" bytecode not found, need to deploy"');
        let faucet = await genesisDeployHelper(
          hre,
          salt,
          'Faucet',
          generateInitCode(['address', 'address'], [deployerAddress, hlgTokenAddress]),
          futureFaucetAddress
        );
        const hlgContract = (await hre.ethers.getContract('HolographERC20', deployerAddress)).attach(hlgTokenAddress);
        const transferTx = await MultisigAwareTx(
          hre,
          'HolographUtilityToken',
          hlgContract,
          await hlgContract.populateTransaction.transfer(
            futureFaucetAddress,
            BigNumber.from('1' + '000' + '000' + '000000000000000000'),
            {
              ...(await txParams({
                hre,
                from: deployerAddress,
                to: hlgContract,
                gasLimit: (
                  await hre.ethers.provider.estimateGas(
                    hlgContract.populateTransaction.transfer(
                      futureFaucetAddress,
                      BigNumber.from('1' + '000' + '000' + '000000000000000000')
                    )
                  )
                ).mul(BigNumber.from('2')),
              })),
            }
          )
        );
        await transferTx.wait();
      } else {
        hre.deployments.log('"Faucet" is already deployed.');
      }
      const faucetContract = await hre.ethers.getContract('Faucet', deployerAddress);
      if ((await faucetContract.token()) != hlgTokenAddress) {
        const tx = await MultisigAwareTx(
          hre,
          'Faucet',
          faucetContract,
          await faucetContract.populateTransaction.setToken(hlgTokenAddress, {
            ...(await txParams({
              hre,
              from: deployerAddress,
              to: faucetContract,
              data: faucetContract.populateTransaction.setToken(hlgTokenAddress),
            })),
          })
        );
        await tx.wait();
        hre.deployments.log('Updated HLG reference');
        hre.deployments.log('Transferring 1M HLG to faucet');
        const transferTx = await hlgContract.transfer(futureFaucetAddress, BigNumber.from(ONE_MILLION_TOKENS), {
          ...(await txParams({
            hre,
            from: deployerAddress,
            to: hlgContract,
            gasLimit: (
              await hre.ethers.provider.estimateGas(
                await hlgContract.populateTransaction.transfer(futureFaucetAddress, BigNumber.from(ONE_MILLION_TOKENS))
              )
            ).mul(BigNumber.from('2')),
          })),
        });
        const receipt = await transferTx.wait();
        hre.deployments.log(`Transfer tx hash: ${receipt.transactionHash}`);
      }
    }
  } else {
    hre.deployments.log(`Skipping faucet deployment on ${currentNetworkType} network`);
  }

  console.log(`Exiting script: ${__filename} ✅\n`);
};

export default func;
func.tags = ['Faucet'];
func.dependencies = ['SampleERC20'];
