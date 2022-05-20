import fs from 'fs';
import { ethers } from 'hardhat';
import { BigNumberish, BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { zeroAddress } from '../scripts/utils/helpers';
import Web3 from 'web3';

const networks = JSON.parse(fs.readFileSync('./config/networks.json', 'utf8'));

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const accounts = await ethers.getSigners();
  const deployer: SignerWithAddress = accounts[0];

  const network = networks[hre.network.name];

  const error = function (err: string) {
    console.log(err);
    process.exit();
  };

  const web3 = new Web3();

  const holographFactoryProxy = await ethers.getContract('HolographFactoryProxy');
  const holographFactory = ((await ethers.getContract('HolographFactory')) as Contract).attach(
    holographFactoryProxy.address
  );

  const holographRegistryProxy = await ethers.getContract('HolographRegistryProxy');
  const holographRegistry = ((await ethers.getContract('HolographRegistry')) as Contract).attach(
    holographRegistryProxy.address
  );

  const chainId = '0x' + network.holographId.toString(16).padStart(8, '0');

  let hTokenAddress = await holographRegistry.getHToken(chainId);

  if (hTokenAddress == zeroAddress()) {
    console.log('need to deploy "hToken" for chain:', chainId);

    const hTokenArtifact: ContractFactory = await ethers.getContractFactory('hToken');

    const erc20Hash = '0x' + web3.utils.asciiToHex('HolographERC20').substring(2).padStart(64, '0');
    const config = [
      erc20Hash, // bytes32 contractType
      chainId, // uint32 chainType
      '0x' + '00'.repeat(32), // bytes32 salt
      hTokenArtifact.bytecode, // bytes byteCode
      web3.eth.abi.encodeParameters(
        ['string', 'string', 'uint8', 'uint256', 'bytes'],
        [
          network.tokenName + ' (Holographed)', // string memory contractName
          'h' + network.tokenSymbol, // string memory contractSymbol
          18, // uint8 contractDecimals
          '0x' + '00'.repeat(32), // uint256 eventConfig
          web3.eth.abi.encodeParameters(
            ['address', 'uint16'],
            [
              deployer.address, // owner
              0, // fee (bps)
            ]
          ),
        ]
      ), // bytes initCode
    ];

    const hash = web3.utils.hexToBytes(
      web3.utils.keccak256(
        '0x' +
          config[0].substring(2) +
          config[1].substring(2) +
          config[2].substring(2) +
          web3.utils.keccak256(config[3]).substring(2) +
          web3.utils.keccak256(config[4]).substring(2) +
          deployer.address.substring(2)
      )
    );

    const sig = await deployer.signMessage(hash);
    const signature: { r: BytesLike; s: BytesLike; v: BigNumberish } = {
      r: '0x' + sig.substring(2, 66),
      s: '0x' + sig.substring(66, 130),
      v: '0x' + sig.substring(130, 132),
    };

    const depoyTx = await holographFactory.deployHolographableContract(config, signature, deployer.address);
    const deployResult = await depoyTx.wait();
    if (deployResult.events.length < 1 || deployResult.events[0].event != 'BridgeableContractDeployed') {
      throw new Error('BridgeableContractDeployed event not fired');
    }
    hTokenAddress = deployResult.events[0].args[0];
    const setHTokenTx = await holographRegistry.setHToken(chainId, hTokenAddress);
    await setHTokenTx.wait();

    console.log('deployed "hToken" at:', await holographRegistry.getHToken(chainId));
  } else {
    console.log('reusing "hToken" at:', hTokenAddress);
  }
};

export default func;
func.tags = ['hToken'];
func.dependencies = [
  'HolographGenesis',
  'DeploySources',
  'DeployERC20',
  'DeployERC721',
  'DeployERC1155',
  'RegisterTemplates',
];
