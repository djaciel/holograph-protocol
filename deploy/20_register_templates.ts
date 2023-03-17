declare var global: any;
import fs from 'fs';
import Web3 from 'web3';
import { BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
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

  const holographRegistryProxy = await hre.ethers.getContract('HolographRegistryProxy', deployer);
  const holographRegistry = ((await hre.ethers.getContract('HolographRegistry', deployer)) as Contract).attach(
    holographRegistryProxy.address
  );

  // Register Generic
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
    const genericTx = await holographRegistry
      .setContractTypeAddress(genericHash, futureGenericAddress, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setContractTypeAddress(genericHash, futureGenericAddress),
        })),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', genericTx.hash);
    await genericTx.wait();
    hre.deployments.log(
      `Registered "HolographGeneric" to: ${await holographRegistry.getContractTypeAddress(genericHash)}`
    );
  } else {
    hre.deployments.log('"HolographGeneric" is already registered');
  }

  // Register ERC721
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
    const erc721Tx = await holographRegistry
      .setContractTypeAddress(erc721Hash, futureErc721Address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setContractTypeAddress(erc721Hash, futureErc721Address),
        })),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', erc721Tx.hash);
    await erc721Tx.wait();
    hre.deployments.log(
      `Registered "HolographERC721" to: ${await holographRegistry.getContractTypeAddress(erc721Hash)}`
    );
  } else {
    hre.deployments.log('"HolographERC721" is already registered');
  }

  // Register HolographDropERC721
  const futureEditionsMetadataRendererAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'EditionsMetadataRenderer',
    generateInitCode([], [])
  );
  const futureEditionsMetadataRendererProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'EditionsMetadataRendererProxy',
    generateInitCode(['address', 'bytes'], [futureEditionsMetadataRendererAddress, generateInitCode([], [])])
  );
  const HolographDropERC721InitCode = generateInitCode(
    [
      'tuple(address,address,address,address,uint64,uint16,bool,tuple(uint104,uint32,uint64,uint64,uint64,uint64,bytes32),address,bytes)',
    ],
    [
      [
        '0x0000000000000000000000000000000000000000', // holographERC721TransferHelper
        '0x0000000000000000000000000000000000000000', // marketFilterAddress (opensea)
        deployer.address, // initialOwner
        deployer.address, // fundsRecipient
        0, // 1000 editions
        1000, // 10% royalty
        true, // enableOpenSeaRoyaltyRegistry
        [0, 0, 0, 0, 0, 0, '0x' + '00'.repeat(32)], // salesConfig
        futureEditionsMetadataRendererProxyAddress, // metadataRenderer
        generateInitCode(['string', 'string', 'string'], ['decscription', 'imageURI', 'animationURI']), // metadataRendererInit
      ],
    ]
  );
  const futureHolographDropERC721Address = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographDropERC721',
    HolographDropERC721InitCode
  );
  hre.deployments.log('the future "HolographDropERC721" address is', futureHolographDropERC721Address);
  const HolographDropERC721Hash = '0x' + web3.utils.asciiToHex('HolographDropERC721').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(HolographDropERC721Hash)) != futureHolographDropERC721Address) {
    const erc721DropTx = await holographRegistry
      .setContractTypeAddress(HolographDropERC721Hash, futureHolographDropERC721Address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setContractTypeAddress(
            HolographDropERC721Hash,
            futureHolographDropERC721Address
          ),
        })),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', erc721DropTx.hash);
    await erc721DropTx.wait();
    hre.deployments.log(
      `Registered "HolographDropERC721" to: ${await holographRegistry.getContractTypeAddress(HolographDropERC721Hash)}`
    );
  } else {
    hre.deployments.log('"HolographDropERC721" is already registered');
  }

  // Register CxipERC721
  const futureCxipErc721Address = await genesisDeriveFutureAddress(
    hre,
    salt,
    'CxipERC721',
    generateInitCode(['address'], [zeroAddress])
  );
  hre.deployments.log('the future "CxipERC721" address is', futureCxipErc721Address);

  const cxipErc721Hash = '0x' + web3.utils.asciiToHex('CxipERC721').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(cxipErc721Hash)) != futureCxipErc721Address) {
    const cxipErc721Tx = await holographRegistry
      .setContractTypeAddress(cxipErc721Hash, futureCxipErc721Address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setContractTypeAddress(cxipErc721Hash, futureCxipErc721Address),
        })),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', cxipErc721Tx.hash);
    await cxipErc721Tx.wait();
    hre.deployments.log(
      `Registered "CxipERC721" to: ${await holographRegistry.getContractTypeAddress(cxipErc721Hash)}`
    );
  } else {
    hre.deployments.log('"CxipERC721" is already registered');
  }

  // Register ERC20
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
    const erc20Tx = await holographRegistry
      .setContractTypeAddress(erc20Hash, futureErc20Address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setContractTypeAddress(erc20Hash, futureErc20Address),
        })),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', erc20Tx.hash);
    await erc20Tx.wait();
    hre.deployments.log(`Registered "HolographERC20" to: ${await holographRegistry.getContractTypeAddress(erc20Hash)}`);
  } else {
    hre.deployments.log('"HolographERC20" is already registered');
  }

  // Register Royalties
  const futureRoyaltiesAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographRoyalties',
    generateInitCode(['address', 'uint256'], [zeroAddress, '0x' + '00'.repeat(32)])
  );
  hre.deployments.log('the future "HolographRoyalties" address is', futureRoyaltiesAddress);

  const pa1dHash = '0x' + web3.utils.asciiToHex('HolographRoyalties').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(pa1dHash)) != futureRoyaltiesAddress) {
    const pa1dTx = await holographRegistry
      .setContractTypeAddress(pa1dHash, futureRoyaltiesAddress, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setContractTypeAddress(pa1dHash, futureRoyaltiesAddress),
        })),
      })
      .catch(error);
    hre.deployments.log('Transaction hash:', pa1dTx.hash);
    await pa1dTx.wait();
    hre.deployments.log(
      `Registered "HolographRoyalties" to: ${await holographRegistry.getContractTypeAddress(pa1dHash)}`
    );
  } else {
    hre.deployments.log('"HolographRoyalties" is already registered');
  }
};

export default func;
func.tags = ['RegisterTemplates'];
func.dependencies = [
  'HolographGenesis',
  'DeploySources',
  'DeployGeneric',
  'DeployERC20',
  'DeployERC721',
  'HolographDropERC721',
  'DeployERC1155',
];
