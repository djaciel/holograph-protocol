declare var global: any;
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction, DeployOptions } from '@holographxyz/hardhat-deploy-holographed/types';
import {
  hreSplit,
  txParams,
  genesisDeployHelper,
  generateInitCode,
  genesisDeriveFutureAddress,
} from '../scripts/utils/helpers';
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

  // Salt is used for deterministic address generation
  const salt = hre.deploymentSalt;

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
  hre.deployments.log('the future "DropsMetadataRendererProxy" address is', futureDropsMetadataRendererProxyAddress);
  let dropsMetadataRendererProxyDeployedCode: string = await hre.provider.send('eth_getCode', [
    futureDropsMetadataRendererProxyAddress,
    'latest',
  ]);
  if (dropsMetadataRendererProxyDeployedCode == '0x' || dropsMetadataRendererProxyDeployedCode == '') {
    hre.deployments.log('"DropsMetadataRendererProxy" bytecode not found, need to deploy"');
    let dropsMetadataRendererProxy = await genesisDeployHelper(
      hre,
      salt,
      'DropsMetadataRendererProxy',
      generateInitCode(['address', 'bytes'], [futureDropsMetadataRendererAddress, generateInitCode([], [])]),
      futureDropsMetadataRendererProxyAddress
    );
  } else {
    hre.deployments.log('"DropsMetadataRendererProxy" is already deployed.');
  }

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
    let editionsMetadataRendererProxy = await genesisDeployHelper(
      hre,
      salt,
      'EditionsMetadataRendererProxy',
      generateInitCode(['address', 'bytes'], [futureEditionsMetadataRendererAddress, generateInitCode([], [])]),
      futureEditionsMetadataRendererProxyAddress
    );
  } else {
    hre.deployments.log('"EditionsMetadataRendererProxy" is already deployed.');
  }

  // Deploy the HolographDropsEditionsV1 custom contract source
  const holographDropsEditionsV1InitCode = generateInitCode(
    [
      'tuple(address,address,address,address,uint64,uint16,bool,tuple(uint104,uint32,uint64,uint64,uint64,uint64,bytes32),address,bytes)',
    ],
    [
      [
        '0x0000000000000000000000000000000000000000', // holographERC721TransferHelper
        '0x0000000000000000000000000000000000000000', // marketFilterAddress (opensea)
        deployer.address, // initialOwner
        deployer.address, // fundsRecipient
        0, // 1000 editions
        1000, // 10% royalty
        true, // enableOpenSeaRoyaltyRegistry
        [0, 0, 0, 0, 0, 0, '0x' + '00'.repeat(32)], // salesConfig
        futureEditionsMetadataRendererProxyAddress, // metadataRenderer
        generateInitCode(['string', 'string', 'string'], ['decscription', 'imageURI', 'animationURI']), // metadataRendererInit
      ],
    ]
  );
  const futureHolographDropsEditionsV1Address = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographDropsEditionsV1',
    holographDropsEditionsV1InitCode
  );
  hre.deployments.log('the future "HolographDropsEditionsV1" address is', futureHolographDropsEditionsV1Address);

  let holographDropsEditionsV1DeployedCode: string = await hre.provider.send('eth_getCode', [
    futureHolographDropsEditionsV1Address,
    'latest',
  ]);

  if (holographDropsEditionsV1DeployedCode == '0x' || holographDropsEditionsV1DeployedCode == '') {
    hre.deployments.log('"HolographDropsEditionsV1" bytecode not found, need to deploy"');
    let holographDropsEditionsV1 = await genesisDeployHelper(
      hre,
      salt,
      'HolographDropsEditionsV1',
      holographDropsEditionsV1InitCode,
      futureHolographDropsEditionsV1Address
    );
  } else {
    hre.deployments.log('"HolographDropsEditionsV1" is already deployed.');
  }
};

export default func;
func.tags = ['DropsMetadataRenderer', 'EditionsMetadataRenderer', 'HolographDropsEditionsV1'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
