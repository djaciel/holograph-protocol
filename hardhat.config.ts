import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'hardhat-deploy';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import { HardhatUserConfig } from 'hardhat/config';
import dotenv from 'dotenv';
dotenv.config();

// avoid hardhat error if no key in .env file
const MOCK_PRIVATE_KEY = '0x' + '11'.repeat(32);

const ROPSTEN_URL = process.env.ROPSTEN_URL || '';
const ROPSTEN_PRIVATE_KEY =
  process.env.ROPSTEN_PRIVATE_KEY! || MOCK_PRIVATE_KEY;

const RINKEBY_URL = process.env.RINKEBY_URL || '';
const RINKEBY_PRIVATE_KEY =
  process.env.RINKEBY_PRIVATE_KEY! || MOCK_PRIVATE_KEY;

const MAINNET_URL = process.env.MAINNET_URL || '';
const MAINNET_PRIVATE_KEY =
  process.env.MAINNET_PRIVATE_KEY || '0x' + '11'.repeat(32);

const CXIP_URL = process.env.MAINNET_URL || '';
const CXIP_PRIVATE_KEY =
  process.env.MAINNET_PRIVATE_KEY || '0x' + '11'.repeat(32);

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

/**
 * Go to https://hardhat.org/config/ to learn more
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  networks: {
    localhost: {},
    hardhat: {
      blockGasLimit: 30_000_000,
    },
    mainnet: {
      url: MAINNET_URL,
      accounts: [MAINNET_PRIVATE_KEY],
    },
    rinkeby: {
      url: RINKEBY_URL,
      accounts: [RINKEBY_PRIVATE_KEY],
    },
    cxip: {
      url: CXIP_URL,
      accounts: [CXIP_PRIVATE_KEY],
    },
    coverage: {
      url: 'http://127.0.0.1:8555',
    },
  },
  namedAccounts: {
    deployer: 0,
    purchaser: 0,
  },
  solidity: {
    version: process.env.SOLIDITY_VERSION ? process.env.SOLIDITY_VERSION : '0.8.12',
    settings: {
      optimizer: {
        enabled: true,
        runs: 99999,
      },
    },
  },
  mocha: {
    timeout: 60000,
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
    currency: 'USD',
    gasPrice: 100,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};

export default config;
