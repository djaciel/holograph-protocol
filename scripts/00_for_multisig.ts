declare var global: any;
import fs from 'fs';
import Web3 from 'web3';
import { BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  generateInitCode,
  genesisDeriveFutureAddress,
  zeroAddress,
  txParams,
} from '../scripts/utils/helpers';
import { ConfigureEvents } from '../scripts/utils/events';
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

  const web3 = new Web3();

  const salt = hre.deploymentSalt;

  const error = function (err: string) {
    hre.deployments.log(err);
    process.exit();
  };

  const holograph = await hre.ethers.getContract('Holograph', deployer);

  const holographRegistryProxy = await hre.ethers.getContract('HolographRegistryProxy', deployer);
  const holographRegistry = ((await hre.ethers.getContract('HolographRegistry', deployer)) as Contract).attach(
    holographRegistryProxy.address
  );

  const futureGenericAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographGeneric',
    generateInitCode(
      ['uint256', 'bool', 'bytes'],
      [
        ConfigureEvents([]), // eventConfig
        true, // skipInit
        '0x', // initCode
      ]
    )
  );
  hre.deployments.log('the future "HolographGeneric" address is', futureGenericAddress);

  const genericHash = '0x' + web3.utils.asciiToHex('HolographGeneric').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(genericHash)) != futureGenericAddress) {
    hre.deployments.log(
      `Need to register "HolographGeneric" with HolographRegistry: ${
        (await holographRegistry.populateTransaction.setContractTypeAddress(genericHash, futureGenericAddress)).data
      }`
    );
    hre.deployments.log(`"HolographGeneric" hash is: ${genericHash}`);
    const genericTx = await holograph
      .adminCall(
        holographRegistryProxy.address,
        (
          await holographRegistry.populateTransaction.setContractTypeAddress(genericHash, futureGenericAddress)
        ).data,
        {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.adminCall(
              holographRegistryProxy.address,
              (
                await holographRegistry.populateTransaction.setContractTypeAddress(genericHash, futureGenericAddress)
              ).data
            ),
          })),
        }
      )
      .catch(error);
    hre.deployments.log('Transaction hash:', genericTx.hash);
    await genericTx.wait();
    hre.deployments.log(
      `Registered "HolographGeneric" to: ${await holographRegistry.getContractTypeAddress(genericHash)}`
    );
  } else {
    hre.deployments.log('"HolographGeneric" is already registered');
  }

  const futureErc721Address = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographERC721',
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'bool', 'bytes'],
      [
        'Holograph ERC721 Collection', // contractName
        'hNFT', // contractSymbol
        1000, // contractBps == 0%
        ConfigureEvents([]), // eventConfig
        true, // skipInit
        generateInitCode(['address'], [deployer.address]), // initCode
      ]
    )
  );
  hre.deployments.log('the future "HolographERC721" address is', futureErc721Address);

  const erc721Hash = '0x' + web3.utils.asciiToHex('HolographERC721').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(erc721Hash)) != futureErc721Address) {
    hre.deployments.log(
      `Need to register "HolographERC721" with HolographRegistry: ${
        (await holographRegistry.populateTransaction.setContractTypeAddress(erc721Hash, futureErc721Address)).data
      }`
    );
    hre.deployments.log(`"HolographERC721" hash is: ${erc721Hash}`);
    const erc721Tx = await holograph
      .adminCall(
        holographRegistryProxy.address,
        (
          await holographRegistry.populateTransaction.setContractTypeAddress(erc721Hash, futureErc721Address)
        ).data,
        {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.adminCall(
              holographRegistryProxy.address,
              (
                await holographRegistry.populateTransaction.setContractTypeAddress(erc721Hash, futureErc721Address)
              ).data
            ),
          })),
        }
      )
      .catch(error);
    hre.deployments.log('Transaction hash:', erc721Tx.hash);
    await erc721Tx.wait();
    hre.deployments.log(
      `Registered "HolographERC721" to: ${await holographRegistry.getContractTypeAddress(erc721Hash)}`
    );
  } else {
    hre.deployments.log('"HolographERC721" is already registered');
  }

  const futureCxipErc721Address = await genesisDeriveFutureAddress(
    hre,
    salt,
    'CxipERC721',
    generateInitCode(['address'], [zeroAddress])
  );
  hre.deployments.log('the future "CxipERC721" address is', futureCxipErc721Address);

  const cxipErc721Hash = '0x' + web3.utils.asciiToHex('CxipERC721').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(cxipErc721Hash)) != futureCxipErc721Address) {
    hre.deployments.log(
      `Need to register "CxipERC721" with HolographRegistry: ${
        (await holographRegistry.populateTransaction.setContractTypeAddress(cxipErc721Hash, futureCxipErc721Address))
          .data
      }`
    );
    hre.deployments.log(`"CxipERC721" hash is: ${cxipErc721Hash}`);
    const cxipErc721Tx = await holograph
      .adminCall(
        holographRegistryProxy.address,
        (
          await holographRegistry.populateTransaction.setContractTypeAddress(cxipErc721Hash, futureCxipErc721Address)
        ).data,
        {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.adminCall(
              holographRegistryProxy.address,
              (
                await holographRegistry.populateTransaction.setContractTypeAddress(
                  cxipErc721Hash,
                  futureCxipErc721Address
                )
              ).data
            ),
          })),
        }
      )
      .catch(error);
    hre.deployments.log('Transaction hash:', cxipErc721Tx.hash);
    await cxipErc721Tx.wait();
    hre.deployments.log(
      `Registered "CxipERC721" to: ${await holographRegistry.getContractTypeAddress(cxipErc721Hash)}`
    );
  } else {
    hre.deployments.log('"CxipERC721" is already registered');
  }

  const futureErc20Address = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographERC20',
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'string', 'string', 'bool', 'bytes'],
      [
        'Holograph ERC20 Token', // contractName
        'HolographERC20', // contractSymbol
        18, // contractDecimals
        ConfigureEvents([]), // eventConfig
        'HolographERC20', // domainSeperator
        '1', // domainVersion
        true, // skipInit
        '0x', // initCode
      ]
    )
  );
  hre.deployments.log('the future "HolographERC20" address is', futureErc20Address);

  const erc20Hash = '0x' + web3.utils.asciiToHex('HolographERC20').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(erc20Hash)) != futureErc20Address) {
    hre.deployments.log(
      `Need to register "HolographERC20" with HolographRegistry: ${
        (await holographRegistry.populateTransaction.setContractTypeAddress(erc20Hash, futureErc20Address)).data
      }`
    );
    hre.deployments.log(`"HolographERC20" hash is: ${erc20Hash}`);
    const erc20Tx = await holograph
      .adminCall(
        holographRegistryProxy.address,
        (
          await holographRegistry.populateTransaction.setContractTypeAddress(erc20Hash, futureErc20Address)
        ).data,
        {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.adminCall(
              holographRegistryProxy.address,
              (
                await holographRegistry.populateTransaction.setContractTypeAddress(erc20Hash, futureErc20Address)
              ).data
            ),
          })),
        }
      )
      .catch(error);
    hre.deployments.log('Transaction hash:', erc20Tx.hash);
    await erc20Tx.wait();
    hre.deployments.log(`Registered "HolographERC20" to: ${await holographRegistry.getContractTypeAddress(erc20Hash)}`);
  } else {
    hre.deployments.log('"HolographERC20" is already registered');
  }

  const futureRoyaltiesAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographRoyalties',
    generateInitCode(['address', 'uint256'], [zeroAddress, '0x' + '00'.repeat(32)])
  );
  hre.deployments.log('the future "HolographRoyalties" address is', futureRoyaltiesAddress);

  const royaltiesHash = '0x' + web3.utils.asciiToHex('HolographRoyalties').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(royaltiesHash)) != futureRoyaltiesAddress) {
    hre.deployments.log(
      `Need to register "HolographRoyalties" with HolographRegistry: ${
        (await holographRegistry.populateTransaction.setContractTypeAddress(royaltiesHash, futureRoyaltiesAddress)).data
      }`
    );
    hre.deployments.log(`"HolographRoyalties" hash is: ${royaltiesHash}`);
    const royaltiesTx = await holograph
      .adminCall(
        royaltiesHash,
        (
          await holographRegistry.populateTransaction.setContractTypeAddress(royaltiesHash, futureRoyaltiesAddress)
        ).data,
        {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.adminCall(
              royaltiesHash,
              (
                await holographRegistry.populateTransaction.setContractTypeAddress(
                  royaltiesHash,
                  futureRoyaltiesAddress
                )
              ).data
            ),
          })),
        }
      )
      .catch(error);
    hre.deployments.log('Transaction hash:', royaltiesTx.hash);
    await royaltiesTx.wait();
    hre.deployments.log(
      `Registered "HolographRoyalties" to: ${await holographRegistry.getContractTypeAddress(royaltiesHash)}`
    );
  } else {
    hre.deployments.log('"HolographRoyalties" is already registered');
  }
};

export default func;
func.tags = ['ForMultisig'];
func.dependencies = [];
