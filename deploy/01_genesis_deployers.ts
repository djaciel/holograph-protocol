declare var global: any;
import { Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction, Deployment } from '@holographxyz/hardhat-deploy-holographed/types';
import { LeanHardhatRuntimeEnvironment, hreSplit, txParams } from '../scripts/utils/helpers';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const accounts = await hre.ethers.getSigners();
  let deployer: SignerWithAddress | SuperColdStorageSigner = accounts[0];

  if (global.__superColdStorage) {
    // address, domain, authorization, ca
    const coldStorage = global.__superColdStorage;
    deployer = new SuperColdStorageSigner(
      coldStorage.address,
      'https://' + coldStorage.domain,
      coldStorage.authorization,
      deployer.provider,
      coldStorage.ca
    );
  }

  let holographGenesis: Contract = await hre.ethers.getContract('HolographGenesis', deployer);

  if (!(await holographGenesis.isApprovedDeployer('0xa198FA5db682a2A828A90b42D3Cd938DAcc01ADE'))) {
    let tx = await holographGenesis.approveDeployer('0xa198FA5db682a2A828A90b42D3Cd938DAcc01ADE', true, {
      ...(await txParams({
        hre,
        from: deployer,
        to: holographGenesis,
        data: holographGenesis.populateTransaction.approveDeployer('0xa198FA5db682a2A828A90b42D3Cd938DAcc01ADE', true),
      })),
    });
    let receipt = await tx.wait();
  }
};

export default func;
func.tags = ['GenesisDeployers'];
func.dependencies = [];
