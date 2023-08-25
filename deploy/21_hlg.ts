declare var global: any;
import fs from 'fs';
import Web3 from 'web3';
import { BigNumber, BigNumberish, BytesLike, ContractFactory, Contract } from 'ethers';
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
  generateInitCode,
  genesisDeriveFutureAddress,
  remove0x,
  txParams,
} from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { HolographERC20Event, ConfigureEvents, AllEventsEnabled } from '../scripts/utils/events';
import { NetworkType, Network, networks } from '@holographxyz/networks';
import { SuperColdStorageSigner } from 'super-cold-storage-signer';
import { Environment, getEnvironment } from '@holographxyz/environment';

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

  const network = networks[hre.networkName];

  const environment: Environment = getEnvironment();

  const chainId = '0x' + network.holographId.toString(16).padStart(8, '0');

  const holograph = await hre.ethers.getContract('Holograph', deployer);
  let hlgTokenAddress = await holograph.getUtilityToken();
  const operatorAddress = await holograph.getOperator();

  const holographFactoryProxy = await hre.ethers.getContract('HolographFactoryProxy', deployer);
  const holographFactory = ((await hre.ethers.getContract('HolographFactory', deployer)) as Contract).attach(
    holographFactoryProxy.address
  );

  const holographRegistryProxy = await hre.ethers.getContract('HolographRegistryProxy', deployer);
  const holographRegistry = ((await hre.ethers.getContract('HolographRegistry', deployer)) as Contract).attach(
    holographRegistryProxy.address
  );

  const error = function (err: string) {
    hre.deployments.log(err);
    process.exit();
  };

  let tokenAmount: BigNumber = BigNumber.from('100000000');
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
    holographFactoryProxy.address,
    erc20ConfigHash,
    hre.ethers.utils.keccak256(holographerBytecode)
  );
  hre.deployments.log('the future "HolographUtilityToken" address is', futureHlgAddress);

  let hlgDeployedCode: string = await hre.provider.send('eth_getCode', [futureHlgAddress, 'latest']);
  hre.deployments.log('hlgTokenAddress', hlgTokenAddress);
  hre.deployments.log('futureHlgAddress', futureHlgAddress);
  if (hlgDeployedCode == '0x' || hlgDeployedCode == '' || hlgTokenAddress != futureHlgAddress) {
    hre.deployments.log('need to deploy "HLG" for chain:', chainId);

    const sig = await deployer.signMessage(erc20ConfigHashBytes);
    const signature: Signature = StrictECDSA({
      r: '0x' + sig.substring(2, 66),
      s: '0x' + sig.substring(66, 130),
      v: '0x' + sig.substring(130, 132),
    } as Signature);

    const deployTx = await holographFactory.deployHolographableContract(erc20Config, signature, deployer.address, {
      ...(await txParams({
        hre,
        from: deployer,
        to: holographFactory,
        data: holographFactory.populateTransaction.deployHolographableContract(
          erc20Config,
          signature,
          deployer.address
        ),
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
    hlgTokenAddress = deployResult.events[eventIndex].args[0];
    if (hlgTokenAddress != futureHlgAddress) {
      throw new Error(
        `Seems like hlgTokenAddress ${hlgTokenAddress} and futureHlgAddress ${futureHlgAddress} do not match!`
      );
    }
    hre.deployments.log('deployed "HLG" at:', await holograph.getUtilityToken());
  } else {
    hre.deployments.log('reusing "HLG" at:', hlgTokenAddress);
  }

  hre.deployments.log('checking HolographUtilityToken reference');
  if ((await holograph.getUtilityToken()) != hlgTokenAddress) {
    const setHTokenTx = await MultisigAwareTx(
      hre,
      deployer,
      'Holograph',
      holograph,
      await holograph.populateTransaction.setUtilityToken(hlgTokenAddress, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holograph,
          data: holograph.populateTransaction.setUtilityToken(hlgTokenAddress),
        })),
      })
    );
    await setHTokenTx.wait();
  }

  hre.deployments.log('checking HolographRegistry UtilityToken reference');
  if ((await holographRegistry.getUtilityToken()) != hlgTokenAddress) {
    const setHTokenTx2 = await MultisigAwareTx(
      hre,
      deployer,
      'HolographRegistry',
      holographRegistry,
      await holographRegistry.populateTransaction.setUtilityToken(hlgTokenAddress, {
        ...(await txParams({
          hre,
          from: deployer,
          to: holographRegistry,
          data: holographRegistry.populateTransaction.setUtilityToken(hlgTokenAddress),
        })),
      })
    );
    await setHTokenTx2.wait();
  }

  hre.deployments.log('checking HolographOperator HLG balance');
  if (currentNetworkType == NetworkType.testnet || currentNetworkType == NetworkType.local) {
    if (environment != Environment.mainnet && environment != Environment.testnet) {
      const hlgContract = (await hre.ethers.getContract('HolographERC20', deployer)).attach(hlgTokenAddress);
      if ((await hlgContract.balanceOf(operatorAddress)).isZero()) {
        hre.deployments.log('HolographOperator has no HLG');
        const transferTx = await MultisigAwareTx(
          hre,
          deployer,
          'HolographUtilityToken',
          hlgContract,
          await hlgContract.populateTransaction.transfer(operatorAddress, BigNumber.from('1000000000000000000000000'), {
            ...(await txParams({
              hre,
              from: deployer,
              to: hlgContract,
              gasLimit: (
                await hre.ethers.provider.estimateGas(
                  hlgContract.populateTransaction.transfer(operatorAddress, BigNumber.from('1000000000000000000000000'))
                )
              ).mul(BigNumber.from('2')),
            })),
          })
        );
        await transferTx.wait();
      }
    }
  }
};

export default func;
func.tags = ['HLG', 'HolographUtilityToken'];
func.dependencies = ['HolographGenesis', 'DeploySources', 'DeployERC20', 'RegisterTemplates'];
