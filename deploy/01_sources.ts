declare var global: any;
import fs from 'fs';
import Web3 from 'web3';
import { BigNumber, BytesLike } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  Admin,
  CxipERC721,
  CxipERC721Proxy,
  ERC20Mock,
  Holograph,
  HolographBridge,
  HolographBridgeProxy,
  Holographer,
  HolographERC20,
  HolographERC721,
  HolographFactory,
  HolographFactoryProxy,
  HolographGenesis,
  HolographOperator,
  HolographOperatorProxy,
  HolographRegistry,
  HolographRegistryProxy,
  HolographTreasury,
  HolographTreasuryProxy,
  HToken,
  HolographInterfaces,
  MockERC721Receiver,
  MockLZEndpoint,
  Owner,
  HolographRoyalties,
  SampleERC20,
  SampleERC721,
} from '../typechain-types';
import {
  genesisDeriveFutureAddress,
  genesisDeployHelper,
  generateInitCode,
  zeroAddress,
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  generateErc20Config,
  getHolographedContractHash,
  Signature,
  StrictECDSA,
  txParams,
} from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { reservedNamespaceHashes } from '../scripts/utils/reserved-namespaces';
import { HolographERC20Event, ConfigureEvents } from '../scripts/utils/events';
import { NetworkType, Network, networks } from '@holographxyz/networks';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';
import { Environment, getEnvironment } from '@holographxyz/environment';

import dotenv from 'dotenv';
dotenv.config();

const GWEI: BigNumber = BigNumber.from('1000000000');
const ZERO: BigNumber = BigNumber.from('0');

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

  const futureHolographAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'Holograph',
    generateInitCode(
      ['uint32', 'address', 'address', 'address', 'address', 'address', 'address', 'address', 'address'],
      [
        '0x' + networks[hre.networkName].holographId.toString(16).padStart(8, '0'),
        zeroAddress,
        zeroAddress,
        zeroAddress,
        zeroAddress,
        zeroAddress,
        zeroAddress,
        zeroAddress,
        zeroAddress,
      ]
    )
  );
  hre.deployments.log('the future "Holograph" address is', futureHolographAddress);
  global.__holographAddress = futureHolographAddress.toLowerCase();

  const futureBridgeAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographBridge',
    generateInitCode(['address', 'address', 'address', 'address'], [zeroAddress, zeroAddress, zeroAddress, zeroAddress])
  );
  hre.deployments.log('the future "HolographBridge" address is', futureBridgeAddress);

  const futureBridgeProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographBridgeProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        zeroAddress,
        generateInitCode(
          ['address', 'address', 'address', 'address', 'address'],
          [zeroAddress, zeroAddress, zeroAddress, zeroAddress, zeroAddress]
        ),
      ]
    )
  );
  hre.deployments.log('the future "HolographBridgeProxy" address is', futureBridgeProxyAddress);

  const futureFactoryAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographFactory',
    generateInitCode(['address', 'address', 'address'], [zeroAddress, zeroAddress, zeroAddress])
  );
  hre.deployments.log('the future "HolographFactory" address is', futureFactoryAddress);

  const futureFactoryProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographFactoryProxy',
    generateInitCode(
      ['address', 'bytes'],
      [zeroAddress, generateInitCode(['address', 'address', 'address'], [zeroAddress, zeroAddress, zeroAddress])]
    )
  );
  hre.deployments.log('the future "HolographFactoryProxy" address is', futureFactoryProxyAddress);
  global.__holographFactoryAddress = futureFactoryProxyAddress.toLowerCase();

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

  const futureOperatorProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographOperatorProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        zeroAddress,
        generateInitCode(
          ['address', 'address', 'address', 'address', 'address', 'uint256'],
          [zeroAddress, zeroAddress, zeroAddress, zeroAddress, zeroAddress, '0x' + '00'.repeat(32)]
        ),
      ]
    )
  );
  hre.deployments.log('the future "HolographOperatorProxy" address is', futureOperatorProxyAddress);

  const futureRegistryAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographRegistry',
    generateInitCode(['address', 'bytes32[]'], [zeroAddress, []])
  );
  hre.deployments.log('the future "HolographRegistry" address is', futureRegistryAddress);

  const futureRegistryProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographRegistryProxy',
    generateInitCode(['address', 'bytes'], [zeroAddress, generateInitCode(['address', 'bytes32[]'], [zeroAddress, []])])
  );
  hre.deployments.log('the future "HolographRegistryProxy" address is', futureRegistryProxyAddress);

  const futureTreasuryAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographTreasury',
    generateInitCode(['address', 'address', 'address', 'address'], [zeroAddress, zeroAddress, zeroAddress, zeroAddress])
  );
  hre.deployments.log('the future "HolographTreasury" address is', futureTreasuryAddress);

  const futureTreasuryProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographTreasuryProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        zeroAddress,
        generateInitCode(
          ['address', 'address', 'address', 'address'],
          [zeroAddress, zeroAddress, zeroAddress, zeroAddress]
        ),
      ]
    )
  );
  hre.deployments.log('the future "HolographTreasuryProxy" address is', futureTreasuryProxyAddress);

  const futureHolographInterfacesAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographInterfaces',
    generateInitCode(['address'], [zeroAddress])
  );
  hre.deployments.log('the future "HolographInterfaces" address is', futureHolographInterfacesAddress);

  const futureRoyaltiesAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographRoyalties',
    generateInitCode(['uint256'], ['0x' + '00'.repeat(32)])
  );
  hre.deployments.log('the future "HolographRoyalties" address is', futureRoyaltiesAddress);

  const network = networks[hre.networkName];

  const environment: Environment = getEnvironment();

  let tokenAmount: BigNumber = BigNumber.from('100' + '000' + '000' + '000000000000000000');
  let targetChain: BigNumber = BigNumber.from('0');
  let tokenRecipient: string = deployer.address;

  // Future Holograph Utility Token
  const currentNetworkType: NetworkType = network.type;
  let primaryNetwork: Network;
  if (currentNetworkType == NetworkType.local) {
    // one billion tokens minted per network on local testing
    tokenAmount = BigNumber.from('1' + '000' + '000' + '000' + '000000000000000000');
    primaryNetwork = networks.localhost;
  } else if (currentNetworkType == NetworkType.testnet) {
    // one hundred million tokens minted per network on testnets
    tokenAmount = BigNumber.from('100' + '000' + '000' + '000000000000000000');
    primaryNetwork = networks.ethereumTestnetGoerli;
    if (environment == Environment.testnet) {
      tokenAmount = BigNumber.from('10' + '000' + '000' + '000' + '000000000000000000');
      targetChain = BigNumber.from(networks.ethereumTestnetGoerli.chain);
      tokenRecipient = networks.ethereumTestnetGoerli.protocolMultisig;
    }
  } else if (currentNetworkType == NetworkType.mainnet) {
    // ten billion tokens minted on ethereum on mainnet
    tokenAmount = BigNumber.from('10' + '000' + '000' + '000' + '000000000000000000');
    // target chain is restricted to ethereum, to prevent the minting of tokens on other chains
    targetChain = BigNumber.from(networks.ethereum.chain);
    // protocol multisig is the recipient
    // This is the hardcoded Gnosis Safe address of Holograph Research
    tokenRecipient = '0xfC40b4233f8Ce60461e1D5FE50b3DDF0C50AE0b4'; //networks.ethereum.protocolMultisig;
    primaryNetwork = networks.ethereum;
  } else {
    throw new Error('cannot identity current NetworkType');
  }

  let { erc20Config, erc20ConfigHash, erc20ConfigHashBytes } = await generateErc20Config(
    primaryNetwork,
    deployer.address,
    'HolographUtilityToken',
    'Holograph Utility Token',
    'HLG',
    'Holograph Utility Token',
    '1',
    18,
    ConfigureEvents([]),
    generateInitCode(
      ['address', 'uint256', 'uint256', 'address'],
      [deployer.address, tokenAmount.toHexString(), targetChain.toHexString(), tokenRecipient]
    ),
    salt
  );

  const holographerBytecode: BytesLike = (await hre.ethers.getContractFactory('Holographer')).bytecode;
  const futureHlgAddress = hre.ethers.utils.getCreate2Address(
    futureFactoryProxyAddress,
    erc20ConfigHash,
    hre.ethers.utils.keccak256(holographerBytecode)
  );
  hre.deployments.log('the future "HolographUtilityToken" address is', futureHlgAddress);

  const dryRun = process.env.DRY_RUN;
  if ((dryRun && dryRun === 'true') || dryRun === true) {
    process.exit();
    throw new Error('WHY?');
  }

  // Holograph
  let holographDeployedCode: string = await hre.provider.send('eth_getCode', [futureHolographAddress, 'latest']);
  if (holographDeployedCode == '0x' || holographDeployedCode == '') {
    hre.deployments.log('"Holograph" bytecode not found, need to deploy"');
    let holograph = await genesisDeployHelper(
      hre,
      salt,
      'Holograph',
      generateInitCode(
        ['uint32', 'address', 'address', 'address', 'address', 'address', 'address', 'address'],
        [
          '0x' + networks[hre.networkName].holographId.toString(16).padStart(8, '0'),
          futureBridgeProxyAddress,
          futureFactoryProxyAddress,
          futureHolographInterfacesAddress,
          futureOperatorProxyAddress,
          futureRegistryProxyAddress,
          futureTreasuryProxyAddress,
          futureHlgAddress,
        ]
      ),
      futureHolographAddress
    );
  } else {
    hre.deployments.log('"Holograph" is already deployed. Checking configs.');
    let holograph = (await hre.ethers.getContractAt('Holograph', futureHolographAddress, deployer)) as Holograph;
    if ((await holograph.getBridge()) != futureBridgeProxyAddress) {
      hre.deployments.log('Updating Bridge reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'Holograph',
        holograph,
        await holograph.populateTransaction.setBridge(futureBridgeProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.setBridge(futureBridgeProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holograph.getFactory()) != futureFactoryProxyAddress) {
      hre.deployments.log('Updating Factory reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'Holograph',
        holograph,
        await holograph.populateTransaction.setFactory(futureFactoryProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.setFactory(futureFactoryProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holograph.getInterfaces()) != futureHolographInterfacesAddress) {
      hre.deployments.log('Updating HolographInterfaces reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'Holograph',
        holograph,
        await holograph.populateTransaction.setInterfaces(futureHolographInterfacesAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.setInterfaces(futureHolographInterfacesAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holograph.getOperator()) != futureOperatorProxyAddress) {
      hre.deployments.log('Updating Operator reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'Holograph',
        holograph,
        await holograph.populateTransaction.setOperator(futureOperatorProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.setOperator(futureOperatorProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holograph.getRegistry()) != futureRegistryProxyAddress) {
      hre.deployments.log('Updating Registry reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'Holograph',
        holograph,
        await holograph.populateTransaction.setRegistry(futureRegistryProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.setRegistry(futureRegistryProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holograph.getTreasury()) != futureTreasuryProxyAddress) {
      hre.deployments.log('Updating Treasury reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'Holograph',
        holograph,
        await holograph.populateTransaction.setTreasury(futureTreasuryProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.setTreasury(futureTreasuryProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holograph.getUtilityToken()) != futureHlgAddress) {
      hre.deployments.log('Updating UtilityToken reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'Holograph',
        holograph,
        await holograph.populateTransaction.setUtilityToken(futureHlgAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.setUtilityToken(futureHlgAddress),
          })),
        })
      );
      await tx.wait();
    }
  }

  // HolographBridge
  let bridgeDeployedCode: string = await hre.provider.send('eth_getCode', [futureBridgeAddress, 'latest']);
  if (bridgeDeployedCode == '0x' || bridgeDeployedCode == '') {
    hre.deployments.log('"HolographBridge" bytecode not found, need to deploy"');
    let holographBridge = await genesisDeployHelper(
      hre,
      salt,
      'HolographBridge',
      generateInitCode(
        ['address', 'address', 'address', 'address'],
        [zeroAddress, zeroAddress, zeroAddress, zeroAddress]
      ),
      futureBridgeAddress
    );
  } else {
    hre.deployments.log('"HolographBridge" is already deployed.');
  }

  // HolographBridgeProxy
  let bridgeProxyDeployedCode: string = await hre.provider.send('eth_getCode', [futureBridgeProxyAddress, 'latest']);
  if (bridgeProxyDeployedCode == '0x' || bridgeProxyDeployedCode == '') {
    hre.deployments.log('"HolographBridgeProxy" bytecode not found, need to deploy"');
    let holographBridgeProxy = await genesisDeployHelper(
      hre,
      salt,
      'HolographBridgeProxy',
      generateInitCode(
        ['address', 'bytes'],
        [
          futureBridgeAddress,
          generateInitCode(
            ['address', 'address', 'address', 'address'],
            [futureFactoryProxyAddress, futureHolographAddress, futureOperatorProxyAddress, futureRegistryProxyAddress]
          ),
        ]
      ),
      futureBridgeProxyAddress
    );
  } else {
    hre.deployments.log('"HolographBridgeProxy" is already deployed. Checking configs.');
    let holographBridgeProxy = (await hre.ethers.getContractAt(
      'HolographBridgeProxy',
      futureBridgeProxyAddress,
      deployer
    )) as HolographBridgeProxy;
    let holographBridge = (await hre.ethers.getContractAt(
      'HolographBridge',
      futureBridgeProxyAddress,
      deployer
    )) as HolographBridge;
    if ((await holographBridgeProxy.getBridge()) != futureBridgeAddress) {
      hre.deployments.log('Updating Bridge reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographBridgeProxy',
        holographBridgeProxy,
        await holographBridgeProxy.populateTransaction.setBridge(futureBridgeAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographBridgeProxy,
            data: holographBridgeProxy.populateTransaction.setBridge(futureBridgeAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographBridge.getFactory()) != futureFactoryProxyAddress) {
      hre.deployments.log('Updating Factory reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographBridge',
        holographBridge,
        await holographBridge.populateTransaction.setFactory(futureFactoryProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographBridge,
            data: holographBridge.populateTransaction.setFactory(futureFactoryProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographBridge.getHolograph()) != futureHolographAddress) {
      hre.deployments.log('Updating Holograph reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographBridge',
        holographBridge,
        await holographBridge.populateTransaction.setHolograph(futureHolographAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographBridge,
            data: holographBridge.populateTransaction.setHolograph(futureHolographAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographBridge.getOperator()) != futureOperatorProxyAddress) {
      hre.deployments.log('Updating Operator reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographBridge',
        holographBridge,
        await holographBridge.populateTransaction.setOperator(futureOperatorProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographBridge,
            data: holographBridge.populateTransaction.setOperator(futureOperatorProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographBridge.getRegistry()) != futureRegistryProxyAddress) {
      hre.deployments.log('Updating Registry reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographBridge',
        holographBridge,
        await holographBridge.populateTransaction.setRegistry(futureRegistryProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographBridge,
            data: holographBridge.populateTransaction.setRegistry(futureRegistryProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
  }

  // HolographFactory
  let factoryDeployedCode: string = await hre.provider.send('eth_getCode', [futureFactoryAddress, 'latest']);
  if (factoryDeployedCode == '0x' || factoryDeployedCode == '') {
    hre.deployments.log('"HolographFactory" bytecode not found, need to deploy"');
    let holographFactory = await genesisDeployHelper(
      hre,
      salt,
      'HolographFactory',
      generateInitCode(['address', 'address', 'address'], [zeroAddress, zeroAddress, zeroAddress]),
      futureFactoryAddress
    );
  } else {
    hre.deployments.log('"HolographFactory" is already deployed.');
  }

  // HolographFactoryProxy
  let factoryProxyDeployedCode: string = await hre.provider.send('eth_getCode', [futureFactoryProxyAddress, 'latest']);
  if (factoryProxyDeployedCode == '0x' || factoryProxyDeployedCode == '') {
    hre.deployments.log('"HolographFactoryProxy" bytecode not found, need to deploy"');
    let holographFactoryProxy = await genesisDeployHelper(
      hre,
      salt,
      'HolographFactoryProxy',
      generateInitCode(
        ['address', 'bytes'],
        [
          futureFactoryAddress,
          generateInitCode(
            ['address', 'address'],
            [
              futureHolographAddress, // Holograph
              futureRegistryProxyAddress, // HolographRegistry
            ]
          ),
        ]
      ),
      futureFactoryProxyAddress
    );
  } else {
    hre.deployments.log('"HolographFactoryProxy" is already deployed. Checking configs.');
    let holographFactoryProxy = (await hre.ethers.getContractAt(
      'HolographFactoryProxy',
      futureFactoryProxyAddress,
      deployer
    )) as HolographFactoryProxy;
    let holographFactory = (await hre.ethers.getContractAt(
      'HolographFactory',
      futureFactoryProxyAddress,
      deployer
    )) as HolographFactory;
    if ((await holographFactoryProxy.getFactory()) != futureFactoryAddress) {
      hre.deployments.log('Updating Factory reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographFactoryProxy',
        holographFactoryProxy,
        await holographFactoryProxy.populateTransaction.setFactory(futureFactoryAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographFactoryProxy,
            data: holographFactoryProxy.populateTransaction.setFactory(futureFactoryAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographFactory.getHolograph()) != futureHolographAddress) {
      hre.deployments.log('Updating Holograph reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographFactory',
        holographFactory,
        await holographFactory.populateTransaction.setHolograph(futureHolographAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographFactory,
            data: holographFactory.populateTransaction.setHolograph(futureHolographAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographFactory.getRegistry()) != futureRegistryProxyAddress) {
      hre.deployments.log('Updating Registry reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographFactory',
        holographFactory,
        await holographFactory.populateTransaction.setRegistry(futureRegistryProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographFactory,
            data: holographFactory.populateTransaction.setRegistry(futureRegistryProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
  }

  // HolographOperator
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

  // HolographOperatorProxy
  let operatorProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureOperatorProxyAddress,
    'latest',
  ]);
  if (operatorProxyDeployedCode == '0x' || operatorProxyDeployedCode == '') {
    hre.deployments.log('"HolographOperatorProxy" bytecode not found, need to deploy"');
    let holographOperatorProxy = await genesisDeployHelper(
      hre,
      salt,
      'HolographOperatorProxy',
      generateInitCode(
        ['address', 'bytes'],
        [
          futureOperatorAddress,
          generateInitCode(
            ['address', 'address', 'address', 'address', 'address', 'uint256'],
            [
              futureBridgeProxyAddress,
              futureHolographAddress,
              futureHolographInterfacesAddress,
              futureRegistryProxyAddress,
              futureHlgAddress,
              GWEI.toHexString(),
            ]
          ),
        ]
      ),
      futureOperatorProxyAddress
    );
  } else {
    hre.deployments.log('"HolographOperatorProxy" is already deployed. Checking configs.');
    let holographOperatorProxy = (await hre.ethers.getContractAt(
      'HolographOperatorProxy',
      futureOperatorProxyAddress,
      deployer
    )) as HolographOperatorProxy;
    let holographOperator = (await hre.ethers.getContractAt(
      'HolographOperator',
      futureOperatorProxyAddress,
      deployer
    )) as HolographOperator;
    if ((await holographOperatorProxy.getOperator()) != futureOperatorAddress) {
      hre.deployments.log('Updating Operator reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographOperatorProxy',
        holographOperatorProxy,
        await holographOperatorProxy.populateTransaction.setOperator(futureOperatorAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographOperatorProxy,
            data: holographOperatorProxy.populateTransaction.setOperator(futureOperatorAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographOperator.getBridge()) != futureBridgeProxyAddress) {
      hre.deployments.log('Updating Bridge reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographOperator',
        holographOperator,
        await holographOperator.populateTransaction.setBridge(futureBridgeProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographOperator,
            data: holographOperator.populateTransaction.setBridge(futureBridgeProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographOperator.getHolograph()) != futureHolographAddress) {
      hre.deployments.log('Updating Holograph reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographOperator',
        holographOperator,
        await holographOperator.populateTransaction.setHolograph(futureHolographAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographOperator,
            data: holographOperator.populateTransaction.setHolograph(futureHolographAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographOperator.getInterfaces()) != futureHolographInterfacesAddress) {
      hre.deployments.log('Updating HolographInterfaces reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographOperator',
        holographOperator,
        await holographOperator.populateTransaction.setInterfaces(futureHolographInterfacesAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographOperator,
            data: holographOperator.populateTransaction.setInterfaces(futureHolographInterfacesAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographOperator.getRegistry()) != futureRegistryProxyAddress) {
      hre.deployments.log('Updating Registry reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographOperator',
        holographOperator,
        await holographOperator.populateTransaction.setRegistry(futureRegistryProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographOperator,
            data: holographOperator.populateTransaction.setRegistry(futureRegistryProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographOperator.getUtilityToken()) != futureHlgAddress) {
      hre.deployments.log('Updating UtilityToken reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographOperator',
        holographOperator,
        await holographOperator.populateTransaction.setUtilityToken(futureHlgAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographOperator,
            data: holographOperator.populateTransaction.setUtilityToken(futureHlgAddress),
          })),
        })
      );
      await tx.wait();
    }
    if (!BigNumber.from(await holographOperator.getMinGasPrice()).eq(GWEI)) {
      hre.deployments.log('Updating MinGasPrice reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographOperator',
        holographOperator,
        await holographOperator.populateTransaction.setMinGasPrice(GWEI.toHexString(), {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographOperator,
            data: holographOperator.populateTransaction.setMinGasPrice(GWEI.toHexString()),
          })),
        })
      );
      await tx.wait();
    }
  }

  // HolographRegistry
  let registryDeployedCode: string = await hre.provider.send('eth_getCode', [futureRegistryAddress, 'latest']);
  if (registryDeployedCode == '0x' || registryDeployedCode == '') {
    hre.deployments.log('"HolographRegistry" bytecode not found, need to deploy"');
    let holographRegistry = await genesisDeployHelper(
      hre,
      salt,
      'HolographRegistry',
      generateInitCode(['address', 'bytes32[]'], [zeroAddress, []]),
      futureRegistryAddress
    );
  } else {
    hre.deployments.log('"HolographRegistry" is already deployed.');
  }

  // HolographRegistryProxy
  let registryProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureRegistryProxyAddress,
    'latest',
  ]);
  if (registryProxyDeployedCode == '0x' || registryProxyDeployedCode == '') {
    hre.deployments.log('"HolographRegistryProxy" bytecode not found, need to deploy"');
    let holographRegistryProxy = await genesisDeployHelper(
      hre,
      salt,
      'HolographRegistryProxy',
      generateInitCode(
        ['address', 'bytes'],
        [
          futureRegistryAddress,
          generateInitCode(['address', 'bytes32[]'], [futureHolographAddress, reservedNamespaceHashes]),
        ]
      ),
      futureRegistryProxyAddress
    );
    let holographRegistry = (await hre.ethers.getContractAt(
      'HolographRegistry',
      futureRegistryProxyAddress,
      deployer
    )) as HolographRegistry;
    if ((await holographRegistry.getUtilityToken()) != futureHlgAddress) {
      hre.deployments.log('Updating UtilityToken reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographRegistry',
        holographRegistry,
        await holographRegistry.populateTransaction.setUtilityToken(futureHlgAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographRegistry,
            data: holographRegistry.populateTransaction.setUtilityToken(futureHlgAddress),
          })),
        })
      );
      await tx.wait();
    }
  } else {
    hre.deployments.log('"HolographRegistryProxy" is already deployed. Checking configs.');
    let holographRegistryProxy = (await hre.ethers.getContractAt(
      'HolographRegistryProxy',
      futureRegistryProxyAddress,
      deployer
    )) as HolographRegistryProxy;
    let holographRegistry = (await hre.ethers.getContractAt(
      'HolographRegistry',
      futureRegistryProxyAddress,
      deployer
    )) as HolographRegistry;
    if ((await holographRegistryProxy.getRegistry()) != futureRegistryAddress) {
      hre.deployments.log('Updating Registry reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographRegistryProxy',
        holographRegistryProxy,
        await holographRegistryProxy.populateTransaction.setRegistry(futureRegistryAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographRegistryProxy,
            data: holographRegistryProxy.populateTransaction.setRegistry(futureRegistryAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographRegistry.getHolograph()) != futureHolographAddress) {
      hre.deployments.log('Updating Holograph reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographRegistry',
        holographRegistry,
        await holographRegistry.populateTransaction.setHolograph(futureHolographAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographRegistry,
            data: holographRegistry.populateTransaction.setHolograph(futureHolographAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographRegistry.getUtilityToken()) != futureHlgAddress) {
      hre.deployments.log('Updating UtilityToken reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographRegistry',
        holographRegistry,
        await holographRegistry.populateTransaction.setUtilityToken(futureHlgAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographRegistry,
            data: holographRegistry.populateTransaction.setUtilityToken(futureHlgAddress),
          })),
        })
      );
      await tx.wait();
    }
  }

  // HolographTreasury
  let treasuryDeployedCode: string = await hre.provider.send('eth_getCode', [futureTreasuryAddress, 'latest']);
  if (treasuryDeployedCode == '0x' || treasuryDeployedCode == '') {
    hre.deployments.log('"HolographTreasury" bytecode not found, need to deploy"');
    let holographTreasury = await genesisDeployHelper(
      hre,
      salt,
      'HolographTreasury',
      generateInitCode(
        ['address', 'address', 'address', 'address'],
        [zeroAddress, zeroAddress, zeroAddress, zeroAddress]
      ),
      futureTreasuryAddress
    );
  } else {
    hre.deployments.log('"HolographTreasury" is already deployed.');
  }

  // HolographTreasuryProxy
  let treasuryProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureTreasuryProxyAddress,
    'latest',
  ]);
  if (treasuryProxyDeployedCode == '0x' || treasuryProxyDeployedCode == '') {
    hre.deployments.log('"HolographTreasuryProxy" bytecode not found, need to deploy"');
    let holographTreasuryProxy = await genesisDeployHelper(
      hre,
      salt,
      'HolographTreasuryProxy',
      generateInitCode(
        ['address', 'bytes'],
        [
          futureTreasuryAddress,
          generateInitCode(
            ['address', 'address', 'address', 'address'],
            [futureBridgeProxyAddress, futureHolographAddress, futureOperatorProxyAddress, futureRegistryProxyAddress]
          ),
        ]
      ),
      futureTreasuryProxyAddress
    );
  } else {
    hre.deployments.log('"HolographTreasuryProxy" is already deployed. Checking configs.');
    let holographTreasuryProxy = (await hre.ethers.getContractAt(
      'HolographTreasuryProxy',
      futureTreasuryProxyAddress,
      deployer
    )) as HolographTreasuryProxy;
    let holographTreasury = (await hre.ethers.getContractAt(
      'HolographTreasury',
      futureTreasuryProxyAddress,
      deployer
    )) as HolographTreasury;
    if ((await holographTreasuryProxy.getTreasury()) != futureTreasuryAddress) {
      hre.deployments.log('Updating Treasury reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographTreasuryProxy',
        holographTreasuryProxy,
        await holographTreasuryProxy.populateTransaction.setTreasury(futureTreasuryAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographTreasuryProxy,
            data: holographTreasuryProxy.populateTransaction.setTreasury(futureTreasuryAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographTreasury.getBridge()) != futureBridgeProxyAddress) {
      hre.deployments.log('Updating Bridge reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographTreasury',
        holographTreasury,
        await holographTreasury.populateTransaction.setBridge(futureBridgeProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographTreasury,
            data: holographTreasury.populateTransaction.setBridge(futureBridgeProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographTreasury.getOperator()) != futureOperatorProxyAddress) {
      hre.deployments.log('Updating Operator reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographTreasury',
        holographTreasury,
        await holographTreasury.populateTransaction.setOperator(futureOperatorProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographTreasury,
            data: holographTreasury.populateTransaction.setOperator(futureOperatorProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
    if ((await holographTreasury.getRegistry()) != futureRegistryProxyAddress) {
      hre.deployments.log('Updating Registry reference');
      let tx = await MultisigAwareTx(
        hre,
        deployer,
        'HolographTreasury',
        holographTreasury,
        await holographTreasury.populateTransaction.setRegistry(futureRegistryProxyAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographTreasury,
            data: holographTreasury.populateTransaction.setRegistry(futureRegistryProxyAddress),
          })),
        })
      );
      await tx.wait();
    }
  }

  // HolographInterfaces
  let interfacesDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureHolographInterfacesAddress,
    'latest',
  ]);
  if (interfacesDeployedCode == '0x' || interfacesDeployedCode == '') {
    hre.deployments.log('"HolographInterfaces" bytecode not found, need to deploy"');
    let interfaces = await genesisDeployHelper(
      hre,
      salt,
      'HolographInterfaces',
      generateInitCode(['address'], [deployer.address]),
      futureHolographInterfacesAddress
    );
    global.__deployedHolographInterfaces = true;
  } else {
    hre.deployments.log('"HolographInterfaces" is already deployed.');
    global.__deployedHolographInterfaces = false;
  }

  // HolographRoyalties
  let royaltiesDeployedCode: string = await hre.provider.send('eth_getCode', [futureRoyaltiesAddress, 'latest']);
  if (royaltiesDeployedCode == '0x' || royaltiesDeployedCode == '') {
    hre.deployments.log('"HolographRoyalties" bytecode not found, need to deploy"');
    let royalties = await genesisDeployHelper(
      hre,
      salt,
      'HolographRoyalties',
      generateInitCode(['uint256'], ['0x' + '00'.repeat(32)]),
      futureRoyaltiesAddress
    );
  } else {
    hre.deployments.log('"HolographRoyalties" is already deployed..');
  }
};

export default func;
func.tags = [
  'DeploySources',

  'Holograph',
  'HolographBridge',
  'HolographBridgeProxy',
  'HolographFactory',
  'HolographFactoryProxy',
  'HolographOperator',
  'HolographOperatorProxy',
  'HolographRegistry',
  'HolographRegistryProxy',
  'HolographTreasury',
  'HolographTreasuryProxy',
  'HolographInterfaces',
  'HolographRoyalties',
];
func.dependencies = ['HolographGenesis'];
