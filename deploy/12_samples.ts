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

  const erc20Hash = '0x' + web3.utils.asciiToHex('HolographERC20').substring(2).padStart(64, '0');
  const sampleErc20Artifact: ContractFactory = await ethers.getContractFactory('SampleERC20');
  const erc20Config = [
    erc20Hash, // bytes32 contractType
    chainId, // uint32 chainType
    '0x' + '00'.repeat(32), // bytes32 salt
    sampleErc20Artifact.bytecode, // bytes byteCode
    web3.eth.abi.encodeParameters(
      ['string', 'string', 'uint8', 'uint256', 'bytes'],
      [
        'Sample ERC20 Token', // string memory contractName
        'SMPL', // string memory contractSymbol
        18, // uint8 decimals
        '0x' + '00'.repeat(32), // uint256 eventConfig
        web3.eth.abi.encodeParameters(
          ['address', 'uint16'],
          [
            deployer.address ,// owner
            0 // fee (bps)
          ]
        )
      ]
    ), // bytes initCode
  ];
  const erc20ConfigHash = web3.utils.hexToBytes(
    web3.utils.keccak256(
      '0x' +
        erc20Config[0].substring(2) +
        erc20Config[1].substring(2) +
        erc20Config[2].substring(2) +
        web3.utils.keccak256(erc20Config[3]).substring(2) +
        web3.utils.keccak256(erc20Config[4]).substring(2) +
        deployer.address.substring(2)
    )
  );
  let sampleErc20Address = await holographRegistry.getHolographedHashAddress(erc20ConfigHash);
  if (sampleErc20Address == zeroAddress()) {
    console.log('need to deploy "SampleERC20" for chain:', chainId);
    const sig = await deployer.signMessage(erc20ConfigHash);
    const signature: { r: BytesLike; s: BytesLike; v: BigNumberish } = {
      r: '0x' + sig.substring(2, 66),
      s: '0x' + sig.substring(66, 130),
      v: '0x' + sig.substring(130, 132),
    };
    const depoyTx = await holographFactory.deployHolographableContract(erc20Config, signature, deployer.address);
    const deployResult = await depoyTx.wait();
    if (deployResult.events.length < 1 || deployResult.events[0].event != 'BridgeableContractDeployed') {
      throw new Error('BridgeableContractDeployed event not fired');
    }
    sampleErc20Address = deployResult.events[0].args[0];
    console.log('deployed "SampleERC20" at:', await holographRegistry.getHolographedHashAddress(erc20ConfigHash));
  } else {
    console.log('reusing "SampleERC20" at:', sampleErc20Address);
  }

  const erc721Hash = '0x' + web3.utils.asciiToHex('HolographERC721').substring(2).padStart(64, '0');
  const sampleErc721Artifact: ContractFactory = await ethers.getContractFactory('SampleERC721');
  const erc721Config = [
    erc721Hash, // bytes32 contractType
    chainId, // uint32 chainType
    '0x' + '00'.repeat(32), // bytes32 salt
    sampleErc721Artifact.bytecode, // bytes byteCode
    web3.eth.abi.encodeParameters(
      ['string', 'string', 'uint16', 'uint256', 'bytes'],
      [
        'Sample ERC721 Contract', // string memory contractName
        'SMPLR', // string memory contractSymbol
        1000, // uint16 contractBps
        '0x' + '00'.repeat(32), // uint256 eventConfig
        web3.eth.abi.encodeParameters(
          ['address'],
          [
            deployer.address // owner
          ]
        ),
      ]
    ), // bytes initCode
  ];
  const erc721ConfigHash = web3.utils.hexToBytes(
    web3.utils.keccak256(
      '0x' +
        erc721Config[0].substring(2) +
        erc721Config[1].substring(2) +
        erc721Config[2].substring(2) +
        web3.utils.keccak256(erc721Config[3]).substring(2) +
        web3.utils.keccak256(erc721Config[4]).substring(2) +
        deployer.address.substring(2)
    )
  );
  let sampleErc721Address = await holographRegistry.getHolographedHashAddress(erc721ConfigHash);
  if (sampleErc721Address == zeroAddress()) {
    console.log('need to deploy "SampleERC721" for chain:', chainId);
    const sig = await deployer.signMessage(erc721ConfigHash);
    const signature: { r: BytesLike; s: BytesLike; v: BigNumberish } = {
      r: '0x' + sig.substring(2, 66),
      s: '0x' + sig.substring(66, 130),
      v: '0x' + sig.substring(130, 132),
    };
    const depoyTx = await holographFactory.deployHolographableContract(erc721Config, signature, deployer.address);
    const deployResult = await depoyTx.wait();
    if (deployResult.events.length < 1 || deployResult.events[0].event != 'BridgeableContractDeployed') {
      throw new Error('BridgeableContractDeployed event not fired');
    }
    sampleErc721Address = deployResult.events[0].args[0];
    console.log('deployed "SampleERC721" at:', await holographRegistry.getHolographedHashAddress(erc721ConfigHash));
  } else {
    console.log('reusing "SampleERC721" at:', sampleErc721Address);
  }

  const cxipErc721Hash = '0x' + web3.utils.asciiToHex('HolographERC721').substring(2).padStart(64, '0');
  const cxipErc721Artifact: ContractFactory = await ethers.getContractFactory('CxipERC721');
  const cxipErc721Config = [
    cxipErc721Hash, // bytes32 contractType
    chainId, // uint32 chainType
    '0x' + '00'.repeat(32), // bytes32 salt
    cxipErc721Artifact.bytecode, // bytes byteCode
    web3.eth.abi.encodeParameters(
      ['string', 'string', 'uint16', 'uint256', 'bytes'],
      [
        'CXIP ERC721 Collection', // string memory contractName
        'CXIP', // string memory contractSymbol
        1000, // uint16 contractBps
        '0x' + '00'.repeat(32), // uint256 eventConfig
        web3.eth.abi.encodeParameters(
          ['address'],
          [
            deployer.address // owner
          ]
        ),
      ]
    ), // bytes initCode
  ];
  const cxipErc721ConfigHash = web3.utils.hexToBytes(
    web3.utils.keccak256(
      '0x' +
        cxipErc721Config[0].substring(2) +
        cxipErc721Config[1].substring(2) +
        cxipErc721Config[2].substring(2) +
        web3.utils.keccak256(cxipErc721Config[3]).substring(2) +
        web3.utils.keccak256(cxipErc721Config[4]).substring(2) +
        deployer.address.substring(2)
    )
  );
  let cxipErc721Address = await holographRegistry.getHolographedHashAddress(cxipErc721ConfigHash);
  if (cxipErc721Address == zeroAddress()) {
    console.log('need to deploy "CxipERC721" for chain:', chainId);
    const sig = await deployer.signMessage(cxipErc721ConfigHash);
    const signature: { r: BytesLike; s: BytesLike; v: BigNumberish } = {
      r: '0x' + sig.substring(2, 66),
      s: '0x' + sig.substring(66, 130),
      v: '0x' + sig.substring(130, 132),
    };
    const depoyTx = await holographFactory.deployHolographableContract(cxipErc721Config, signature, deployer.address);
    const deployResult = await depoyTx.wait();
    if (deployResult.events.length < 1 || deployResult.events[0].event != 'BridgeableContractDeployed') {
      throw new Error('BridgeableContractDeployed event not fired');
    }
    cxipErc721Address = deployResult.events[0].args[0];
    console.log('deployed "CxipERC721" at:', await holographRegistry.getHolographedHashAddress(cxipErc721ConfigHash));
  } else {
    console.log('reusing "CxipERC721" at:', cxipErc721Address);
  }
};

export default func;
func.tags = ['SampleERC20', 'SampleERC721', 'CxipERC721'];
func.dependencies = [
  'HolographGenesis',
  'DeploySources',
  'DeployERC20',
  'DeployERC721',
  'DeployERC1155',
  'RegisterTemplates',
  'hToken'
];
