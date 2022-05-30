declare var global: any;
import fs from 'fs';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import Web3 from 'web3';
import {
  genesisDeriveFutureAddress,
  genesisDeployHelper,
  generateInitCode,
  zeroAddress,
  LeanHardhatRuntimeEnvironment,
  hreSplit,
} from '../scripts/utils/helpers';

const networks = JSON.parse(fs.readFileSync('./config/networks.json', 'utf8'));

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const { deployments, getNamedAccounts } = hre;
  const { deploy, deterministicCustom } = deployments;
  const { deployer } = await getNamedAccounts();

  const web3 = new Web3();

  const salt: string = '0x' + '00'.repeat(12);

  const futureHolographAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'Holograph',
    generateInitCode(
      ['uint32', 'address', 'address', 'address', 'address'],
      [
        '0x' + networks[hre.networkName].holographId.toString(16).padStart(8, '0'),
        zeroAddress(),
        zeroAddress(),
        zeroAddress(),
        zeroAddress(),
      ]
    )
  );
  hre.deployments.log('the future "Holograph" address is', futureHolographAddress);

  const futureBridgeProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographBridgeProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        zeroAddress(),
        generateInitCode(
          ['address', 'address', 'address', 'address'],
          [zeroAddress(), zeroAddress(), zeroAddress(), zeroAddress()]
        ),
      ]
    )
  );
  hre.deployments.log('the future "HolographBridgeProxy" address is', futureBridgeProxyAddress);

  // Interfaces
  let interfaces = await genesisDeployHelper(hre, salt, 'Interfaces', generateInitCode(['address'], [deployer]));

  // HolographRegistry
  let holographRegistry = await genesisDeployHelper(
    hre,
    salt,
    'HolographRegistry',
    generateInitCode(['address', 'bytes32[]'], [zeroAddress(), []])
  );

  // HolographRegistryProxy
  let holographRegistryProxy = await genesisDeployHelper(
    hre,
    salt,
    'HolographRegistryProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        holographRegistry.address,
        generateInitCode(
          ['address', 'bytes32[]'],
          [
            futureHolographAddress,
            [
              '0x' + web3.utils.asciiToHex('HolographERC721').substring(2).padStart(64, '0'),
              '0x' + web3.utils.asciiToHex('HolographERC20').substring(2).padStart(64, '0'),
              '0x' + web3.utils.asciiToHex('PA1D').substring(2).padStart(64, '0'),
            ],
          ]
        ),
      ]
    )
  );

  // HolographOperator
  let holographOperator = await genesisDeployHelper(
    hre,
    salt,
    'HolographOperator',
    generateInitCode(['address', 'address', 'address'], [zeroAddress(), zeroAddress(), zeroAddress()])
  );

  // HolographOperatorProxy
  let holographOperatorProxy = await genesisDeployHelper(
    hre,
    salt,
    'HolographOperatorProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        holographOperator.address,
        generateInitCode(
          ['address', 'address', 'address'],
          [futureHolographAddress, holographRegistryProxy.address, futureBridgeProxyAddress]
        ),
      ]
    )
  );

  // SecureStorage
  let secureStorage = await genesisDeployHelper(
    hre,
    salt,
    'SecureStorage',
    generateInitCode(['address'], [zeroAddress()])
  );

  // SecureStorageProxy
  let secureStorageProxy = await genesisDeployHelper(
    hre,
    salt,
    'SecureStorageProxy',
    generateInitCode(['address', 'bytes'], [secureStorage.address, generateInitCode(['address'], [zeroAddress()])])
  );

  // HolographFactory
  let holographFactory = await genesisDeployHelper(
    hre,
    salt,
    'HolographFactory',
    generateInitCode(['address', 'address', 'address'], [zeroAddress(), zeroAddress(), zeroAddress()])
  );

  // HolographFactoryProxy
  let holographFactoryProxy = await genesisDeployHelper(
    hre,
    salt,
    'HolographFactoryProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        holographFactory.address,
        generateInitCode(
          ['address', 'address', 'address'],
          [
            futureHolographAddress, // Holograph
            holographRegistryProxy.address, // HolographRegistry
            secureStorage.address, // SecureStorage
          ]
        ),
      ]
    )
  );

  // HolographBridge
  let holographBridge = await genesisDeployHelper(
    hre,
    salt,
    'HolographBridge',
    generateInitCode(
      ['address', 'address', 'address', 'address'],
      [zeroAddress(), zeroAddress(), zeroAddress(), zeroAddress()]
    )
  );

  // HolographBridgeProxy
  let holographBridgeProxy = await genesisDeployHelper(
    hre,
    salt,
    'HolographBridgeProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        holographBridge.address,
        generateInitCode(
          ['address', 'address', 'address', 'address'],
          [
            futureHolographAddress,
            holographRegistryProxy.address,
            holographFactoryProxy.address,
            holographOperatorProxy.address,
          ]
        ),
      ]
    )
  );

  // Holograph
  let holograph = await genesisDeployHelper(
    hre,
    salt,
    'Holograph',
    generateInitCode(
      ['uint32', 'address', 'address', 'address', 'address', 'address', 'address'],
      [
        '0x' + networks[hre.networkName].holographId.toString(16).padStart(8, '0'),
        interfaces.address,
        holographRegistryProxy.address,
        holographFactoryProxy.address,
        holographBridgeProxy.address,
        holographOperatorProxy.address,
        secureStorageProxy.address,
      ]
    )
  );

  // PA1D
  let royalties = await genesisDeployHelper(
    hre,
    salt,
    'PA1D',
    generateInitCode(['address', 'uint256'], [deployer, '0x' + '00'.repeat(32)])
  );
};

export default func;
func.tags = [
  'Interfaces',
  'HolographRegistry',
  'HolographRegistryProxy',
  'HolographOperator',
  'HolographOperatorProxy',
  'SecureStorage',
  'SecureStorageProxy',
  'HolographFactory',
  'HolographFactoryProxy',
  'HolographBridge',
  'HolographBridgeProxy',
  'Holograph',
  'PA1D',
  'DeploySources',
];
func.dependencies = ['HolographGenesis'];
