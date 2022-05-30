const ChainId = {
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
  syn2hlg: function (synChainId: number): number {
    return 0;
  },
  hlg2syn: function (hlgChainId: number): number {
    return 0;
  },
};

export default ChainId;
