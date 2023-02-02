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

  // DropInitializer memory initializer = DropInitializer({
  //   holographFeeManager: address(feeManager),
  //   holographERC721TransferHelper: address(0x1234),
  //   factoryUpgradeGate: address(factoryUpgradeGate),
  //   marketFilterDAOAddress: address(0x0),
  //   contractName: "Test NFT",
  //   contractSymbol: "TNFT",
  //   initialOwner: DEFAULT_OWNER_ADDRESS,
  //   fundsRecipient: payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS),
  //   editionSize: editionSize,
  //   royaltyBPS: 800,
  //   setupCalls: new bytes[](0),
  //   metadataRenderer: address(dummyRenderer),
  //   metadataRendererInit: ""
  // });
  const salt = hre.deploymentSalt;
  const futureErc721DropAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographERC721Drop',
    generateInitCode(
      ['tuple(address,address,address,address,string,string,address,address,uint64,uint16,bytes[],address,bytes)'],
      [
        [
          '0x0000000000000000000000000000000000000001', // holographFeeManager
          '0x0000000000000000000000000000000000000002', // holographERC721TransferHelper
          '0x0000000000000000000000000000000000000003', // factoryUpgradeGate
          '0x0000000000000000000000000000000000000004', // marketFilterDAOAddress
          'Holograph ERC721 Drop Collection', // contractName
          'hDROP', // contractSymbol
          deployer.address, // initialOwner
          deployer.address, // fundsRecipient
          100, // 100 editions
          1000, // 10% royalty
          [], // setupCalls (sales configuration)
          '0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f', // metadataRenderer
          generateInitCode(['string', 'string', 'string'], ['desc', 'image', 'animation']), // metadataRendererInit
        ],
      ]
    ) // initCode
  );
  hre.deployments.log('the future "HolographERC721Drop" address is', futureErc721DropAddress);
  let erc721DeployedCode: string = await hre.provider.send('eth_getCode', [futureErc721DropAddress, 'latest']);

  if (erc721DeployedCode == '0x' || erc721DeployedCode == '') {
    hre.deployments.log('"HolographERC721Drop" bytecode not found, need to deploy"');
    let holographErc721Drop = await genesisDeployHelper(
      hre,
      salt,
      'HolographERC721Drop',
      generateInitCode(
        ['tuple(address,address,address,address,string,string,address,address,uint64,uint16,bytes[],address,bytes)'],
        [
          [
            '0x0000000000000000000000000000000000000001', // holographFeeManager
            '0x0000000000000000000000000000000000000002', // holographERC721TransferHelper
            '0x0000000000000000000000000000000000000003', // factoryUpgradeGate
            '0x0000000000000000000000000000000000000004', // marketFilterDAOAddress
            'Holograph ERC721 Drop Collection', // contractName
            'hDROP', // contractSymbol
            deployer.address, // initialOwner
            deployer.address, // fundsRecipient
            100, // 100 editions
            1000, // 10% royalty
            [], // setupCalls (sales configuration)
            '0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f', // metadataRenderer
            generateInitCode(['string', 'string', 'string'], ['desc', 'image', 'animation']), // metadataRendererInit
          ],
        ]
      ), // initCode
      futureErc721DropAddress
    );
  } else {
    hre.deployments.log('"HolographERC721Drop" is already deployed.');
  }
};

export default func;
func.tags = ['HolographERC721Drop', 'DeployERC721Drop'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
