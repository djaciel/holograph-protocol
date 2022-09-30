const ChainId = {
  evm2hlg: function (evmChainId: number): number {
    switch (evmChainId) {
      // eth
      case 1:
        return 1;
      // bsc
      case 56:
        return 2;
      // avalanche
      case 43114:
        return 3;
      // polygon
      case 137:
        return 4;
      // arbitrum
      case 42161:
        return 6;
      // optimism
      case 10:
        return 7;
      // fantom
      case 250:
        return 5;
      // rinkeby
      case 4:
        return 4000000001;
      // goerli
      case 5:
        return 4000000011;
      // bsc testnet
      case 97:
        return 4000000002;
      // fuji
      case 43113:
        return 4000000003;
      // mumbai
      case 80001:
        return 4000000004;
      // arbitrum rinkeby
      case 421611:
        return 4000000006;
      // optimism kovan
      case 69:
        return 4000000007;
      // fantom testnet
      case 4002:
        return 4000000005;
      // local2
      case 1338:
        return 4294967294;
      // local
      case 1339:
        return 4294967295;
      default:
        return 0;
    }
  },
  hlg2evm: function (hlgChainId: number): number {
    switch (hlgChainId) {
      // eth
      case 1:
        return 1;
      // bsc
      case 2:
        return 56;
      // avalanche
      case 3:
        return 43114;
      // polygon
      case 4:
        return 137;
      // arbitrum
      case 6:
        return 42161;
      // optimism
      case 7:
        return 10;
      // fantom
      case 5:
        return 250;
      // rinkeby
      case 4000000001:
        return 4;
      // goerli
      case 4000000011:
        return 5;
      // bsc testnet
      case 4000000002:
        return 97;
      // fuji
      case 4000000003:
        return 43113;
      // mumbai
      case 4000000004:
        return 80001;
      // arbitrum rinkeby
      case 4000000006:
        return 421611;
      // optimism kovan
      case 4000000007:
        return 69;
      // fantom testnet
      case 4000000005:
        return 4002;
      // local2
      case 4294967294:
        return 1338;
      // local
      case 4294967295:
        return 1339;
      default:
        return 0;
    }
  },
  lz2hlg: function (lzChainId: number): number {
    switch (lzChainId) {
      // eth
      case 1:
        return 1;
      // bsc
      case 2:
        return 2;
      // avalanche
      case 6:
        return 3;
      // polygon
      case 9:
        return 4;
      // arbitrum
      case 10:
        return 6;
      // optimism
      case 11:
        return 7;
      // fantom
      case 12:
        return 5;
      // rinkeby
      case 10001:
        return 4000000001;
      // goerli
      case 10021:
        return 4000000011;
      // bsc testnet
      case 10002:
        return 4000000002;
      // fuji
      case 10006:
        return 4000000003;
      // mumbai
      case 10009:
        return 4000000004;
      // arbitrum rinkeby
      case 10010:
        return 4000000006;
      // optimism kovan
      case 10011:
        return 4000000007;
      // fantom testnet
      case 10012:
        return 4000000005;
      // local2
      case 65534:
        return 4294967294;
      // local
      case 65535:
        return 4294967295;
      default:
        return 0;
    }
  },
  hlg2lz: function (hlgChainId: number): number {
    switch (hlgChainId) {
      // eth
      case 1:
        return 1;
      // bsc
      case 2:
        return 2;
      // avalanche
      case 3:
        return 6;
      // polygon
      case 4:
        return 9;
      // fantom
      case 5:
        return 12;
      // arbitrum
      case 6:
        return 10;
      // optimism
      case 7:
        return 11;
      // rinkeby
      case 4000000001:
        return 10001;
      // goerli
      case 4000000011:
        return 10021;
      // bsc testnet
      case 4000000002:
        return 10002;
      // fuji
      case 4000000003:
        return 10006;
      // mumbai
      case 4000000004:
        return 10009;
      // fantom testnet
      case 4000000005:
        return 10012;
      // arbitrum rinkeby
      case 4000000006:
        return 10010;
      // optimism kovan
      case 4000000007:
        return 10011;
      // local2
      case 4294967294:
        return 65534;
      // local
      case 4294967295:
        return 65535;
      default:
        return 0;
    }
  },
};

export default ChainId;
