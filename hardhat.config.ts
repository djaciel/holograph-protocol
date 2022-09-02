declare var global: any;
import fs from 'fs';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'hardhat-deploy-holographed';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import { types, task, HardhatUserConfig } from 'hardhat/config';
import 'hardhat-holograph-contract-builder';
import networks from './config/networks';
import dotenv from 'dotenv';
dotenv.config();

const getGitBranch = function () {
  const acceptableBranches = ['mainnet', 'testnet', 'develop'];
  const contents = fs.readFileSync('./.git/HEAD', 'utf8');
  const branch = contents.trim().split('ref: refs/heads/')[1];
  if (acceptableBranches.includes(branch)) {
    return branch;
  } else {
    return 'develop';
  }
};

const SOLIDITY_VERSION = process.env.SOLIDITY_VERSION || '0.8.13';

const MNEMONIC = process.env.MNEMONIC || 'test '.repeat(11) + 'junk';
const DEPLOYER = process.env.DEPLOYER || '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

const RINKEBY_PRIVATE_KEY = process.env.RINKEBY_PRIVATE_KEY! || DEPLOYER;
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY || DEPLOYER;

const MATIC_PRIVATE_KEY = process.env.MATIC_PRIVATE_KEY || DEPLOYER;
const MUMBAI_PRIVATE_KEY = process.env.MUMBAI_PRIVATE_KEY || DEPLOYER;
const FUJI_PRIVATE_KEY = process.env.FUJI_PRIVATE_KEY || DEPLOYER;

const CXIP_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY || DEPLOYER;

const ETHERSCAN_API_KEY: string = process.env.ETHERSCAN_API_KEY || '';
const POLYGONSCAN_API_KEY: string = process.env.POLYGONSCAN_API_KEY || '';
const AVALANCHE_API_KEY: string = process.env.AVALANCHE_API_KEY || '';

const DEPLOYMENT_SALT = parseInt(process.env.DEPLOYMENT_SALT || '0');

const DEPLOYMENT_PATH = process.env.DEPLOYMENT_PATH || 'deployments';

global.__DEPLOYMENT_SALT = '0x' + DEPLOYMENT_SALT.toString(16).padStart(64, '0');

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
            fs.writeFileSync(deployDir + '/' + file, JSON.stringify(data, undefined, 2));
          }
        }
      }
    };
    if (!fs.existsSync('./abi')) {
      fs.mkdirSync('./abi');
    } else {
      recursiveDelete('./abi');
    }
    extractABIs('./artifacts/contracts', './abi');
  });

/**
 * Go to https://hardhat.org/config/ to learn more
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  paths: {
    deployments: DEPLOYMENT_PATH + '/' + getGitBranch(),
  },
  defaultNetwork: 'localhost',
  external: {
    deployments: {
      arbitrum: ['externalDeployments/arbitrum'],
      arbitrum_rinkeby: ['externalDeployments/arbitrum_rinkeby'],
      aurora: ['externalDeployments/aurora'],
      aurora_testnet: ['externalDeployments/aurora_testnet'],
      avax: ['externalDeployments/avax'],
      bsc: ['externalDeployments/bsc'],
      bsc_testnet: ['externalDeployments/bsc_testnet'],
      cronos: ['externalDeployments/cronos'],
      cronos_testnet: ['externalDeployments/cronos_testnet'],
      cxip: ['externalDeployments/cxip'],
      eth: ['externalDeployments/eth'],
      eth_goerli: ['externalDeployments/eth_goerli'],
      eth_kovan: ['externalDeployments/eth_kovan'],
      eth_rinkeby: ['externalDeployments/eth_rinkeby'],
      eth_ropsten: ['externalDeployments/eth_ropsten'],
      ftm: ['externalDeployments/ftm'],
      ftm_testnet: ['externalDeployments/ftm_testnet'],
      fuji: ['externalDeployments/fuji'],
      gno: ['externalDeployments/gno'],
      gno_sokol: ['externalDeployments/gno_sokol'],
      localhost: ['externalDeployments/localhost'],
      localhost2: ['externalDeployments/localhost2'],
      matic: ['externalDeployments/matic'],
      mumbai: ['externalDeployments/mumbai'],
      optimism: ['externalDeployments/optimism'],
      optimism_kovan: ['externalDeployments/optimism_kovan'],
    },
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
    eth: {
      url: networks.eth.rpc,
      chainId: networks.eth.chain,
      accounts: [MAINNET_PRIVATE_KEY],
    },
    eth_rinkeby: {
      url: networks.eth_rinkeby.rpc,
      chainId: networks.eth_rinkeby.chain,
      accounts: [RINKEBY_PRIVATE_KEY],
    },
    matic: {
      url: networks.matic.rpc,
      chainId: networks.matic.chain,
      accounts: [MATIC_PRIVATE_KEY] || '',
    },
    mumbai: {
      url: networks.mumbai.rpc,
      chainId: networks.mumbai.chain,
      accounts: [MUMBAI_PRIVATE_KEY],
    },
    fuji: {
      url: networks.fuji.rpc,
      chainId: networks.fuji.chain,
      accounts: [FUJI_PRIVATE_KEY],
    },
    cxip: {
      url: networks.cxip.rpc,
      chainId: networks.cxip.chain,
      accounts: [CXIP_PRIVATE_KEY],
    },
    coverage: {
      url: 'http://127.0.0.1:8555',
    },
  },
  namedAccounts: {
    deployer: 0,
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
    enabled: process.env.REPORT_GAS ? true : false,
    currency: 'USD',
    gasPrice: 100,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      rinkeby: ETHERSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
      avalanche: AVALANCHE_API_KEY,
      avalancheFujiTestnet: AVALANCHE_API_KEY,
    },
  },
  hardhatHolographContractBuilder: {
    runOnCompile: true,
    verbose: false,
  },
};

export default config;
