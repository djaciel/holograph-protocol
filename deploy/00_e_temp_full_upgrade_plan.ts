declare var global: any;
import fs from 'fs';
import Web3 from 'web3';
import { BigNumber, BytesLike } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
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
  gweiToWei,
  askQuestion,
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

  const network = networks[hre.networkName];
  const environment: Environment = getEnvironment();
  const currentNetworkType: NetworkType = network.type;

  const subOneWei = function (input: BigNumber): BigNumber {
    return input.sub(BigNumber.from('1'));
  };

  const salt = hre.deploymentSalt;

  // =============================
  // Set gas parameters
  // =============================

  const MSG_BASE_GAS: BigNumber = BigNumber.from('110000');
  const MSG_GAS_PER_BYTE: BigNumber = BigNumber.from('25');
  const JOB_BASE_GAS: BigNumber = BigNumber.from('160000');
  const JOB_GAS_PER_BYTE: BigNumber = BigNumber.from('35');
  const MIN_GAS_PRICE: BigNumber = BigNumber.from('1'); // 1 WEI
  const GAS_LIMIT: BigNumber = BigNumber.from('10000001');

  const defaultParams: BigNumber[] = [
    MSG_BASE_GAS,
    MSG_GAS_PER_BYTE,
    JOB_BASE_GAS,
    JOB_GAS_PER_BYTE,
    MIN_GAS_PRICE,
    GAS_LIMIT,
  ];

  const networkSpecificParams: { [key: string]: BigNumber[] } = {
    ethereum: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(gweiToWei(BigNumber.from('40'))), // MIN_GAS_PRICE, // 40 GWEI
      GAS_LIMIT,
    ],
    ethereumTestnetGoerli: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(gweiToWei(BigNumber.from('5'))), // MIN_GAS_PRICE, // 5 GWEI
      GAS_LIMIT,
    ],

    binanceSmartChain: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      BigNumber.from('180000'),
      BigNumber.from('40'),
      subOneWei(gweiToWei(BigNumber.from('3'))), // MIN_GAS_PRICE, // 3 GWEI
      GAS_LIMIT,
    ],
    binanceSmartChainTestnet: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      BigNumber.from('180000'),
      BigNumber.from('40'),
      subOneWei(gweiToWei(BigNumber.from('1'))), // MIN_GAS_PRICE, // 1 GWEI
      GAS_LIMIT,
    ],

    avalanche: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(gweiToWei(BigNumber.from('30'))), // MIN_GAS_PRICE, // 30 GWEI
      GAS_LIMIT,
    ],
    avalancheTestnet: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(gweiToWei(BigNumber.from('30'))), // MIN_GAS_PRICE, // 30 GWEI
      GAS_LIMIT,
    ],

    polygon: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(gweiToWei(BigNumber.from('200'))), // MIN_GAS_PRICE, // 200 GWEI
      GAS_LIMIT,
    ],
    polygonTestnet: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(gweiToWei(BigNumber.from('5'))), // MIN_GAS_PRICE, // 5 GWEI
      GAS_LIMIT,
    ],

    optimism: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(BigNumber.from('10000000')), // MIN_GAS_PRICE, // 0.01 GWEI
      GAS_LIMIT,
    ],
    optimismTestnetGoerli: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(gweiToWei(BigNumber.from('5'))), // MIN_GAS_PRICE, // 5 GWEI
      GAS_LIMIT,
    ],

    arbitrumOne: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(BigNumber.from('100000000')), // MIN_GAS_PRICE, // 0.1 GWEI
      GAS_LIMIT,
    ],
    arbitrumTestnetGoerli: [
      MSG_BASE_GAS,
      MSG_GAS_PER_BYTE,
      JOB_BASE_GAS,
      JOB_GAS_PER_BYTE,
      subOneWei(gweiToWei(BigNumber.from('5'))), // MIN_GAS_PRICE, // 5 GWEI
      GAS_LIMIT,
    ],
  };

  // =============================
  // Set supported networks
  // =============================

  const networkType: NetworkType = network.type;
  const networkKeys: string[] = Object.keys(networks);
  let supportedNetworkNames: string[] = [];
  let supportedNetworks: Network[] = [];
  let chainIds: number[] = [];
  let gasParameters: BigNumber[][] = [];
  for (let i = 0, l = networkKeys.length; i < l; i++) {
    const key: string = networkKeys[i];
    const value: Network = networks[key];
    if (value.active && value.type == networkType) {
      supportedNetworkNames.push(key);
      supportedNetworks.push(value);
      if (value.holographId > 0) {
        if (value.holographId == network.holographId) {
          chainIds.push(0);
          if (key in networkSpecificParams) {
            gasParameters.push(networkSpecificParams[key]!);
          } else {
            gasParameters.push(defaultParams);
          }
        }
        chainIds.push(value.holographId);
        if (key in networkSpecificParams) {
          gasParameters.push(networkSpecificParams[key]!);
        } else {
          gasParameters.push(defaultParams);
        }
      }
    }
  }

  const holograph = await hre.ethers.getContract('Holograph', deployer);

  // =============================
  // Derive future addresses
  // =============================

  // OVM_GasPriceOracle
  const futureOptimismGasPriceOracleAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'OVM_GasPriceOracle',
    generateInitCode(['uint256', 'uint256', 'uint256', 'uint256', 'uint256'], [0, 0, 0, 0, 0])
  );
  hre.deployments.log('the future "OVM_GasPriceOracle" address is', futureOptimismGasPriceOracleAddress);

  // LayerZeroModule
  const futureLayerZeroModuleAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'LayerZeroModule',
    generateInitCode(
      [
        'address',
        'address',
        'address',
        'address',
        'uint32[]',
        'struct(uint256,uint256,uint256,uint256,uint256,uint256)[]',
      ],
      [zeroAddress, zeroAddress, zeroAddress, zeroAddress, [], []]
    )
  );
  hre.deployments.log('the future "LayerZeroModule" address is', futureLayerZeroModuleAddress);

  // LayerZeroModuleProxy
  const futureLayerZeroModuleProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'LayerZeroModuleProxy',
    generateInitCode(
      ['address', 'bytes'],
      [
        zeroAddress,
        generateInitCode(
          [
            'address',
            'address',
            'address',
            'address',
            'uint32[]',
            'struct(uint256,uint256,uint256,uint256,uint256,uint256)[]',
          ],
          [zeroAddress, zeroAddress, zeroAddress, zeroAddress, [], []]
        ),
      ]
    )
  );
  hre.deployments.log('the future "LayerZeroModuleProxy" address is', futureLayerZeroModuleProxyAddress);

  // If dry run just log the future addresses and exit
  const dryRun = process.env.DRY_RUN;
  if (dryRun && dryRun === 'true') {
    console.log(`Dry run. Exiting...`);
    process.exit();
  }

  if (!dryRun || dryRun === 'false') {
    const answer = await askQuestion(`Continue? (y/n)\n`);
    if (answer !== 'y') {
      console.log(`Exiting...`);
      process.exit();
    }
  }

  console.log(`Deploying...`);

  // =============================
  // Deploy contracts
  // =============================

  // OVM_GasPriceOracle
  let optimismGasPriceOracleDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureOptimismGasPriceOracleAddress,
    'latest',
  ]);
  if (optimismGasPriceOracleDeployedCode == '0x' || optimismGasPriceOracleDeployedCode == '') {
    hre.deployments.log('"OVM_GasPriceOracle" bytecode not found, need to deploy"');
    let optimismGasPriceOracle = await genesisDeployHelper(
      hre,
      salt,
      'OVM_GasPriceOracle',
      generateInitCode(
        ['uint256', 'uint256', 'uint256', 'uint256', 'uint256'],
        [
          1000000, // gasPrice == 1 (since scalar is with 6 decimal places)
          100000000000, // l1BaseFee == 100 GWEI
          2100, // overhead
          1000000, // scalar (since division does not work well in non-decimal numbers, we multiply and then divide by scalar after)
          6, // decimals
        ]
      ),
      futureOptimismGasPriceOracleAddress
    );
  } else {
    hre.deployments.log('"OVM_GasPriceOracle" is already deployed..');
  }

  // LayerZeroModule
  let layerZeroModuleDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureLayerZeroModuleAddress,
    'latest',
  ]);
  if (layerZeroModuleDeployedCode == '0x' || layerZeroModuleDeployedCode == '') {
    hre.deployments.log('"LayerZeroModule" bytecode not found, need to deploy"');
    let layerZeroModule = await genesisDeployHelper(
      hre,
      salt,
      'LayerZeroModule',
      generateInitCode(
        [
          'address',
          'address',
          'address',
          'address',
          'uint32[]',
          'struct(uint256,uint256,uint256,uint256,uint256,uint256)[]',
        ],
        [zeroAddress, zeroAddress, zeroAddress, zeroAddress, [], []]
      ),
      futureLayerZeroModuleAddress
    );
  } else {
    hre.deployments.log('"LayerZeroModule" is already deployed..');
  }

  // LayerZeroModuleProxy
  let layerZeroModuleProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureLayerZeroModuleProxyAddress,
    'latest',
  ]);
  if (layerZeroModuleProxyDeployedCode == '0x' || layerZeroModuleProxyDeployedCode == '') {
    hre.deployments.log('"LayerZeroModuleProxy" bytecode not found, need to deploy"');
    let layerZeroModuleProxy = await genesisDeployHelper(
      hre,
      salt,
      'LayerZeroModuleProxy',
      generateInitCode(
        ['address', 'bytes'],
        [
          futureLayerZeroModuleAddress,
          generateInitCode(
            [
              'address',
              'address',
              'address',
              'address',
              'uint32[]',
              'struct(uint256,uint256,uint256,uint256,uint256,uint256)[]',
            ],
            [
              await holograph.getBridge(),
              await holograph.getInterfaces(),
              await holograph.getOperator(),
              futureOptimismGasPriceOracleAddress,
              chainIds,
              gasParameters,
            ]
          ),
        ]
      ),
      futureLayerZeroModuleProxyAddress
    );
  } else {
    hre.deployments.log('"LayerZeroModuleProxy" is already deployed..');
  }

  let lzEndpoint = networks[hre.networkName].lzEndpoint.toLowerCase();
  const layerZeroModuleProxy = await hre.ethers.getContract('LayerZeroModuleProxy', deployer);
  const layerZeroModule = (await hre.ethers.getContractAt(
    'LayerZeroModule',
    layerZeroModuleProxy.address,
    deployer
  )) as Contract;

  if ((await layerZeroModule.getLZEndpoint()).toLowerCase() != lzEndpoint) {
    const lzTx = await MultisigAwareTx(
      hre,
      deployer,
      'LayerZeroModule',
      layerZeroModule,
      await layerZeroModule.populateTransaction.setLZEndpoint(lzEndpoint, {
        ...(await txParams({
          hre,
          from: deployer,
          to: layerZeroModule,
          data: layerZeroModule.populateTransaction.setLZEndpoint(lzEndpoint),
        })),
      })
    );
    hre.deployments.log('Transaction hash:', lzTx.hash);
    await lzTx.wait();
    hre.deployments.log(`Registered lzEndpoint to: ${await layerZeroModule.getLZEndpoint()}`);
  } else {
    hre.deployments.log(`lzEndpoint is already registered to: ${await layerZeroModule.getLZEndpoint()}`);
  }

  // =================================
  // Setup DropsPriceOracle
  // =================================

  const definedOracleNames = {
    avalanche: 'Avalanche',
    avalancheTestnet: 'AvalancheTestnet',
    binanceSmartChain: 'BinanceSmartChain',
    binanceSmartChainTestnet: 'BinanceSmartChainTestnet',
    ethereum: 'Ethereum',
    ethereumTestnetGoerli: 'EthereumTestnetGoerli',
    polygon: 'Polygon',
    polygonTestnet: 'PolygonTestnet',
    optimism: 'Optimism',
    optimismTestnetGoerli: 'OptimismTestnetGoerli',
    arbitrumNova: 'ArbitrumNova',
    arbitrumOne: 'ArbitrumOne',
    arbitrumTestnetGoerli: 'ArbitrumTestnetGoerli',
    mantle: 'Mantle',
    mantleTestnet: 'MantleTestnet',
    base: 'Base',
    baseTestnetGoerli: 'BaseTestnetGoerli',
    zora: 'Zora',
    zoraTestnetGoerli: 'ZoraTestnetGoerli',
  };

  let targetDropsPriceOracle = 'DummyDropsPriceOracle';
  if (network.key in definedOracleNames) {
    targetDropsPriceOracle = 'DropsPriceOracle' + definedOracleNames[network.key];
  } else {
    if (environment == Environment.mainnet || (network.key != 'localhost' && network.key != 'hardhat')) {
      throw new Error('Drops price oracle not created for network yet!');
    }
  }

  hre.deployments.log('targetDropsPriceOracle is', targetDropsPriceOracle);

  // Deploy network specific DropsPriceOracle source contract
  const futureDropsPriceOracleAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    targetDropsPriceOracle,
    generateInitCode([], [])
  );
  hre.deployments.log('the future "' + targetDropsPriceOracle + '" address is', futureDropsPriceOracleAddress);

  // Get DropsPriceOracle source contract code to see if it already exists
  let dropsPriceOracleDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsPriceOracleAddress,
    'latest',
  ]);

  // If DropsPriceOracle source contract is not deployed, deploy it
  if (dropsPriceOracleDeployedCode == '0x' || dropsPriceOracleDeployedCode == '') {
    definedOracleNames;
    hre.deployments.log('"' + targetDropsPriceOracle + '" bytecode not found, need to deploy"');
    let dropsPriceOracle = await genesisDeployHelper(
      hre,
      salt,
      targetDropsPriceOracle,
      generateInitCode([], []),
      futureDropsPriceOracleAddress
    );
  } else {
    hre.deployments.log('"' + targetDropsPriceOracle + '" is already deployed.');
  }

  // Deploy DropsPriceOracleProxy source contract
  const futureDropsPriceOracleProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'DropsPriceOracleProxy',
    generateInitCode([], [])
  );
  hre.deployments.log('the future "DropsPriceOracleProxy" address is', futureDropsPriceOracleProxyAddress);

  // Get DropsPriceOracleProxy source contract code to see if it already exists
  let dropsPriceOracleProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsPriceOracleProxyAddress,
    'latest',
  ]);

  // If DropsPriceOracleProxy source contract is not deployed, deploy it
  if (dropsPriceOracleProxyDeployedCode == '0x' || dropsPriceOracleProxyDeployedCode == '') {
    hre.deployments.log('"DropsPriceOracleProxy" bytecode not found, need to deploy"');
    let dropsPriceOracleProxy = await genesisDeployHelper(
      hre,
      salt,
      'DropsPriceOracleProxy',
      generateInitCode(['address', 'bytes'], [futureDropsPriceOracleAddress, generateInitCode([], [])]),
      futureDropsPriceOracleProxyAddress
    );
  } else {
    // If DropsPriceOracleProxy source contract is deployed, check if it references the correct DropsPriceOracle
    hre.deployments.log('"DropsPriceOracleProxy" is already deployed.');
    hre.deployments.log('Checking for reference to correct "' + targetDropsPriceOracle + '" deployment.');
    // need to check here if source reference is correct
    futureDropsPriceOracleProxyAddress;
    const dropsPriceOracleProxy = await hre.ethers.getContract('DropsPriceOracleProxy', deployer);
    let priceOracleSource = await dropsPriceOracleProxy.getDropsPriceOracle();

    // If DropsPriceOracleProxy source contract does not reference the correct DropsPriceOracle, update it
    if (priceOracleSource != futureDropsPriceOracleAddress) {
      hre.deployments.log('"DropsPriceOracleProxy" references incorrect version of "' + targetDropsPriceOracle + '".');
      const setDropsPriceOracleTx = await MultisigAwareTx(
        hre,
        deployer,
        'DropsPriceOracleProxy',
        dropsPriceOracleProxy,
        await dropsPriceOracleProxy.populateTransaction.setDropsPriceOracle(futureDropsPriceOracleAddress, {
          ...(await txParams({
            hre,
            from: deployer,
            to: dropsPriceOracleProxy,
            data: dropsPriceOracleProxy.populateTransaction.setDropsPriceOracle(futureDropsPriceOracleAddress),
          })),
        })
      );
      hre.deployments.log('Transaction hash:', setDropsPriceOracleTx.hash);
      await setDropsPriceOracleTx.wait();
      hre.deployments.log('"DropsPriceOracleProxy" reference updated.');
    } else {
      hre.deployments.log('"DropsPriceOracleProxy" references correct version of "' + targetDropsPriceOracle + '".');
    }
  }

  const holographRegistryProxy = await hre.ethers.getContract('HolographRegistryProxy', deployer);
  const holographRegistry = ((await hre.ethers.getContract('HolographRegistry', deployer)) as Contract).attach(
    holographRegistryProxy.address
  );

  const futureCxipErc721Address = await genesisDeriveFutureAddress(
    hre,
    salt,
    'CxipERC721',
    generateInitCode(['address'], [deployer.address])
  );
  hre.deployments.log('the future "CxipERC721" address is', futureCxipErc721Address);

  // CxipERC721
  let cxipErc721DeployedCode: string = await hre.provider.send('eth_getCode', [futureCxipErc721Address, 'latest']);
  if (cxipErc721DeployedCode == '0x' || cxipErc721DeployedCode == '') {
    hre.deployments.log('"CxipERC721" bytecode not found, need to deploy"');
    let cxipErc721 = await genesisDeployHelper(
      hre,
      salt,
      'CxipERC721',
      generateInitCode(['address'], [deployer.address]),
      futureCxipErc721Address
    );
  } else {
    hre.deployments.log('"CxipERC721" is already deployed.');
  }

  // ==============================================
  // Deploy Drops Metadata Renderer and Proxy
  // ==============================================

  // Deploy DropsMetadataRenderer source contract
  const futureDropsMetadataRendererAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'DropsMetadataRenderer',
    generateInitCode([], [])
  );
  hre.deployments.log('the future "DropsMetadataRenderer" address is', futureDropsMetadataRendererAddress);
  let dropsMetadataRendererDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsMetadataRendererAddress,
    'latest',
  ]);

  if (dropsMetadataRendererDeployedCode == '0x' || dropsMetadataRendererDeployedCode == '') {
    hre.deployments.log('"DropsMetadataRenderer" bytecode not found, need to deploy"');
    let dropsMetadataRenderer = await genesisDeployHelper(
      hre,
      salt,
      'DropsMetadataRenderer',
      generateInitCode([], []),
      futureDropsMetadataRendererAddress
    );
  } else {
    hre.deployments.log('"DropsMetadataRenderer" is already deployed.');
  }

  // Deploy DropsMetadataRendererProxy source contract
  const futureDropsMetadataRendererProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'DropsMetadataRendererProxy',
    generateInitCode(['address', 'bytes'], [futureDropsMetadataRendererAddress, generateInitCode([], [])])
  );
  let dropsMetadataRendererProxy = (await hre.ethers.getContractAt(
    'DropsMetadataRendererProxy',
    futureDropsMetadataRendererProxyAddress,
    deployer
  )) as Contract;
  hre.deployments.log('the future "DropsMetadataRendererProxy" address is', futureDropsMetadataRendererProxyAddress);
  let dropsMetadataRendererProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsMetadataRendererProxyAddress,
    'latest',
  ]);
  if (dropsMetadataRendererProxyDeployedCode == '0x' || dropsMetadataRendererProxyDeployedCode == '') {
    hre.deployments.log('"DropsMetadataRendererProxy" bytecode not found, need to deploy"');
    dropsMetadataRendererProxy = await genesisDeployHelper(
      hre,
      salt,
      'DropsMetadataRendererProxy',
      generateInitCode(['address', 'bytes'], [futureDropsMetadataRendererAddress, generateInitCode([], [])]),
      futureDropsMetadataRendererProxyAddress
    );
  } else {
    hre.deployments.log('"DropsMetadataRendererProxy" is already deployed.');
    hre.deployments.log('Checking "DropsMetadataRendererProxy" source.');
    if (
      (await dropsMetadataRendererProxy.getDropsMetadataRenderer()).toLowerCase() !=
      futureDropsMetadataRendererProxyAddress.toLowerCase()
    ) {
      hre.deployments.log('Need to set "DropsMetadataRendererProxy" source.');
      const setDropsMetadataRendererTx = await MultisigAwareTx(
        hre,
        deployer,
        'DropsMetadataRendererProxy',
        dropsMetadataRendererProxy,
        await dropsMetadataRendererProxy.populateTransaction.setDropsMetadataRenderer(
          futureDropsMetadataRendererProxyAddress,
          {
            ...(await txParams({
              hre,
              from: deployer,
              to: dropsMetadataRendererProxy,
              data: await dropsMetadataRendererProxy.populateTransaction.setDropsMetadataRenderer(
                futureDropsMetadataRendererProxyAddress
              ),
            })),
          }
        )
      );
      hre.deployments.log('Transaction hash:', setDropsMetadataRendererTx.hash);
      await setDropsMetadataRendererTx.wait();
      hre.deployments.log(
        `Registered "DropsMetadataRenderer" to: ${await dropsMetadataRendererProxy.getDropsMetadataRenderer()}`
      );
    } else {
      hre.deployments.log('"DropsMetadataRendererProxy" source is correct.');
    }
  }

  // ==============================================
  // Deploy Editions Metadata Renderer and Proxy
  // ==============================================

  // Deploy EditionsMetadataRenderer source contract
  const futureEditionsMetadataRendererAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'EditionsMetadataRenderer',
    generateInitCode([], [])
  );
  hre.deployments.log('the future "EditionsMetadataRenderer" address is', futureEditionsMetadataRendererAddress);
  let editionsMetadataRendererDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureEditionsMetadataRendererAddress,
    'latest',
  ]);
  if (editionsMetadataRendererDeployedCode == '0x' || editionsMetadataRendererDeployedCode == '') {
    hre.deployments.log('"EditionsMetadataRenderer" bytecode not found, need to deploy"');
    let editionsMetadataRenderer = await genesisDeployHelper(
      hre,
      salt,
      'EditionsMetadataRenderer',
      generateInitCode([], []),
      futureEditionsMetadataRendererAddress
    );
  } else {
    hre.deployments.log('"EditionsMetadataRenderer" is already deployed.');
  }

  // Deploy EditionsMetadataRendererProxy source contract
  const futureEditionsMetadataRendererProxyAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'EditionsMetadataRendererProxy',
    generateInitCode(['address', 'bytes'], [futureEditionsMetadataRendererAddress, generateInitCode([], [])])
  );
  let editionsMetadataRendererProxy = (await hre.ethers.getContractAt(
    'EditionsMetadataRendererProxy',
    futureEditionsMetadataRendererProxyAddress,
    deployer
  )) as Contract;
  hre.deployments.log(
    'the future "EditionsMetadataRendererProxy" address is',
    futureEditionsMetadataRendererProxyAddress
  );
  let editionsMetadataRendererProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureEditionsMetadataRendererProxyAddress,
    'latest',
  ]);
  if (editionsMetadataRendererProxyDeployedCode == '0x' || editionsMetadataRendererProxyDeployedCode == '') {
    hre.deployments.log('"EditionsMetadataRendererProxy" bytecode not found, need to deploy"');
    editionsMetadataRendererProxy = await genesisDeployHelper(
      hre,
      salt,
      'EditionsMetadataRendererProxy',
      generateInitCode(['address', 'bytes'], [futureEditionsMetadataRendererAddress, generateInitCode([], [])]),
      futureEditionsMetadataRendererProxyAddress
    );
  } else {
    hre.deployments.log('"EditionsMetadataRendererProxy" is already deployed.');
    hre.deployments.log('Checking "EditionsMetadataRendererProxy" source.');
    if (
      (await editionsMetadataRendererProxy.getEditionsMetadataRenderer()).toLowerCase() !=
      futureEditionsMetadataRendererAddress.toLowerCase()
    ) {
      hre.deployments.log('Need to set "EditionsMetadataRendererProxy" source.');
      const setEditionsMetadataRendererTx = await MultisigAwareTx(
        hre,
        deployer,
        'EditionsMetadataRendererProxy',
        editionsMetadataRendererProxy,
        await editionsMetadataRendererProxy.populateTransaction.setEditionsMetadataRenderer(
          futureEditionsMetadataRendererAddress,
          {
            ...(await txParams({
              hre,
              from: deployer,
              to: editionsMetadataRendererProxy,
              data: await editionsMetadataRendererProxy.populateTransaction.setEditionsMetadataRenderer(
                futureEditionsMetadataRendererAddress
              ),
            })),
          }
        )
      );
      hre.deployments.log('Transaction hash:', setEditionsMetadataRendererTx.hash);
      await setEditionsMetadataRendererTx.wait();
      hre.deployments.log(
        `Registered "EditionsMetadataRenderer" to: ${await editionsMetadataRendererProxy.getEditionsMetadataRenderer()}`
      );
    } else {
      hre.deployments.log('"EditionsMetadataRendererProxy" source is correct.');
    }
  }

  // ==============================================
  // Deploy HolographDropERC721
  // ==============================================

  // Deploy the HolographDropERC721 custom contract source
  const HolographDropERC721InitCode = generateInitCode(
    [
      'tuple(address,address,address,address,uint64,uint16,bool,tuple(uint104,uint32,uint64,uint64,uint64,uint64,bytes32),address,bytes)',
    ],
    [
      [
        zeroAddress, // holographERC721TransferHelper
        zeroAddress, // marketFilterAddress (opensea)
        deployer.address, // initialOwner
        deployer.address, // fundsRecipient
        0, // 1000 editions
        1000, // 10% royalty
        false, // enableOpenSeaRoyaltyRegistry
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

  let HolographDropERC721DeployedCode: string = await hre.provider.send('eth_getCode', [
    futureHolographDropERC721Address,
    'latest',
  ]);

  if (HolographDropERC721DeployedCode == '0x' || HolographDropERC721DeployedCode == '') {
    hre.deployments.log('"HolographDropERC721" bytecode not found, need to deploy"');
    let HolographDropERC721 = await genesisDeployHelper(
      hre,
      salt,
      'HolographDropERC721',
      HolographDropERC721InitCode,
      futureHolographDropERC721Address
    );
  } else {
    hre.deployments.log('"HolographDropERC721" is already deployed.');
  }

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
  let contracts: string[] = [
    'OVM_GasPriceOracle',
    'LayerZeroModuleProxy',
    'LayerZeroModule',
    'DropsPriceOracleProxy',
    'CxipERC721',
    'HolographDropERC721',
    'EditionsMetadataRenderer',
    'DropsMetadataRenderer',
    'EditionsMetadataRendererProxy',
    'DropsMetadataRendererProxy',
    'HolographOperator',
  ];
  for (let i: number = 0, l: number = contracts.length; i < l; i++) {
    console.log(`Verifying "${contracts[i]}"...`);
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
func.tags = ['TEMP_FULL_UPGRADE_PLAN'];
func.dependencies = [];
