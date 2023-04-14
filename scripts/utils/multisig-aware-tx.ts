declare var global: any;

import { Transaction } from '@ethersproject/transactions';
import { TransactionRequest, TransactionResponse, TransactionReceipt } from '@ethersproject/abstract-provider';
import { Signer } from '@ethersproject/abstract-signer';
import { Contract, ContractTransaction } from '@ethersproject/contracts';

import { NetworkType, Network, networks } from '@holographxyz/networks';
import { Environment, getEnvironment } from '@holographxyz/environment';

import { BigNumber } from '@ethersproject/bignumber';

import { HardhatRuntimeEnvironment } from 'hardhat/types';

import { txParams, zeroAddress } from './helpers';

interface MultisigHandler extends ContractTransaction {
  wait(confirmations?: number): Promise<ContractReceipt>;
}

const pressAnyKeyToContinue = async (prompt?: string = 'Press any key to continue: '): Promise<void> => {
  return new Promise((resolve, reject): void => {
    process.stdin.resume();
    process.stdout.write(prompt);
    process.stdin.once('data', (data: any): void => {
      resolve();
    });
    //process.stdin.once('error', reject);
  });
};

const MultisigAwareTx = async (
  hre: HardhatRuntimeEnvironment,
  deployer: Signer,
  futureTx: TransactionRequest
): Promise<MultisigHandler | ContractTransaction | TransactionResponse> => {
  const network: Network = networks[hre.networkName];
  const environment: Environment = getEnvironment();
  let contract: Contract = await hre.ethers.getContractAt('Admin', futureTx.to, deployer);
  let admin: string = (await contract.admin()).toLowerCase(); // just in case, get it, in case?
  // accomodate factory deployed contracts, which use owner storage slot instead of admin
  if (admin === global.__holographFactoryAddress) {
    contract = await hre.ethers.getContractAt('Owner', futureTx.to, deployer);
    admin = (await contract.owner()).toLowerCase();
  }
  // check if deployer is admin
  if (admin === deployer.address.toLowerCase()) {
    return (await deployer.sendTransaction(futureTx)) as ContractTransaction;
  } else {
    // deployer is not admin
    // check if holograph is admin
    if (admin === global.__holographAddress) {
      const holograph: Contract = await hre.ethers.getContractAt('Admin', global.__holographAddress, deployer);
      const holographAdmin: string = (await holograph.admin()).toLowerCase();
      // check if deployer is admin of holograph
      if (holographAdmin === deployer.address.toLowerCase()) {
        global.__txNonce[hre.networkName] -= 1;
        return (await holograph.adminCall(futureTx.to, futureTx.data, {
          ...(await txParams({
            hre,
            from: deployer,
            to: holograph,
            data: holograph.populateTransaction.adminCall(futureTx.to, futureTx.data),
          })),
        })) as ContractTransaction;
      } else {
        if (network.protocolMultisig === undefined || network.protocolMultisig === zeroAddress) {
          // deployer not admin of holograph
          throw new Error('No multisig available, admin is Holograph, deployer not admin of Holograph');
        } else {
          // multisig exists, need to check if it's admin of holograph
          if (holographAdmin === network.protocolMultisig.toLowerCase()) {
            let outputText: string = [
              '',
              '🚨🚨🚨' + '\x1b[31m' + ' Multisig Transaction ' + '\x1b[89m' + '\x1b[37m\x1b[89m' + '🚨🚨🚨',
              'You will need to make a transaction on your ' +
                network.name +
                ' multisig at address ' +
                network.protocolMultisig,
              'The following transaction needs to be created:',
              '\t' + '\x1b[33m' + 'Holograph(' + holograph.address + ').adminCall({',
              '\t\t' + 'target: ' + futureTx.to,
              '\t\t' + 'payload: ' + futureTx.data,
              '\t' + '})' + '\x1b[89m' + '\x1b[37m\x1b[89m',
              'In transaction builder enter the following address: 🔐 ' +
                '\x1b[32m' +
                holograph.address +
                '\x1b[89m' +
                '\x1b[37m\x1b[89m',
              'Select "' + '\x1b[32m' + 'Custom data' + '\x1b[89m' + '\x1b[37m\x1b[89m' + '"',
              'Set ETH value to: ' + '\x1b[32m' + '0' + '\x1b[89m' + '\x1b[37m\x1b[89m',
              'Use the following payload for Data input field:',
              '\t' +
                '\x1b[32m' +
                (await holograph.populateTransaction.adminCall(futureTx.to, futureTx.data)).data +
                '\x1b[89m' +
                '\x1b[37m\x1b[89m',
              '',
            ].join('\n');
            await pressAnyKeyToContinue(outputText);
            global.__txNonce[hre.networkName] -= 1;
            return {
              hash: 'multisig transaction',
              wait: async (): Promise<ContractReceipt> => {
                return {} as ContractReceipt;
              },
            } as MultisigHandler;
          } else {
            throw new Error('Admin is Holograph, neither multisig nor deployer are admin of Holograph');
          }
        }
      }
    } else {
      // holograph is not admin
      if (network.protocolMultisig === undefined || network.protocolMultisig === zeroAddress) {
        // multisig does not exist
        throw new Error('No multisig available, neither deployer nor Holograph are admin of this contract');
      } else {
        // multisig exists, need to check if it's admin admin of contract
        if (admin === network.protocolMultisig.toLowerCase()) {
          // here we need to call function directly on contract
          // this is a multisig owned contracts, so instructions need to be provided to multisig
          let outputText: string = [
            '',
            '🚨🚨🚨' + '\x1b[31m' + ' Multisig Transaction ' + '\x1b[89m' + '\x1b[37m\x1b[89m' + '🚨🚨🚨',
            'You will need to make a transaction on your ' +
              network.name +
              ' multisig at address ' +
              network.protocolMultisig,
            'The following transaction needs to be created:',
            '\t' + '\x1b[33m' + 'Contract(' + futureTx.to + ').call({',
            '\t\t' + 'from: ' + network.protocolMultisig,
            '\t\t' + 'payload: ' + futureTx.data,
            '\t' + '})' + '\x1b[89m' + '\x1b[37m\x1b[89m',
            'In transaction builder enter the following address: 🔐 ' +
              '\x1b[32m' +
              futureTx.to +
              '\x1b[89m' +
              '\x1b[37m\x1b[89m',
            'Select "' + '\x1b[32m' + 'Custom data' + '\x1b[89m' + '\x1b[37m\x1b[89m' + '"',
            'Set ETH value to: ' + '\x1b[32m' + '0' + '\x1b[89m' + '\x1b[37m\x1b[89m',
            'Use the following payload for Data input field:',
            '\t' + '\x1b[32m' + futureTx.data + '\x1b[89m' + '\x1b[37m\x1b[89m',
            '',
          ].join('\n');
          await pressAnyKeyToContinue(outputText);
          global.__txNonce[hre.networkName] -= 1;
          return {
            hash: 'multisig transaction',
            wait: async (): Promise<ContractReceipt> => {
              return {} as ContractReceipt;
            },
          } as MultisigHandler;
        } else {
          throw new Error('Neither deployer, multisig, nor Holograph are admin of this contract');
        }
      }
    }
  }
};

export { MultisigHandler, MultisigAwareTx };
