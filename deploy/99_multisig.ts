declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';
import { hreSplit, txParams } from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { NetworkType, Network, networks } from '@holographxyz/networks';
import { Environment, getEnvironment } from '@holographxyz/environment';

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

  global.__txNonce = {} as { [key: string]: number };
  global.__txNonce[hre.networkName] = await hre.ethers.provider.getTransactionCount(deployer.address);

  const network: Network = networks[hre.networkName];

  const environment: Environment = getEnvironment();

  if (
    (network.type == NetworkType.mainnet || network.type == NetworkType.testnet) &&
    (environment == Environment.mainnet || environment == Environment.testnet)
  ) {
    let useDeployer: boolean = false;
    if (network.protocolMultisig === undefined) {
      useDeployer = true;
    }
    const MULTI_SIG: string = useDeployer
      ? deployer.address.toLowerCase()
      : (network.protocolMultisig as string).toLowerCase();

    const switchToHolograph: string[] = [
      'HolographBridgeProxy',
      'HolographFactoryProxy',
      'HolographInterfaces',
      'HolographOperatorProxy',
      'HolographRegistryProxy',
      'HolographTreasuryProxy',
      'LayerZeroModule',
    ];

    const holograph = await hre.ethers.getContract('Holograph', deployer);

    if ((await holograph.getAdmin()).toLowerCase() !== MULTI_SIG) {
      let setHolographAdminTx = await MultisigAwareTx(
        hre,
        deployer,
        'Holograph',
        holograph,
        await holograph.populateTransaction.setAdmin(MULTI_SIG, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.setAdmin(MULTI_SIG),
          })),
        })
      );
      hre.deployments.log(`Changing Holograph Admin tx ${setHolographAdminTx.hash}`);
      await setHolographAdminTx.wait();
      hre.deployments.log('Changed Holograph Admin');
    }

    for (const contractName of switchToHolograph) {
      const contract = await hre.ethers.getContract(contractName, deployer);
      if ((await contract.getAdmin()).toLowerCase() !== holograph.address.toLowerCase()) {
        let setHolographAsAdminTx = await MultisigAwareTx(
          hre,
          deployer,
          contractName,
          contract,
          await contract.populateTransaction.setAdmin(holograph.address, {
            ...(await txParams({
              hre,
              from: deployer,
              to: contract,
              data: contract.populateTransaction.setAdmin(holograph.address),
            })),
          })
        );
        hre.deployments.log(`Changing ${contractName} Admin to Holograph tx ${setHolographAsAdminTx.hash}`);
        await setHolographAsAdminTx.wait();
        hre.deployments.log(`Changed ${contractName} Admin to Holograph`);
      }
    }
  } else {
    hre.deployments.log(`Skipping multisig setup for ${NetworkType[network.type]}`);
  }
};
export default func;
func.tags = ['MultiSig'];
func.dependencies = [];
