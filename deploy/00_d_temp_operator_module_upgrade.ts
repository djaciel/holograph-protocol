declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  genesisDeployHelper,
  generateInitCode,
  genesisDeriveFutureAddress,
  zeroAddress,
  getGasPrice,
  getGasLimit,
  txParams,
} from '../scripts/utils/helpers';
import { HolographERC721Event, ConfigureEvents } from '../scripts/utils/events';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import Web3 from 'web3';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const accounts = await hre.ethers.getSigners();
  let deployer: SignerWithAddress | SuperColdStorageSigner = accounts[0];

  const salt = hre.deploymentSalt;

  const web3 = new Web3();

  // HolographOperator
  const futureOperatorAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographOperator',
    generateInitCode(
      ['address', 'address', 'address', 'address', 'address', 'uint256'],
      [zeroAddress, zeroAddress, zeroAddress, zeroAddress, zeroAddress, '0x' + '00'.repeat(32)]
    )
  );
  hre.deployments.log('the future "HolographOperator" address is', futureOperatorAddress);

  let operatorDeployedCode: string = await hre.provider.send('eth_getCode', [futureOperatorAddress, 'latest']);
  if (operatorDeployedCode == '0x' || operatorDeployedCode == '') {
    hre.deployments.log('"HolographOperator" bytecode not found, need to deploy"');
    let holographOperator = await genesisDeployHelper(
      hre,
      salt,
      'HolographOperator',
      generateInitCode(
        ['address', 'address', 'address', 'address', 'address', 'uint256'],
        [zeroAddress, zeroAddress, zeroAddress, zeroAddress, zeroAddress, '0x' + '00'.repeat(32)]
      ),
      futureOperatorAddress
    );
  } else {
    hre.deployments.log('"HolographOperator" is already deployed.');
  }

  // Verify
  let contracts: string[] = ['HolographOperator'];
  for (let i: number = 0, l: number = contracts.length; i < l; i++) {
    let contract: string = contracts[i];
    try {
      await hre1.run('verify:verify', {
        address: (await hre.ethers.getContract(contract)).address,
        constructorArguments: [],
      });
    } catch (error) {
      hre.deployments.log(`Failed to verify ""${contract}" -> ${error}`);
    }
  }
};

export default func;
func.tags = ['TEMP_OPERATOR_UPGRADE'];
func.dependencies = [];
