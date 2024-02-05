declare var global: any;
import path from 'path';
import fs from 'fs';
import Web3 from 'web3';
import { BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DeployFunction } from '@holographxyz/hardhat-deploy-holographed/types';
import { NetworkType, Network, networks } from '@holographxyz/networks';
import {
  LeanHardhatRuntimeEnvironment,
  hreSplit,
  generateInitCode,
  genesisDeriveFutureAddress,
  zeroAddress,
  txParams,
  getDeployer,
} from '../scripts/utils/helpers';
import { MultisigAwareTx } from '../scripts/utils/multisig-aware-tx';
import { ConfigureEvents } from '../scripts/utils/events';
import {
  ERC20,
  ERC20Burnable,
  ERC20Metadata,
  ERC20Permit,
  ERC20Safer,
  ERC165,
  ERC721,
  ERC721Enumerable,
  ERC721Metadata,
  ERC721TokenReceiver,
  HolographInterfaces,
  InitializableInterface,
  HolographRoyaltiesInterface,
} from '../typechain-types';

const web3 = new Web3();

const functionHash = function (func: string): string {
  return web3.eth.abi.encodeFunctionSignature(func);
};

const bitwiseXorHexString = function (pinBlock1: string, pinBlock2: string): string {
  pinBlock1 = pinBlock1.substring(2);
  pinBlock2 = pinBlock2.substring(2);
  let result: string = '';
  for (let index: number = 0; index < 8; index++) {
    let temp: string = (parseInt(pinBlock1.charAt(index), 16) ^ parseInt(pinBlock2.charAt(index), 16))
      .toString(16)
      .toLowerCase();
    result += temp;
  }
  return '0x' + result;
};

const XOR = function (hashes: string[]): string {
  let output: string = '0x00000000';
  for (let i: number = 0, l: number = hashes.length; i < l; i++) {
    output = bitwiseXorHexString(output, hashes[i]);
  }
  return output;
};

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  console.log(`Starting deploy script: ${path.basename(__filename)} 👇`);

  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const deployer = await getDeployer(hre);
  const deployerAddress = await deployer.signer.getAddress();
  const salt = hre.deploymentSalt;

  // Deploy HolographInterfaces
  const futureHolographInterfacesAddress = await genesisDeriveFutureAddress(
    hre,
    salt,
    'HolographInterfaces',
    generateInitCode(['address'], [zeroAddress])
  );
  hre.deployments.log('the future "HolographInterfaces" address is', futureHolographInterfacesAddress);

  const holographInterfaces: HolographInterfaces = (await hre.ethers.getContractAt(
    'HolographInterfaces',
    futureHolographInterfacesAddress,
    deployerAddress
  )) as HolographInterfaces;

  const network: Network = networks[hre.networkName];
  const networkType: NetworkType = network.type;
  const networkKeys: string[] = Object.keys(networks);
  const networkValues: Network[] = Object.values(networks);
  let supportedNetworkNames: string[] = [];
  let supportedNetworks: Network[] = [];
  let needToMap: number[][] = [];

  for (let i = 0, l = networkKeys.length; i < l; i++) {
    // Retrieve the key (network name) and its corresponding value (network details).
    const key: string = networkKeys[i];
    const value: Network = networkValues[i];

    // Check if the network type matches the current network type.
    if (value.type == networkType) {
      // Add the network key and value to their respective arrays.
      supportedNetworkNames.push(key);
      supportedNetworks.push(value);

      // Check if the network has a valid holograph ID.
      if (value.holographId > 0) {
        // Retrieve and convert the chain ID mapping from EVM to Holograph.
        let evm2hlg: number = (await holographInterfaces.getChainId(1, value.chain, 2)).toNumber();
        // Check if the retrieved mapping doesn't match the expected holograph ID.
        if (evm2hlg != value.holographId) {
          // Add mapping details to needToMap array.
          needToMap.push([1, value.chain, 2, value.holographId]);
          // Log this mapping requirement in a human-readable format.
          console.log(
            `Mapping required: EVM (${key}) chain ID ${value.chain} to Holograph chain ID ${value.holographId}`
          );
        }

        // Retrieve and convert the chain ID mapping from Holograph to EVM.
        let hlg2evm: number = (await holographInterfaces.getChainId(2, value.holographId, 1)).toNumber();
        // Check if the retrieved mapping doesn't match the expected EVM chain ID.
        if (hlg2evm != value.chain) {
          // Add mapping details to needToMap array.
          needToMap.push([2, value.holographId, 1, value.chain]);
          // Log this mapping requirement in a human-readable format.
          console.log(
            `Mapping required: Holograph chain ID ${value.holographId} to EVM (${key}) chain ID ${value.chain}`
          );
        }

        // Check if the network has a valid LayerZero ID.
        if (value.lzId > 0) {
          // Retrieve and convert the chain ID mapping from LayerZero to Holograph.
          let lz2hlg: number = (await holographInterfaces.getChainId(3, value.lzId, 2)).toNumber();
          // Check if the retrieved mapping doesn't match the expected holograph ID.
          if (lz2hlg != value.holographId) {
            // Add mapping details to needToMap array.
            needToMap.push([3, value.lzId, 2, value.holographId]);
            // Log this mapping requirement in a human-readable format.
            console.log(`Mapping required: LayerZero ID ${value.lzId} to Holograph chain ID ${value.holographId}`);
          }

          // Retrieve and convert the chain ID mapping from Holograph to LayerZero.
          let hlg2lz: number = (await holographInterfaces.getChainId(2, value.holographId, 3)).toNumber();
          // Check if the retrieved mapping doesn't match the expected LayerZero ID.
          if (hlg2lz != value.lzId) {
            // Add mapping details to needToMap array.
            needToMap.push([2, value.holographId, 3, value.lzId]);
            // Log this mapping requirement in a human-readable format.
            console.log(`Mapping required: Holograph chain ID ${value.holographId} to LayerZero ID ${value.lzId}`);
          }
        }
      }
    }
  }

  // Check if there are any mappings needed by examining the length of the needToMap array.
  if (needToMap.length == 0) {
    // If no mappings are needed, log a message indicating all networks are currently supported.
    hre.deployments.log('HolographInterfaces supports all currently configured networks');
  } else {
    // If mappings are needed, log a message indicating some networks need configuration.
    hre.deployments.log('HolographInterfaces needs to have some network support configured');
    // Log the details of the mappings needed in a JSON format for review.
    hre.deployments.log(JSON.stringify(needToMap));

    // Initialize arrays to hold the mapping details for the chain types and IDs.
    let fromChainType: number[] = [];
    let fromChainId: number[] = [];
    let toChainType: number[] = [];
    let toChainId: number[] = [];

    // Iterate over each mapping requirement in needToMap.
    for (let chainMap of needToMap) {
      // Populate the arrays with the specific details of each mapping requirement.
      fromChainType.push(chainMap[0]); // Type of the source chain
      fromChainId.push(chainMap[1]); // ID of the source chain
      toChainType.push(chainMap[2]); // Type of the destination chain
      toChainId.push(chainMap[3]); // ID of the destination chain
    }

    // Prepare and execute a transaction to update the chain ID mappings as required.
    let tx = await MultisigAwareTx(
      hre,
      'HolographInterfaces',
      holographInterfaces,
      await holographInterfaces.populateTransaction.updateChainIdMaps(
        fromChainType,
        fromChainId,
        toChainType,
        toChainId,
        {
          // Use txParams to get any additional transaction parameters needed (e.g., gas limit, gas price).
          ...(await txParams({
            hre,
            from: deployerAddress, // Specify the deployer address as the transaction initiator.
            to: holographInterfaces, // Specify the HolographInterfaces contract as the transaction recipient.
            data: holographInterfaces.populateTransaction.updateChainIdMaps(
              fromChainType,
              fromChainId,
              toChainType,
              toChainId
            ),
          })),
        } as any
      )
    );
    // Wait for the transaction to be mined and finalized.
    await tx.wait();
  }

  let supportedPrepends: { type: number; prepend: string }[] = [
    { type: 1, prepend: 'ipfs://' },
    { type: 2, prepend: 'https://' },
    { type: 3, prepend: 'ar://' },
  ];
  let needToMapPrepends: { type: number; prepend: string }[] = [];
  for (let prepend of supportedPrepends) {
    let currentPrepend: string = await holographInterfaces.getUriPrepend(prepend.type);
    if (currentPrepend != prepend.prepend) {
      needToMapPrepends.push(prepend);
    }
  }
  if (needToMapPrepends.length == 0) {
    hre.deployments.log('HolographInterfaces has all currently supported URI prepends configured');
  } else {
    hre.deployments.log('HolographInterfaces needs to have some URI prepends configured');
    let uriTypes: number[] = [];
    let prepends: string[] = [];
    for (let prepend of needToMapPrepends) {
      uriTypes.push(prepend.type);
      prepends.push(prepend.prepend);
    }
    let tx = await MultisigAwareTx(
      hre,
      'HolographInterfaces',
      holographInterfaces,
      await holographInterfaces.populateTransaction.updateUriPrepends(uriTypes, prepends, {
        ...(await txParams({
          hre,
          from: deployerAddress,
          to: holographInterfaces,
          data: holographInterfaces.populateTransaction.updateUriPrepends(uriTypes, prepends),
        })),
      } as any)
    );
    await tx.wait();
  }
  const supportedInterfaces: { [key: string]: string[] } = {
    // ERC20
    '1': [
      // ERC165
      functionHash('supportsInterface(bytes4)'),

      // ERC20
      functionHash('allowance(address,address)'),
      functionHash('approve(address,uint256)'),
      functionHash('balanceOf(address)'),
      functionHash('totalSupply()'),
      functionHash('transfer(address,uint256)'),
      functionHash('transferFrom(address,address,uint256)'),
      XOR([
        functionHash('allowance(address,address)'),
        functionHash('approve(address,uint256)'),
        functionHash('balanceOf(address)'),
        functionHash('totalSupply()'),
        functionHash('transfer(address,uint256)'),
        functionHash('transferFrom(address,address,uint256)'),
      ]),

      // ERC20Metadata
      functionHash('name()'),
      functionHash('symbol()'),
      functionHash('decimals()'),
      XOR([functionHash('name()'), functionHash('symbol()'), functionHash('decimals()')]),

      // ERC20Burnable
      functionHash('burn(uint256)'),
      functionHash('burnFrom(address,uint256)'),
      XOR([functionHash('burn(uint256)'), functionHash('burnFrom(address,uint256)')]),

      // ERC20Safer
      functionHash('safeTransfer(address,uint256)'),
      functionHash('safeTransfer(address,uint256,bytes)'),
      functionHash('safeTransferFrom(address,address,uint256)'),
      functionHash('safeTransferFrom(address,address,uint256,bytes)'),
      XOR([
        functionHash('safeTransfer(address,uint256)'),
        functionHash('safeTransfer(address,uint256,bytes)'),
        functionHash('safeTransferFrom(address,address,uint256)'),
        functionHash('safeTransferFrom(address,address,uint256,bytes)'),
      ]),

      // ERC20Permit
      functionHash('permit(address,address,uint256,uint256,uint8,bytes32,bytes32)'),
      functionHash('nonces(address)'),
      functionHash('DOMAIN_SEPARATOR()'),
      XOR([
        functionHash('permit(address,address,uint256,uint256,uint8,bytes32,bytes32)'),
        functionHash('nonces(address)'),
        functionHash('DOMAIN_SEPARATOR()'),
      ]),

      // Ownable
      functionHash('owner()'),
      functionHash('transferOwnership(address)'),
      XOR([functionHash('owner()'), functionHash('transferOwnership(address)')]),
    ],

    // ERC721
    '2': [
      // ERC165
      functionHash('supportsInterface(bytes4)'),

      // ERC721
      functionHash('balanceOf(address)'),
      functionHash('ownerOf(uint256)'),
      functionHash('safeTransferFrom(address,address,uint256)'),
      functionHash('safeTransferFrom(address,address,uint256,bytes)'),
      functionHash('transferFrom(address,address,uint256)'),
      functionHash('approve(address,uint256)'),
      functionHash('setApprovalForAll(address,bool)'),
      functionHash('getApproved(uint256)'),
      functionHash('isApprovedForAll(address,address)'),
      XOR([
        functionHash('balanceOf(address)'),
        functionHash('ownerOf(uint256)'),
        functionHash('safeTransferFrom(address,address,uint256)'),
        functionHash('safeTransferFrom(address,address,uint256,bytes)'),
        functionHash('transferFrom(address,address,uint256)'),
        functionHash('approve(address,uint256)'),
        functionHash('setApprovalForAll(address,bool)'),
        functionHash('getApproved(uint256)'),
        functionHash('isApprovedForAll(address,address)'),
      ]),

      // ERC721Enumerable
      functionHash('totalSupply()'),
      functionHash('tokenByIndex(uint256)'),
      functionHash('tokenOfOwnerByIndex(address,uint256)'),
      XOR([
        functionHash('totalSupply()'),
        functionHash('tokenByIndex(uint256)'),
        functionHash('tokenOfOwnerByIndex(address,uint256)'),
      ]),

      // ERC721Metadata
      functionHash('name()'),
      functionHash('symbol()'),
      functionHash('tokenURI(uint256)'),
      XOR([functionHash('name()'), functionHash('symbol()'), functionHash('tokenURI(uint256)')]),

      // adding ERC20-like-Metadata support for Etherscan totalSupply fix
      functionHash('decimals()'),
      XOR([functionHash('name()'), functionHash('symbol()'), functionHash('decimals()')]),

      // ERC721TokenReceiver
      functionHash('onERC721Received(address,address,uint256,bytes)'),

      // CollectionURI
      functionHash('contractURI()'),

      // Ownable
      functionHash('owner()'),
      functionHash('transferOwnership(address)'),
      XOR([functionHash('owner()'), functionHash('transferOwnership(address)')]),
    ],
    // HolographRoyalties
    '4': [
      // HolographRoyalties
      functionHash('initHolographRoyalties(bytes)'),
      functionHash('configurePayouts(address[],uint256[])'),
      functionHash('getPayoutInfo()'),
      functionHash('getEthPayout()'),
      functionHash('getTokenPayout(address)'),
      functionHash('getTokensPayout(address[])'),
      functionHash('supportsInterface(bytes4)'),
      functionHash('setRoyalties(uint256,address,uint256)'),
      functionHash('royaltyInfo(uint256,uint256)'),
      functionHash('getFeeBps(uint256)'),
      functionHash('getFeeRecipients(uint256)'),
      XOR([functionHash('getFeeBps(uint256)'), functionHash('getFeeRecipients(uint256)')]),
      functionHash('getRoyalties(uint256)'),
      functionHash('getFees(uint256)'),
      functionHash('tokenCreator(address,uint256)'),
      functionHash('calculateRoyaltyFee(address,uint256,uint256)'),
      functionHash('marketContract()'),
      functionHash('tokenCreators(uint256)'),
      functionHash('bidSharesForToken(uint256)'),
      functionHash('getStorageSlot(string)'),
      functionHash('getTokenAddress(string)'),
    ],
  };
  if (global.__deployedHolographInterfaces) {
    hre.deployments.log('HolographInterfaces needs to have all supported interfaces configured');
    for (let key of Object.keys(supportedInterfaces)) {
      let tx = await MultisigAwareTx(
        hre,
        'HolographInterfaces',
        holographInterfaces,
        await holographInterfaces.populateTransaction.updateInterfaces(parseInt(key), supportedInterfaces[key], true, {
          ...(await txParams({
            hre,
            from: deployerAddress,
            to: holographInterfaces,
            data: holographInterfaces.populateTransaction.updateInterfaces(
              parseInt(key),
              supportedInterfaces[key],
              true
            ),
          })),
        } as any)
      );
      await tx.wait();
    }
  } else {
    hre.deployments.log('Checking HolographInterfaces if some supported interfaces need to be configured');
    for (let key of Object.keys(supportedInterfaces)) {
      let interfaces: string[] = supportedInterfaces[key];
      let todo: string[] = [];
      for (let i of interfaces) {
        console.log('Checking if HolographInterfaces supports', i);
        if (!(await holographInterfaces.supportsInterface(parseInt(key), i))) {
          // we need to add support
          todo.push(i);
        }
      }
      if (todo.length == 0) {
        hre.deployments.log('No missing interfaces in HolographInterfaces for InterfaceType[' + key + ']');
      } else {
        hre.deployments.log('Found missing interfaces in HolographInterfaces for InterfaceType[' + key + ']');
        let tx = await MultisigAwareTx(
          hre,
          'HolographInterfaces',
          holographInterfaces,
          await holographInterfaces.populateTransaction.updateInterfaces(parseInt(key), todo, true, {
            ...(await txParams({
              hre,
              from: deployerAddress,
              to: holographInterfaces,
              data: holographInterfaces.populateTransaction.updateInterfaces(parseInt(key), todo, true),
            })),
          } as any)
        );
        await tx.wait();
      }
    }
  }

  console.log(`Exiting script: ${__filename} ✅\n`);
};

export default func;
func.tags = ['ValidateInterfaces'];
func.dependencies = ['HolographGenesis', 'DeploySources'];
