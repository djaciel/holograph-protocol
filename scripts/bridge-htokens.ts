import { JsonRpcProvider } from '@ethersproject/providers';
import { Network, NetworkType, networks } from '@holographxyz/networks';
import { Contract, BigNumber, BytesLike, ethers, BigNumberish, UnsignedTransaction } from 'ethers';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import Web3 from 'web3';
import { GasPricing, initializeGasPricing } from './utils/gas';
const web3 = new Web3();

const IS_GAS_ESTIMATION_LOGS_ENABLED = true;
const IS_OVERRIDE_MOE_GAS_ENABLED = false;
export const INSUFFICIENT_BALANCE_ERROR = 'Insufficient balance';
export const MIN_POLYGON_GAS_PRICE = BigNumber.from('400000000000');

// npx hardhat bridge-htokens --token [hETh, hMatic, hAvax...] --amount [eth units & optional] --from [network] --to [network]
task('bridge-htokens', 'Bridge hToken from one network to another')
  .addParam('token', 'The hToken to bridge')
  .addParam('amount', 'The amount of hToken to bridge')
  .addParam('destination', 'The network to bridge to')
  // .addParam('from', 'The network to bridge from')
  // .addParam('to', 'The network to bridge to')
  .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
    // const { to, from, amount } = taskArgs; // TODO: allow for from and to to be specified
    const { destination, amount } = taskArgs;

    const signer = (await hre.ethers.getSigners())[0]; // Get the first signer
    const from = await signer.getAddress();
    const to = from; // TODO: Allow for the destination address to be specified

    // Get the address of the token to bridge
    const network = networks[hre.network.name];
    const currentNetworkType: NetworkType = network.type;

    const sourceChain = networks[network.key];
    const destinationChain = networks[destination];

    console.log(sourceChain);
    console.log(destinationChain);

    const hTokenAddress = getHTokenAddress(currentNetworkType as NetworkType, taskArgs.token as TokenSymbol);
    if (!hTokenAddress) {
      throw new Error(`Invalid h token: ${taskArgs.token}`);
    }

    // Convert amount in ETH units to Wei and to bytes32
    const amountInWei = ethers.utils.parseEther(amount);
    const formattedAmount = ethers.utils.hexZeroPad(amountInWei.toHexString(), 32);

    console.log(`Bridging ${amount} ETH (${amountInWei.toString()} Wei) of ${taskArgs.token}`);
    console.log(`Formatted amount: ${formattedAmount}`);

    console.log(`Network ${network.shortKey} is of type ${currentNetworkType}`);
    console.log(
      `Bridging ${amount} ${taskArgs.token} at ${hTokenAddress} from ${network.shortKey} to ${destinationChain.shortKey}`
    );
    console.log(`Formatted amount: ${formattedAmount}`);

    const data = generateInitCode(['address', 'address', 'uint256'], [from, to, formattedAmount]);
    console.log(`Data: ${data}`);

    // Estimate the bridging fee
    const result = await bridgeOut(hre, sourceChain, destinationChain, hTokenAddress!, data);
  });

function getHTokenAddress(network: NetworkType, token: TokenSymbol): string | undefined {
  return tokenAddresses[network][token];
}

export const getRpcProvider = (network: Network) => {
  return new JsonRpcProvider({
    url: network.rpc,
  });
};

export const checkBalanceBeforeTX = (balance: BigNumberish, gas: BigNumberish): string => {
  if (BigNumber.from(gas).gt(BigNumber.from(balance))) return INSUFFICIENT_BALANCE_ERROR;
  return '';
};

async function bridgeOut(
  hre: any,
  sourceChain: Network,
  destinationChain: Network,
  htokenAddress: string,
  data: BytesLike
): Promise<any> {
  const signer = (await hre.ethers.getSigners())[0]; // Get the first signer
  const holograph = await hre.ethers.getContract('Holograph', signer);
  const bridgeContract: Contract = await hre.ethers.getContractAt(
    'HolographBridge',
    await holograph.getBridge(),
    signer
  );
  const operatorContract: Contract = await hre.ethers.getContractAt('HolographOperator', await holograph.getOperator());

  console.log(`Holgraph contract: ${holograph.address}`);
  console.log(`Bridge contract: ${bridgeContract.address}`);
  console.log(`Operator contract: ${operatorContract.address}`);
  console.log(`H Token address: ${htokenAddress}`);

  // Get the initial payload with max gas limit and gas price to simulate the transaction on destination chain
  let payload: BytesLike = await bridgeContract.callStatic.getBridgeOutRequestPayload(
    destinationChain.holographId,
    htokenAddress,
    '0x' + 'ff'.repeat(32), // Max gas limit
    '0x' + 'ff'.repeat(32), // Max gas price
    data as string
  );

  if (IS_GAS_ESTIMATION_LOGS_ENABLED) {
    console.log('Bridge gas estimation log 1: ', {
      operatorAddress: operatorContract.address,
      bridgeAddress: bridgeContract.address,
      holographToChainId: destinationChain.holographId,
      address: htokenAddress,
      initialPayload: payload,
    });
  }

  // For proper gas limit estimation, we take the payload and run a simulation on destination chain
  // load destination chain service provider
  const destinationProvider = getRpcProvider(destinationChain);
  console.log(destinationProvider);

  let destinationFrom = '0x0000000000000000000000000000000000000000';

  // Optimism and zora uses a different address for the zero address so we use that instead to simulate the tx while estimating gas
  // NOTE: The different address is the address of the Wrapped ETH contract
  if (
    destinationChain.chain == 10 ||
    destinationChain.chain == 420 ||
    destinationChain.chain == 7777777 ||
    destinationChain.chain == 999999999
  ) {
    destinationFrom = '0x4200000000000000000000000000000000000006';
  }

  // Optimism and zora sepolia uses a different address for the zero address so we use that instead to simulate the tx while estimating gas
  let sourceFrom = '0x0000000000000000000000000000000000000000';
  if (
    sourceChain.chain == 10 ||
    sourceChain.chain == 420 ||
    sourceChain.chain == 7777777 ||
    sourceChain.chain == 999999999
  ) {
    sourceFrom = '0x4200000000000000000000000000000000000006';
  }

  // Arbitrum One uses a different address
  if (destinationChain.chain == 42161) {
    destinationFrom = '0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f';
  }

  if (sourceChain.chain == 42161) {
    sourceFrom = '0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f';
  }

  // Arbitrum Sepolis uses a different address
  if (destinationChain.chain == 421614) {
    destinationFrom = '0x82af49447d8a07e3bd95bd0d56f35241523fbab1';
  }

  if (sourceChain.chain == 421614) {
    sourceFrom = '0x82af49447d8a07e3bd95bd0d56f35241523fbab1';
  }

  // We call jobEstimator on destination chain
  // by supplying 10 million gas, we get back result of how much gas is left from simulation
  // subtract leftover gas from 10 million to know exactly how much gas is used for tx
  // use 10 million gas as base gas to estimate with
  const testGasLimit: BigNumberish = BigNumber.from('10000000');
  let estimatedGas: BigNumber = testGasLimit.sub(
    await operatorContract
      .connect(destinationProvider)
      .connect(destinationFrom)
      .callStatic.jobEstimator(payload as string, {
        from: destinationFrom,
        gasLimit: testGasLimit,
        gasPrice: BigNumber.from(100000000000), // Max gas price
      })
  );

  // We extract the most recent and most accurate gas prices for destination network
  const gasPricing: GasPricing = await initializeGasPricing(destinationChain.key, destinationProvider);

  // Get gas price based on eip-1559 support
  let destinationGasPrice: BigNumber = gasPricing.isEip1559 ? gasPricing.maxFeePerGas! : gasPricing.gasPrice!;

  // Add 50% overhead to accommodate gas spikes and testing
  destinationGasPrice = destinationGasPrice.add(destinationGasPrice.div(BigNumber.from('2')));

  if (
    (destinationChain.chain === networks.polygonTestnet.chain || destinationChain.chain === networks.polygon.chain) &&
    destinationGasPrice.lt(MIN_POLYGON_GAS_PRICE)
  ) {
    destinationGasPrice = MIN_POLYGON_GAS_PRICE;
  }

  if (IS_GAS_ESTIMATION_LOGS_ENABLED) {
    console.log('Bridge gas estimation log 2: ', {
      destinationChainId: destinationChain.chain,
      destinationFrom: destinationFrom,
      estimatedGas: estimatedGas,
      gasPricing: gasPricing,
      destinationGasPriceBeforeMintGasOverride: BigNumber.from(destinationGasPrice).toString(),
    });
  }

  // Add 25% to the estimated gas limit for the destination network
  estimatedGas = estimatedGas.add(estimatedGas.div(BigNumber.from('4')));

  if (IS_OVERRIDE_MOE_GAS_ENABLED) {
    console.log(`Going to set manual values`);
    estimatedGas = BigNumber.from('1000000'); // set gas limit to 100k wei
    destinationGasPrice = BigNumber.from('1000000000'); // set gas price to 1 Gwei
  }

  if (IS_GAS_ESTIMATION_LOGS_ENABLED) {
    console.log('Bridge gas estimation log 3: ', {
      holographToChainId: destinationChain.holographId,
      holographToChainIdAsNumber: destinationChain.chain,
      htokenAddress: htokenAddress,
      estimatedGas: BigNumber.from(estimatedGas).toString(),
      destinationGasPrice: BigNumber.from(destinationGasPrice).toString(),
      estimatedGasHex: BigNumber.from(estimatedGas).toHexString(),
      destinationGasPriceHex: BigNumber.from(destinationGasPrice).toHexString(),
      data: data,
    });
  }

  // Now that we have gasLimit and gasPrice, we update the payload to include the proper data needed for estimating fees
  payload = await bridgeContract.callStatic.getBridgeOutRequestPayload(
    destinationChain.holographId,
    htokenAddress,
    estimatedGas,
    destinationGasPrice,
    data as string,
    {
      gasLimit: estimatedGas,
      gasPrice: destinationGasPrice,
    }
  );

  if (IS_GAS_ESTIMATION_LOGS_ENABLED) {
    console.log('Bridge gas estimation log 4: ', {
      payload: payload,
    });
  }

  // We are now ready to get fees for transaction
  const fees: BigNumber[] = await bridgeContract.callStatic.getMessageFee(
    destinationChain.holographId,
    estimatedGas,
    destinationGasPrice,
    payload
  );

  if (IS_GAS_ESTIMATION_LOGS_ENABLED) {
    console.log('Bridge gas estimation log 5: ', {
      hlgFee: BigNumber.from(fees[0]).toString(),
      msgFee: BigNumber.from(fees[1]).toString(),
      dstGasPrice: BigNumber.from(fees[2]).toString(),
    });
  }

  // fees consist of two parts: hlg fee and lz fee
  // fees[0] = hlg fee is the amount that we charge user for making sure operators can get the job done
  // fees[1] = lz fee is what LayerZero charge for sending the message cross-chain
  // we add the two fees together into one number
  let total: BigNumber = fees[0].add(fees[1]);
  // for now, to accommodate us time to properly estimate and calculate fees, we add 25% to give us margin for error
  total = total.add(total.div(BigNumber.from('4')));

  // time to run another gas estimate to make sure we accommodate the fact that value is being passed and might affect gas pricing
  estimatedGas = testGasLimit.sub(
    await operatorContract
      .connect(destinationProvider)
      .connect(destinationFrom)
      .callStatic.jobEstimator(payload as string, {
        from: destinationFrom,
        value: total,
        gasLimit: testGasLimit,
      })
  );

  if (IS_GAS_ESTIMATION_LOGS_ENABLED) {
    console.log('Bridge gas estimation log 6: ', {
      estimatedGas: BigNumber.from(estimatedGas).toString(),
    });
  }

  if (IS_OVERRIDE_MOE_GAS_ENABLED) {
    estimatedGas = BigNumber.from('1000000'); // set gas limit to 1 million wei
    destinationGasPrice = BigNumber.from('10000000000'); // set gas price to 10 Gwei
  }

  const unsignedTx: UnsignedTransaction = await bridgeContract.populateTransaction.bridgeOutRequest(
    destinationChain.holographId,
    htokenAddress,
    estimatedGas, // is gas Limit
    destinationGasPrice,
    data as string,
    { value: total }
  );

  if (IS_GAS_ESTIMATION_LOGS_ENABLED) {
    console.log('Bridge gas estimation log 7: ', {
      unsignedTx: unsignedTx,
    });
  }

  const balance = await signer.getBalance();
  const value = total;
  const gasPrice = await hre.ethers.provider.getGasPrice();
  const gasLimit = estimatedGas;
  const gas = gasPrice.mul(gasLimit);

  if (IS_GAS_ESTIMATION_LOGS_ENABLED) {
    console.log('Bridge gas estimation log 8: ', {
      balance: BigNumber.from(balance).toString(),
      value: BigNumber.from(value).toString(),
      gasPrice: BigNumber.from(gasPrice).toString(),
      gasLimit: BigNumber.from(gasLimit).toString(),
      gas: BigNumber.from(gas).toString(),
    });
  }

  const error = checkBalanceBeforeTX(balance, gas.add(value));

  // TODO: Move this to it's own function
  const tx = await signer.sendTransaction(unsignedTx as Object);
  await tx.wait();

  console.log(`Transaction hash: ${tx.hash}`);

  return {
    gasPrice,
    gasLimit,
    gas,
    value,
    total: gas.add(value),
    unsignedTx,
    error,
  };
}

type TokenSymbol = 'hETH' | 'hBNB' | 'hAVAX' | 'hMATIC' | 'hMNT';
type HTokenAddresses = {
  [network in NetworkType]: {
    [token in TokenSymbol]?: string;
  };
};

export const tokenAddresses: HTokenAddresses = {
  local: {}, // To sastify the type checker
  testnet: {
    hETH: '0xB019322549D380C6bC7CbC6628ff29455fe4C1cC',
    hBNB: '0xA1a98BCE0BDb2770dAfb3588d4457887f5E19434',
    hAVAX: '0x9dA278F042213B5E8a8e18499CB3B5073d585660',
    hMATIC: '0x4Fd9Be1a583F4da78362aCf92942d01C46269dF0',
    hMNT: '0xcF26eb593C244fa62E35b08DaD45136b75690841',
  },
  mainnet: {
    hETH: '0x82904Fa267EC9588E5cD5A91Ec28ea11EA69182F',
    hAVAX: '0xA84C9B6bA6Fb90EA29AA5391AbB313483AAD1fB5',
    hBNB: '0x6B3498725726C1D5925015CF19bd79A22C55b330',
    hMNT: '0x614dcA9aCE2ceA0a89320B0C8C43549848498BD6',
    hMATIC: '0x37fD830b1219b88e845ac76fC397948d48A4eA02',
  },
};

const generateInitCode = function (vars: string[], vals: any[]): string {
  return web3.eth.abi.encodeParameters(vars, vals);
};

export default {};
