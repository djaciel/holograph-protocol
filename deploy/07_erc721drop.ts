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
  zeroAddress,
} from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
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
};

export default func;
func.tags = ['DropsMetadataRenderer', 'EditionsMetadataRenderer', 'HolographDropERC721'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
