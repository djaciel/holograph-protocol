declare var global: any;
import fs from 'fs';
import path from 'path';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import '@holographxyz/hardhat-deploy-holographed';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@nomicfoundation/hardhat-foundry';
import { subtask } from 'hardhat/config';
import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from 'hardhat/builtin-tasks/task-names';

import { types, task, HardhatUserConfig } from 'hardhat/config';
import '@holographxyz/hardhat-holograph-contract-builder';
import { BigNumber } from 'ethers';
import { Environment, getEnvironment } from '@holographxyz/environment';
import { NetworkType, Network, Networks, networks } from '@holographxyz/networks';
import { GasService } from './scripts/utils/gas-service';
import dotenv from 'dotenv';
//import * as tenderly from '@tenderly/hardhat-tenderly';
import { network } from 'hardhat';
dotenv.config();

let tenderlyNetwork = {};
let tenderlyConfig = {};
/*
if (process.env.USE_TENDERLY && process.env.USE_TENDERLY == 'true') {
  tenderly.setup();
  tenderlyNetwork = {
    tenderly: {
      chainId: 5,
      url: 'https://rpc.tenderly.co/fork/<fork-chain-id>',
    },
  };
  tenderlyConfig = {
    tenderly: {
      project: process.env.TENDERLY_PROJECT,
      username: process.env.TENDERLY_USERNAME,
      privateVerification: false,
      forkNetwork: '<fork-chain-id>',
    },
  };
}
*/

function getRemappings() {
  return fs
    .readFileSync('remappings.txt', 'utf8')
    .split('\n')
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split('='));
}

function hex2buffer(input: string): Uint8Array {
  input = input.toLowerCase().trim();
  if (input.startsWith('0x')) {
    input = input.substring(2).trim();
  }
  if (input.length % 2 !== 0) {
    input = '0' + input;
  }
  let bytes: number[] = [];
  for (let i = 0; i < input.length; i += 2) {
    bytes.push(parseInt(input.substring(i, i + 2), 16));
  }
  return Uint8Array.from(bytes);
}

const currentEnvironment = Environment[getEnvironment()];
process.stdout.write(`\n👉 Environment: ${currentEnvironment}\n\n`);

const SOLIDITY_VERSION = process.env.SOLIDITY_VERSION || '0.8.13';

const MNEMONIC = process.env.MNEMONIC || 'test '.repeat(11) + 'junk';
const DEPLOYER = process.env.DEPLOYER || '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

if (
  process.env.SUPER_COLD_STORAGE_ENABLED &&
  process.env.SUPER_COLD_STORAGE_ENABLED == 'true' &&
  process.env.npm_lifecycle_event == 'deploy'
) {
  global.__superColdStorage = {
    address: process.env.SUPER_COLD_STORAGE_ADDRESS,
    domain: process.env.SUPER_COLD_STORAGE_DOMAIN,
    authorization: process.env.SUPER_COLD_STORAGE_AUTHORIZATION, // String.fromCharCode.apply(null, hex2buffer(process.env.SUPER_COLD_STORAGE_AUTHORIZATION)),
    ca: String.fromCharCode.apply(null, hex2buffer(process.env.SUPER_COLD_STORAGE_CA)),
  };
}

const setDeployerKey = function (fallbackKey: string | number): string | number {
  if ('__superColdStorage' in global) {
    return ('super-cold-storage://' + global.__superColdStorage.address) as string;
  } else {
    return fallbackKey;
  }
};

const dynamicNetworks = function (skipLocalhost: boolean = true): unknown {
  let output = {};
  for (const name of Object.keys(networks)) {
    if (name != 'hardhat' && (!skipLocalhost || (skipLocalhost && name != 'localhost' && name != 'localhost2'))) {
      let envKey = name.replace(/([A-Z]{1})/g, '_$1').toUpperCase();
      output[name] = {
        url: process.env[envKey + '_RPC_URL'] || networks[name].rpc,
        chainId: networks[name].chain,
        accounts: [process.env[envKey + '_PRIVATE_KEY'] || DEPLOYER],
      };
    }
  }
  return output;
};

const dynamicExternalDeployments = function (): unknown {
  let output = {};
  for (const name of Object.keys(networks)) {
    if (name != 'hardhat') {
      output[name] = ['node_modules/@holographxyz/holograph-genesis/deployments/' + name];
    }
  }
  return output;
};

const AVALANCHE_PRIVATE_KEY = process.env.AVALANCHE_PRIVATE_KEY || DEPLOYER;
const AVALANCHE_TESTNET_PRIVATE_KEY = process.env.AVALANCHE_TESTNET_PRIVATE_KEY || DEPLOYER;
const BINANCE_SMART_CHAIN_PRIVATE_KEY = process.env.BINANCE_SMART_CHAIN_PRIVATE_KEY || DEPLOYER;
const BINANCE_SMART_CHAIN_TESTNET_PRIVATE_KEY = process.env.BINANCE_SMART_CHAIN_TESTNET_PRIVATE_KEY || DEPLOYER;
const ETHEREUM_PRIVATE_KEY = process.env.ETHEREUM_PRIVATE_KEY || DEPLOYER;
const ETHEREUM_TESTNET_GOERLI_PRIVATE_KEY = process.env.ETHEREUM_TESTNET_GOERLI_PRIVATE_KEY || DEPLOYER;
const ETHEREUM_TESTNET_RINKEBY_PRIVATE_KEY = process.env.ETHEREUM_TESTNET_RINKEBY_PRIVATE_KEY || DEPLOYER;
const POLYGON_PRIVATE_KEY = process.env.POLYGON_PRIVATE_KEY || DEPLOYER;
const POLYGON_TESTNET_PRIVATE_KEY = process.env.POLYGON_TESTNET_PRIVATE_KEY || DEPLOYER;

const selectDeploymentSalt = (): number => {
  let salt;
  switch (currentEnvironment) {
    case Environment.experimental:
      salt = parseInt(process.env.EXPERIMENTAL_DEPLOYMENT_SALT || '1000000');
      if (salt > 9999999 || salt < 1000000) {
        throw new Error('EXPERIMENTAL_DEPLOYMENT_SALT is out of bounds. Allowed range is [1000000-9999999]');
      }
      break;
    case Environment.develop:
      salt = parseInt(process.env.DEVELOP_DEPLOYMENT_SALT || '1000');
      if (salt > 999999 || salt < 1000) {
        throw new Error('DEVELOP_DEPLOYMENT_SALT is out of bounds. Allowed range is [1000-999999]');
      }
      break;
    case Environment.testnet:
      salt = parseInt(process.env.TESTNET_DEPLOYMENT_SALT || '0');
      if (salt > 999 || salt < 0) {
        throw new Error('TESTNET_DEPLOYMENT_SALT is out of bounds. Allowed range is [0-999]');
      }
      break;
    case Environment.mainnet:
      salt = parseInt(process.env.MAINNET_DEPLOYMENT_SALT || '0');
      if (salt > 999 || salt < 0) {
        throw new Error('MAINNET_DEPLOYMENT_SALT is out of bounds. Allowed range is [0-999]');
      }
      break;
    default:
      throw new Error('Unknown Environment provided -> ' + currentEnvironment);
  }
  return salt;
};

const DEPLOYMENT_SALT = selectDeploymentSalt();

const DEPLOYMENT_PATH = process.env.DEPLOYMENT_PATH || 'deployments';

global.__DEPLOYMENT_SALT = '0x' + DEPLOYMENT_SALT.toString(16).padStart(64, '0');

// This subtask runs before the actual hardhat compile task
// THis is used to filter out the contracts/drops folder from compilation since those are handled by foundry
// TODO: Disabled for now
// subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(async (_, __, runSuper) => {
//   const paths = await runSuper();
//   return paths.filter((p) => !p.includes('contracts/drops/'));
// });

// this task runs before the actual hardhat deploy task
task('deploy', 'Deploy contracts').setAction(async (args, hre, runSuper) => {
  let network: Network = networks[hre.network.name];
  if (network.type === NetworkType.localhost) {
    process.env.GAS_LIMIT_MULTIPLIER = '10000';
    process.env.GAS_PRICE_MULTIPLIER = '10000';
    process.env.MAXIMUM_GAS_PRICE = '0';
    process.env.MAXIMUM_GAS_BRIBE = '0';
  }
  // set gas parameters
  global.__gasLimitMultiplier = BigNumber.from(process.env.GAS_LIMIT_MULTIPLIER || '10000');
  global.__gasPriceMultiplier = BigNumber.from(process.env.GAS_PRICE_MULTIPLIER || '10000');
  global.__maxGasPrice = BigNumber.from(process.env.MAXIMUM_GAS_PRICE || '0');
  global.__maxGasBribe = BigNumber.from(process.env.MAXIMUM_GAS_BRIBE || '0');
  // start gas price monitoring service
  process.stdout.write('Loading Gas Price Service\n');
  const gasService: GasService = new GasService(hre.network.name, hre.ethers.provider, 'DEBUG' in process.env);
  process.stdout.write('Seeding Gas Price Service\n');
  await gasService.init();
  process.stdout.write('\nReady to start deployments\n');
  // run the actual hardhat deploy task
  return runSuper(args);
});

task('deploymentsPrettier', 'Adds EOF new line to prevent prettier to change files').setAction(async (args) => {
  if (!fs.existsSync('./deployments')) {
    throw new Error('The directory "deployments" was not found.');
  }

  function getAllFiles(dirPath: string, arrayOfFiles: string[]) {
    const files = fs.readdirSync(dirPath);

    arrayOfFiles = arrayOfFiles || [];

    for (const file of files) {
      if (fs.statSync(dirPath + '/' + file).isDirectory()) {
        arrayOfFiles = getAllFiles(dirPath + '/' + file, arrayOfFiles);
      } else {
        arrayOfFiles.push(path.join(__dirname, dirPath, '/', file));
      }
    }

    return arrayOfFiles;
  }

  function checkIfEoFIsEmpty(fileContent: string) {
    const matches = fileContent.match(/\r?\n$/);
    if (matches) {
      return true;
    }
    return false;
  }

  const files = getAllFiles('./deployments', []);
  for (const file of files) {
    if (file.endsWith('.json')) {
      const fileContents = fs.readFileSync(file, 'utf8');
      if (!checkIfEoFIsEmpty(fileContents)) {
        fs.appendFileSync(file, '\n');
      }
    }
  }
});

task('abi', 'Create standalone ABI files for all smart contracts')
  .addOptionalParam('silent', 'Provide less details in the output', false, types.boolean)
  .setAction(async (args, hre) => {
    if (!fs.existsSync('./artifacts')) {
      throw new Error('The directory "artifacts" was not found. Make sure you run "yarn compile" first.');
    }
    const recursiveDelete = function (dir: string) {
      const files = fs.readdirSync(dir, { withFileTypes: true });
      for (let i = 0, l = files.length; i < l; i++) {
        if (files[i].isDirectory()) {
          recursiveDelete(dir + '/' + files[i].name);
          fs.rmdirSync(dir + '/' + files[i].name);
        } else {
          fs.unlinkSync(dir + '/' + files[i].name);
        }
      }
    };
    const extractABIs = function (sourceDir: string, deployDir: string) {
      const files = fs.readdirSync(sourceDir, { withFileTypes: true });
      for (let i = 0, l = files.length; i < l; i++) {
        const file = files[i].name;
        if (files[i].isDirectory()) {
          extractABIs(sourceDir + '/' + file, deployDir);
        } else {
          if (file.endsWith('.json') && !file.endsWith('.dbg.json')) {
            if (!args.silent) {
              console.log(' -- exporting', file.split('.')[0], 'ABI');
            }
            const data = JSON.parse(fs.readFileSync(sourceDir + '/' + file, 'utf8')).abi;
            fs.writeFileSync(deployDir + '/' + file, JSON.stringify(data, undefined, 2) + '\n');
          }
        }
      }
    };
    if (!fs.existsSync('./abi')) {
      fs.mkdirSync('./abi');
    }
    if (!fs.existsSync('./abi/' + currentEnvironment)) {
      fs.mkdirSync('./abi/' + currentEnvironment);
    } else {
      recursiveDelete('./abi/' + currentEnvironment);
    }
    extractABIs('./artifacts/contracts', './abi/' + currentEnvironment);
  });

/**
 * Go to https://hardhat.org/config/ to learn more
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          for (const [from, to] of getRemappings()) {
            if (line.includes(from)) {
              line = line.replace(from, to);
              break;
            }
          }
        }
        return line;
      },
    }),
  },
  paths: {
    sources: 'contracts',
    cache: 'cache_hardhat',
    deployments: DEPLOYMENT_PATH + '/' + currentEnvironment,
  },
  defaultNetwork: 'localhost',
  external: {
    deployments: dynamicExternalDeployments(),
  },
  networks: {
    localhost: {
      url: networks.localhost.rpc,
      chainId: networks.localhost.chain,
      accounts: {
        mnemonic: MNEMONIC,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 11,
        passphrase: '',
      },
      companionNetworks: {
        // https://github.com/wighawag/hardhat-deploy#companionnetworks
        l2: 'localhost2',
      },
      saveDeployments: false,
    },
    localhost2: {
      url: networks.localhost2.rpc,
      chainId: networks.localhost2.chain,
      accounts: {
        mnemonic: MNEMONIC,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 11,
        passphrase: '',
      },
      companionNetworks: {
        // https://github.com/wighawag/hardhat-deploy#companionnetworks
        l2: 'localhost',
      },
      saveDeployments: false,
    },
    ...dynamicNetworks(),
    ...tenderlyNetwork,
  },
  namedAccounts: {
    deployer: setDeployerKey(0),
    lzEndpoint: 10,
  },
  solidity: {
    version: SOLIDITY_VERSION,
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999,
      },
      metadata: {
        bytecodeHash: 'none',
      },
    },
  },
  mocha: {
    timeout: 1000 * 60 * 60,
  },
  gasReporter: {
    // I prefer my command line tools to not try to connect to a 3rd party site while I am loading private keys into it
    enabled: process.env.PRIVACY_MODE ? false : true,
    // enabled: process.env.COINMARKETCAP_API_KEY !== undefined,
    outputFile: './gasReport.txt', // comment line to get the report on terminal
    noColors: true, // comment line to get the report on terminal
    currency: 'USD',
    coinmarketcap: process.env.COINMARKETCAP_API_KEY || '',
    token: 'ETH',
    gasPriceApi: process.env.PRIVACY_MODE
      ? ''
      : 'https://api.binanceSmartChainscan.com/api?module=proxy&action=ethereumTestnet_gasPrice',
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || '',
      goerli: process.env.ETHERSCAN_API_KEY || '',
      avalanche: process.env.SNOWTRACE_API_KEY || '',
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY || '',
      polygon: process.env.POLYGONSCAN_API_KEY || '',
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || '',
      bsc: process.env.BSCSCAN_API_KEY || '',
      bscTestnet: process.env.BSCSCAN_API_KEY || '',
      optimisticEthereum: process.env.OPTIMISTIC_API_KEY || process.env.OPTIMISM_API_KEY || '',
      optimisticGoerli: process.env.OPTIMISTIC_API_KEY || process.env.OPTIMISM_API_KEY || '',
      arbitrumOne: process.env.ARBISCAN_API_KEY || '',
      arbitrumGoerli: process.env.ARBISCAN_API_KEY || '',
      arbitrumNova: process.env.ARBISCAN_NOVA_API_KEY || '',
      mantle: process.env.MANTLE_API_KEY || '',
      mantleTestnet: process.env.MANTLE_API_KEY || '',
      base: process.env.BASESCAN_API_KEY || '',
      baseTestnetGoerli: process.env.BASESCAN_API_KEY || '',
      zora: process.env.ZORAENERGY_API_KEY || '',
      zoraTestnetGoerli: process.env.ZORAENERGY_API_KEY || '',
    },
    customChains: [
      {
        network: 'arbitrumNova',
        chainId: 42170,
        urls: {
          apiURL: 'https://api-nova.arbiscan.io/api',
          browserURL: 'https://nova.arbiscan.io',
        },
      },
      {
        network: 'mantle',
        chainId: 5000,
        urls: {
          apiURL: 'https://explorer.mantle.xyz/api',
          browserURL: 'https://explorer.mantle.xyz',
        },
      },
      {
        network: 'mantleTestnet',
        chainId: 5001,
        urls: {
          apiURL: 'https://explorer.testnet.mantle.xyz/api',
          browserURL: 'https://explorer.testnet.mantle.xyz',
        },
      },
      {
        network: 'base',
        chainId: 8453,
        urls: {
          apiURL: 'https://api.basescan.org/api',
          browserURL: 'https://basescan.org',
        },
      },
      {
        network: 'baseTestnetGoerli',
        chainId: 84531,
        urls: {
          apiURL: 'https://api-goerli.basescan.org/api',
          browserURL: 'https://goerli.basescan.org',
        },
      },
    ],
  },
  hardhatHolographContractBuilder: {
    runOnCompile: true,
    verbose: false,
  },
  ...tenderlyConfig,
};

// Allow hardhat to use short network names
function mapNetworkKeysByShortKey(networks: Networks) {
  for (let key in networks) {
    // Not all networks in @holographxyz/networks are supported by hardhat
    if (key in config.networks!) {
      let shortKey = networks[key]!.shortKey;
      config.networks![shortKey] = config.networks![key];
    }
  }

  return config;
}

mapNetworkKeysByShortKey(networks as Networks);

export default config;
