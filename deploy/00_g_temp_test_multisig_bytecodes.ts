declare var global: any;
import Web3 from 'web3';
import { BigNumber, BytesLike, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { NetworkType, Network, networks } from '@holographxyz/networks';
import {
  genesisDeriveFutureAddress,
  txParams,
  genesisDeployHelper,
  generateInitCode,
  zeroAddress,
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  gweiToWei,
  generateErc20Config,
  Signature,
  StrictECDSA,
} from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';
import { HolographOperator, HolographOperatorProxy } from '../typechain-types';
import { ConfigureEvents } from '../scripts/utils/events';

interface HTokenData {
  primaryNetwork: Network;
  tokenSymbol: string;
  supportedNetworks: Network[];
}

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const accounts = await hre.ethers.getSigners();
  let deployer: SignerWithAddress | SuperColdStorageSigner = accounts[0];
  const subOneWei = function (input: BigNumber): BigNumber {
    return input.sub(BigNumber.from('1'));
  };

  const salt = hre.deploymentSalt;
  const web3 = new Web3();
  const network = networks[hre.networkName];

  const holograph = await hre.ethers.getContract('Holograph', deployer);
  console.log(`Holograph Contract address is ${holograph.address}`);

  const holographRegistryProxy = await hre.ethers.getContract('HolographRegistryProxy', deployer);
  const holographRegistry = ((await hre.ethers.getContract('HolographRegistry', deployer)) as Contract).attach(
    holographRegistryProxy.address
  );

  // LZ MODULE DEPLOYMENT

  // LayerZeroModule
  const layerZeroModule = (await hre.ethers.getContract('LayerZeroModule', deployer)) as Contract;
  const layerZeroModuleProxy = (await hre.ethers.getContract('LayerZeroModuleProxy', deployer)) as Contract;

  // LayerZeroModuleProxy
  const operator = ((await hre.ethers.getContract('HolographOperator', deployer)) as Contract).attach(
    await holograph.getOperator()
  );

  // LayerZeroModule at Proxy address
  const lzModule = ((await hre.ethers.getContract('LayerZeroModule', deployer)) as Contract).attach(
    layerZeroModuleProxy.address
  );

  // OptimismGasPriceOracle
  const optimismGasPriceOracle = (await hre.ethers.getContract('OVM_GasPriceOracle', deployer)) as Contract;

  if ((await operator.getMessagingModule()).toLowerCase() != layerZeroModuleProxy.address.toLowerCase()) {
    const lzTx = await MultisigAwareTx(
      hre,
      deployer,
      'HolographOperator',
      operator,
      await operator.populateTransaction.setMessagingModule(layerZeroModuleProxy.address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: operator,
          data: operator.populateTransaction.setMessagingModule(layerZeroModuleProxy.address),
        })),
      })
    );
    hre.deployments.log('Transaction hash:', lzTx.hash);
    await lzTx.wait();
    hre.deployments.log(`Registered MessagingModule to: ${await operator.getMessagingModule()}`);
  } else {
    hre.deployments.log(`MessagingModule is already registered to: ${await operator.getMessagingModule()}`);
  }

  // we check that LayerZeroModule has correct OptimismGasPriceOracle set
  if ((await lzModule.getOptimismGasPriceOracle()).toLowerCase() != optimismGasPriceOracle.address.toLowerCase()) {
    const lzOpTx = await MultisigAwareTx(
      hre,
      deployer,
      'LayerZeroModule',
      lzModule,
      await lzModule.populateTransaction.setOptimismGasPriceOracle(optimismGasPriceOracle.address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: lzModule,
          data: lzModule.populateTransaction.setOptimismGasPriceOracle(optimismGasPriceOracle.address),
        })),
      })
    );
    hre.deployments.log('Transaction hash:', lzOpTx.hash);
    await lzOpTx.wait();
    hre.deployments.log(`Registered OptimismGasPriceOracle to: ${await lzModule.getOptimismGasPriceOracle()}`);
  } else {
    hre.deployments.log(
      `OptimismGasPriceOracle is already registered to: ${await lzModule.getOptimismGasPriceOracle()}`
    );
  }

  // HOLOGRAPH OPERATOR

  const holographOperatorProxy = (await hre.ethers.getContract('HolographOperatorProxy', deployer)) as Contract;
  const holographOperator = (await hre.ethers.getContract('HolographOperator', deployer)) as Contract;

  if ((await holographOperatorProxy.getOperator()) != holographOperator.address) {
    hre.deployments.log('Updating Operator reference');
    let tx = await MultisigAwareTx(
      hre,
      deployer,
      'HolographOperatorProxy',
      holographOperatorProxy,
      await holographOperatorProxy.populateTransaction.setOperator(holographOperator.address, {
        ...((await txParams({
          hre,
          from: deployer,
          to: holographOperatorProxy,
          data: holographOperatorProxy.populateTransaction.setOperator(holographOperator.address),
        })) as any),
      })
    );
    await tx.wait();
    hre.deployments.log('Updated Operator reference');
  }

  // HOLOGRAPH DROP AND CXIP DEPLOYMENT
  // Register HolographDropERC721
  const holographDropERC721 = (await hre.ethers.getContract('HolographDropERC721', deployer)) as Contract;

  hre.deployments.log('the future "HolographDropERC721" address is', holographDropERC721.address);
  const HolographDropERC721Hash = '0x' + web3.utils.asciiToHex('HolographDropERC721').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(HolographDropERC721Hash)) != holographDropERC721.address) {
    const erc721DropTx = await MultisigAwareTx(
      hre,
      deployer,
      'HolographRegistry',
      holographRegistry,
      await holographRegistry.populateTransaction.setContractTypeAddress(
        HolographDropERC721Hash,
        holographDropERC721.address,
        {
          ...(await txParams({
            hre,
            from: deployer,
            to: holographRegistry,
            data: holographRegistry.populateTransaction.setContractTypeAddress(
              HolographDropERC721Hash,
              holographDropERC721.address
            ),
          })),
        }
      )
    );
    hre.deployments.log('Transaction hash:', erc721DropTx.hash);
    await erc721DropTx.wait();
    hre.deployments.log(
      `Registered "HolographDropERC721" to: ${await holographRegistry.getContractTypeAddress(HolographDropERC721Hash)}`
    );
  } else {
    hre.deployments.log('"HolographDropERC721" is already registered');
  }

  // Register CxipERC721
  const cxipErc721 = (await hre.ethers.getContract('CxipERC721', deployer)) as Contract;
  const cxipErc721Hash = '0x' + web3.utils.asciiToHex('CxipERC721').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(cxipErc721Hash)) != cxipErc721.address) {
    const cxipErc721Tx = await MultisigAwareTx(
      hre,
      deployer,
      'HolographRegistry',
      holographRegistry,
      await holographRegistry.populateTransaction.setContractTypeAddress(cxipErc721Hash, cxipErc721.address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setContractTypeAddress(cxipErc721Hash, cxipErc721.address),
        })),
      })
    );
    hre.deployments.log('Transaction hash:', cxipErc721Tx.hash);
    await cxipErc721Tx.wait();
    hre.deployments.log(
      `Registered "CxipERC721" to: ${await holographRegistry.getContractTypeAddress(cxipErc721Hash)}`
    );
  } else {
    hre.deployments.log('"CxipERC721" is already registered');
  }

  // H TOKEN
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
          // networks.baseTestnetGoerli,
          networks.ethereumTestnetGoerli,
          networks.optimismTestnetGoerli,
          // networks.zoraTestnetGoerli,
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
          // networks.arbitrumNova,
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
      console.log(`Network ${network.name}`);
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
      if ((await registry.getHToken(chain)) != hToken.address) {
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
          await registry.populateTransaction.setHToken(chain, hToken.address, {
            ...(await txParams({
              hre,
              from: deployer,
              to: registry,
              data: registry.populateTransaction.setHToken(chain, hToken.address),
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

  // Register hToken
  const hToken = (await hre.ethers.getContract('hToken', deployer)) as Contract;
  const hTokenHash = '0x' + web3.utils.asciiToHex('hToken').substring(2).padStart(64, '0');
  if ((await holographRegistry.getContractTypeAddress(hTokenHash)) != hToken.address) {
    const hTokenTx = await MultisigAwareTx(
      hre,
      deployer,
      'HolographRegistry',
      holographRegistry,
      await holographRegistry.populateTransaction.setContractTypeAddress(hTokenHash, hToken.address, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setContractTypeAddress(hTokenHash, hToken.address),
        })),
      })
    );
    hre.deployments.log('Transaction hash:', hTokenTx.hash);
    await hTokenTx.wait();
    hre.deployments.log(`Registered "hToken" to: ${await holographRegistry.getContractTypeAddress(hTokenHash)}`);
  } else {
    hre.deployments.log('"hToken" is already registered');
  }
};

export default func;
func.tags = ['TEMP_MULTISIG_BYTECODES'];
func.dependencies = [];
