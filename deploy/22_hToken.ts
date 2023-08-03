declare var global: any;
import fs from 'fs';
import Web3 from 'web3';
import { BigNumberish, BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {
  LeanHardhatRuntimeEnvironment,
  Signature,
  hreSplit,
  zeroAddress,
  StrictECDSA,
  generateErc20Config,
  genesisDeployHelper,
  generateInitCode,
  genesisDeriveFutureAddress,
  remove0x,
  txParams,
} from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { HolographERC20Event, ConfigureEvents, AllEventsEnabled } from '../scripts/utils/events';
import { NetworkType, Network, networks } from '@holographxyz/networks';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';

interface HTokenData {
  primaryNetwork: Network;
  tokenSymbol: string;
  supportedNetworks: Network[];
}

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

  const futureHTokenAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'hToken',
    generateInitCode(['address', 'uint16'], [deployer.address, 0])
  );
  hre.deployments.log('the future "hToken" address is', futureHTokenAddress);

  // hToken
  let hTokenDeployedCode: string = await hre.provider.send('eth_getCode', [futureHTokenAddress, 'latest']);
  if (hTokenDeployedCode == '0x' || hTokenDeployedCode == '') {
    hre.deployments.log('"hToken" bytecode not found, need to deploy"');
    let holographErc20 = await genesisDeployHelper(
      hre,
      salt,
      'hToken',
      generateInitCode(['address', 'uint16'], [deployer.address, 0]),
      futureHTokenAddress
    );
  } else {
    hre.deployments.log('"hToken" is already deployed.');
  }

  const network = networks[hre.networkName];

  const holograph = await hre.ethers.getContract('Holograph', deployer);

  const factory = (await hre.ethers.getContractAt(
    'HolographFactory',
    await holograph.getFactory(),
    deployer
  )) as Contract;

  const registry = (await hre.ethers.getContractAt(
    'HolographRegistry',
    await holograph.getRegistry(),
    deployer
  )) as Contract;

  const holographerBytecode: BytesLike = (await hre.ethers.getContractFactory('Holographer')).bytecode;

  const error = function (err: string) {
    hre.deployments.log(err);
    process.exit();
  };

  const currentNetworkType: NetworkType = network.type;
  let hTokens: HTokenData[] = [];
  let primaryNetwork: Network;
  if (currentNetworkType == NetworkType.local) {
    primaryNetwork = networks.localhost;
    hTokens = [
      {
        primaryNetwork: networks.localhost,
        tokenSymbol: 'ETH',
        supportedNetworks: [networks.localhost, networks.localhost2],
      },
    ];
  } else if (currentNetworkType == NetworkType.testnet) {
    primaryNetwork = networks.ethereumTestnetGoerli;
    hTokens = [
      {
        primaryNetwork: networks.ethereumTestnetGoerli,
        tokenSymbol: 'ETH',
        supportedNetworks: [
          networks.arbitrumTestnetGoerli,
          networks.baseTestnetGoerli,
          networks.ethereumTestnetGoerli,
          networks.optimismTestnetGoerli,
          networks.zoraTestnetGoerli,
        ],
      },
      {
        primaryNetwork: networks.avalancheTestnet,
        tokenSymbol: 'AVAX',
        supportedNetworks: [networks.avalancheTestnet],
      },
      {
        primaryNetwork: networks.binanceSmartChainTestnet,
        tokenSymbol: 'BNB',
        supportedNetworks: [networks.binanceSmartChainTestnet],
      },
      {
        primaryNetwork: networks.mantleTestnet,
        tokenSymbol: 'MNT',
        supportedNetworks: [networks.mantleTestnet],
      },
      {
        primaryNetwork: networks.polygonTestnet,
        tokenSymbol: 'MATIC',
        supportedNetworks: [networks.polygonTestnet],
      },
    ];
  } else if (currentNetworkType == NetworkType.mainnet) {
    primaryNetwork = networks.ethereum;
    hTokens = [
      {
        primaryNetwork: networks.ethereum,
        tokenSymbol: 'ETH',
        supportedNetworks: [
          networks.arbitrumOne,
          networks.arbitrumNova,
          networks.base,
          networks.ethereum,
          networks.optimism,
          networks.zora,
        ],
      },
      {
        primaryNetwork: networks.avalanche,
        tokenSymbol: 'AVAX',
        supportedNetworks: [networks.avalanche],
      },
      {
        primaryNetwork: networks.binanceSmartChain,
        tokenSymbol: 'BNB',
        supportedNetworks: [networks.binanceSmartChain],
      },
      {
        primaryNetwork: networks.mantle,
        tokenSymbol: 'MNT',
        supportedNetworks: [networks.mantle],
      },
      {
        primaryNetwork: networks.polygon,
        tokenSymbol: 'MATIC',
        supportedNetworks: [networks.polygon],
      },
    ];
  } else {
    throw new Error('cannot identity current NetworkType');
  }

  const hTokenDeployer = async function (
    holograph: Contract,
    factory: Contract,
    registry: Contract,
    holographerBytecode: BytesLike,
    data: HTokenData
  ) {
    const hTokenHash = '0x' + web3.utils.asciiToHex('hToken').substring(2).padStart(64, '0');
    const chainId = '0x' + data.primaryNetwork.holographId.toString(16).padStart(8, '0');
    let { erc20Config, erc20ConfigHash, erc20ConfigHashBytes } = await generateErc20Config(
      data.primaryNetwork,
      deployer.address,
      'hTokenProxy',
      'Holographed ' + data.tokenSymbol,
      'h' + data.tokenSymbol,
      'Holographed ' + data.tokenSymbol,
      '1',
      18,
      ConfigureEvents([]),
      generateInitCode(
        ['bytes32', 'address', 'bytes'],
        [hTokenHash, registry.address, generateInitCode(['address', 'uint16'], [deployer.address, 0])]
      ),
      salt
    );

    const futureHTokenAddress = hre.ethers.utils.getCreate2Address(
      factory.address,
      erc20ConfigHash,
      hre.ethers.utils.keccak256(holographerBytecode)
    );
    hre.deployments.log('the future "hToken ' + data.tokenSymbol + '" address is', futureHTokenAddress);

    let hTokenDeployedCode: string = await hre.provider.send('eth_getCode', [futureHTokenAddress, 'latest']);
    if (hTokenDeployedCode == '0x' || hTokenDeployedCode == '') {
      hre.deployments.log('need to deploy "hToken ' + data.tokenSymbol + '"');

      const sig = await deployer.signMessage(erc20ConfigHashBytes);
      const signature: Signature = StrictECDSA({
        r: '0x' + sig.substring(2, 66),
        s: '0x' + sig.substring(66, 130),
        v: '0x' + sig.substring(130, 132),
      } as Signature);

      const deployTx = await factory.deployHolographableContract(erc20Config, signature, deployer.address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: factory,
          data: factory.populateTransaction.deployHolographableContract(erc20Config, signature, deployer.address),
        })),
      });
      const deployResult = await deployTx.wait();
      let eventIndex: number = 0;
      let eventFound: boolean = false;
      for (let i = 0, l = deployResult.events.length; i < l; i++) {
        let e = deployResult.events[i];
        if (e.event == 'BridgeableContractDeployed') {
          eventFound = true;
          eventIndex = i;
          break;
        }
      }
      if (!eventFound) {
        throw new Error('BridgeableContractDeployed event not fired');
      }
      let hTokenAddress = deployResult.events[eventIndex].args[0];
      if (hTokenAddress != futureHTokenAddress) {
        throw new Error(
          `Seems like hTokenAddress ${hTokenAddress} and futureHTokenAddress ${futureHTokenAddress} do not match!`
        );
      }
      hre.deployments.log('deployed "hToken ' + data.tokenSymbol + '" at:', hTokenAddress);
    } else {
      hre.deployments.log('reusing "hToken ' + data.tokenSymbol + '" at:', futureHTokenAddress);
    }

    const hToken = ((await hre.ethers.getContract('hToken', deployer)) as Contract).attach(futureHTokenAddress);

    for (let network of data.supportedNetworks) {
      if (!(await hToken.isSupportedChain(network.chain))) {
        hre.deployments.log('Need to add ' + network.chain.toString() + ' as supported chain');
        const setSupportedChainTx = await MultisigAwareTx(
          hre,
          deployer,
          'hToken',
          hToken,
          await hToken.populateTransaction.updateSupportedChain(network.chain, true, {
            ...(await txParams({
              hre,
              from: deployer,
              to: hToken,
              data: hToken.populateTransaction.updateSupportedChain(network.chain, true),
            })),
          })
        );
        await setSupportedChainTx.wait();
        hre.deployments.log('Set ' + network.chain.toString() + ' as supported chain');
      }
      const chain = '0x' + network.holographId.toString(16).padStart(8, '0');
      if ((await registry.getHToken(chain)) != futureHTokenAddress) {
        hre.deployments.log(
          'Updated "Registry" with "hToken ' +
            data.tokenSymbol +
            '" for holographChainId #' +
            Number.parseInt(chain).toString()
        );
        const setHTokenTx = await MultisigAwareTx(
          hre,
          deployer,
          'HolographRegistry',
          registry,
          await registry.populateTransaction.setHToken(chain, futureHTokenAddress, {
            ...(await txParams({
              hre,
              from: deployer,
              to: registry,
              data: registry.populateTransaction.setHToken(chain, futureHTokenAddress),
            })),
          })
        );
        await setHTokenTx.wait();
      }
    }
  };

  for (let hToken of hTokens) {
    await hTokenDeployer(holograph, factory, registry, holographerBytecode, hToken);
  }
};

export default func;
func.tags = ['hToken'];
func.dependencies = ['HolographGenesis', 'DeploySources', 'DeployERC20', 'RegisterTemplates'];
