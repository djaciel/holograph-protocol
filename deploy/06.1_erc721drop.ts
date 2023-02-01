declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  genesisDeployHelper,
  generateInitCode,
  genesisDeriveFutureAddress,
  zeroAddress,
  getGasPrice,
  getGasLimit,
} from '../scripts/utils/helpers';
import { HolographERC721Event, ConfigureEvents } from '../scripts/utils/events';
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
  const salt = hre.deploymentSalt;
  const futureErc721DropAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographERC721Drop',
    generateInitCode(
      ['string', 'string', 'uint16', 'uint256', 'bool', 'bytes'],
      [
        'Holograph ERC721 Drop Collection', // contractName
        'hDropNFT', // contractSymbol
        1000, // contractBps == 0%
        ConfigureEvents([]), // eventConfig
        true, // skipInit
        generateInitCode(['address'], [deployer.address]), // initCode
      ]
    )
  );
  hre.deployments.log('the future "HolographERC721Drop" address is', futureErc721DropAddress);
  // HolographERC721Drop
  let erc721DeployedCode: string = await hre.provider.send('eth_getCode', [futureErc721DropAddress, 'latest']);

  // TODO: This is the solidity version of the drop initializer
  // struct DropInitializer {
  //   address holographFeeManager;
  //   address holographERC721TransferHelper;
  //   address factoryUpgradeGate;
  //   address marketFilterDAOAddress;
  //   string contractName;
  //   string contractSymbol;
  //   address initialOwner;
  //   address payable fundsRecipient;
  //   uint64 editionSize;
  //   uint16 royaltyBPS;
  //   bytes[] setupCalls;
  //   address metadataRenderer;
  //   bytes metadataRendererInit;
  // }
  if (erc721DeployedCode == '0x' || erc721DeployedCode == '') {
    hre.deployments.log('"HolographERC721Drop" bytecode not found, need to deploy"');
    let holographErc721Drop = await genesisDeployHelper(
      hre,
      salt,
      'HolographERC721Drop',
      generateInitCode(
        ['string', 'string', 'uint16', 'uint256', 'bool', 'bytes'],
        [
          'Holograph ERC721 Drop Collection', // contractName
          'hDROP', // contractSymbol
          1000, // contractBps == 0%
          ConfigureEvents([]), // eventConfig
          true, // skipInit
          generateInitCode(
            [
              'tuple(address,address,address,address,string,string,address,address,uint64,uint16,bytes[],address,bytes)',
            ],
            [
              [
                '0x0000000000000000000000000000000000000000', // holographFeeManager
                '0x0000000000000000000000000000000000000000', // holographERC721TransferHelper
                '0x0000000000000000000000000000000000000000', // factoryUpgradeGate
                '0x0000000000000000000000000000000000000000', // marketFilterDAOAddress
                'Holograph ERC721 Drop Collection', // contractName
                'hDROP', // contractSymbol
                deployer.address, // initialOwner
                deployer.address, // fundsRecipient
                1000, // 1000 editions
                1000, // 10% royalty
                [], // setupCalls
                '0x0000000000000000000000000000000000000000', // metadataRenderer
                '0x', // metadataRendererInit
              ],
            ]
          ), // initCode
        ]
      ),
      futureErc721DropAddress
    );
  } else {
    hre.deployments.log('"HolographERC721Drop" is already deployed.');
  }
};

export default func;
func.tags = ['HolographERC721Drop', 'DeployERC721Drop'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
