import { Transaction } from '@ethersproject/transactions';
import { TransactionRequest, TransactionResponse, TransactionReceipt } from '@ethersproject/abstract-provider';
import { Signer } from '@ethersproject/abstract-signer';
import { Contract, ContractTransaction } from '@ethersproject/contracts';

import { NetworkType, Network, networks } from '@holographxyz/networks';
import { Environment, getEnvironment } from '@holographxyz/environment';

import { HardhatRuntimeEnvironment } from 'hardhat/types';

import { BigNumber } from '@ethersproject/bignumber';

/*
export type TransactionRequest = {
    to?: string,
    from?: string,
    nonce?: BigNumberish,

    gasLimit?: BigNumberish,
    gasPrice?: BigNumberish,

    data?: BytesLike,
    value?: BigNumberish,
    chainId?: number

    type?: number;
    accessList?: AccessListish;

    maxPriorityFeePerGas?: BigNumberish;
    maxFeePerGas?: BigNumberish;

    customData?: Record<string, any>;
    ccipReadEnabled?: boolean;
}

export interface TransactionResponse extends Transaction {
    hash: string;

    // Only if a transaction has been mined
    blockNumber?: number,
    blockHash?: string,
    timestamp?: number,

    confirmations: number,

    // Not optional (as it is in Transaction)
    from: string;

    // The raw transaction
    raw?: string,

    // This function waits until the transaction has been mined
    wait: (confirmations?: number) => Promise<TransactionReceipt>
};

export interface ContractTransaction extends TransactionResponse {
    wait(confirmations?: number): Promise<ContractReceipt>;
}
*/

interface MultisigHandler extends ContractTransaction {
  wait(confirmations?: number): Promise<ContractReceipt>;
}

const MultisigAwareTx = async (hre: HardhatRuntimeEnvironment, deployer: Signer, futureTx: TransactionRequest): Promise<MultisigHandler | ContractTransaction | TransactionResponse> => {
  process.stdout.write("\n\n" + JSON.stringify(futureTx, undefined, 2) + "\n\n");
//  process.stdout.write("\n\n" + JSON.stringify(futureTx) + "\n\n");
//  process.stdout.write("\n\n" + JSON.stringify(hre) + "\n\n");
  const network: Network = networks[hre.networkName];

  const environment: Environment = getEnvironment();
  if (network.protocolMultisig === undefined) {
    // check if contract admin matches current deployer/wallet
    // if admin is set to current deployer/wallet, pass through
    return (await deployer.sendTransaction(futureTx)) as ContractTransaction;
    // else check if holograph admin is deployer/wallet
  } else {
    // check that holograph is admin of contract/to address
    // check that multisig is admin of holograph
    // spit out transaction for user
    process.stdout.write("\n\n" + JSON.stringify([targetFunction, functionArguments], undefined, 2) + "\n\n");
    throw new Error('we need to support this');
  }
};

export { MultisigHandler, MultisigAwareTx }
