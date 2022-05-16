HOLOGRAPH_LICENSE_HEADER

SOLIDITY_COMPILER_VERSION

library ChainId {

    function lz2hlg(uint16 lzChainId) internal pure returns (uint32 hlgChainId) {
        assembly {
            switch lzChainId
            // eth
            case 1 {
                hlgChainId := 1
            }
            // bsc
            case 2 {
                hlgChainId := 2
            }
            // avalanche
            case 6 {
                hlgChainId := 3
            }
            // polygon
            case 9 {
                hlgChainId := 4
            }
            // arbitrum
            case 10 {
                hlgChainId := 6
            }
            // optimism
            case 11 {
                hlgChainId := 7
            }
            // fantom
            case 12 {
                hlgChainId := 5
            }
            // rinkeby
            case 10001 {
                hlgChainId := 4000000001
            }
            // bsc testnet
            case 10002 {
                hlgChainId := 4000000002
            }
            // fuji
            case 10006 {
                hlgChainId := 4000000003
            }
            // mumbai
            case 10009 {
                hlgChainId := 4000000004
            }
            // arbitrum rinkeby
            case 10010 {
                hlgChainId := 4000000006
            }
            // optimism kovan
            case 10011 {
                hlgChainId := 4000000007
            }
            // fantom testnet
            case 10012 {
                hlgChainId := 4000000005
            }
            // local2
            case 65534 {
                hlgChainId := 4294967294
            }
            // local
            case 65535 {
                hlgChainId := 4294967295
            }
            default {
                hlgChainId := 0
            }
        }
    }

    function hlg2lz(uint32 hlgChainId) internal pure returns (uint16 lzChainId) {
        assembly {
            switch hlgChainId
            // eth
            case 1 {
                lzChainId := 1
            }
            // bsc
            case 2 {
                lzChainId := 2
            }
            // avalanche
            case 3 {
                lzChainId := 6
            }
            // polygon
            case 4 {
                lzChainId := 9
            }
            // fantom
            case 5 {
                lzChainId := 12
            }
            // arbitrum
            case 6 {
                lzChainId := 10
            }
            // optimism
            case 7 {
                lzChainId := 11
            }
            // rinkeby
            case 4000000001 {
                lzChainId := 10001
            }
            // bsc testnet
            case 4000000002 {
                lzChainId := 10002
            }
            // fuji
            case 4000000003 {
                lzChainId := 10006
            }
            // mumbai
            case 4000000004 {
                lzChainId := 10009
            }
            // fantom testnet
            case 4000000005 {
                lzChainId := 10012
            }
            // arbitrum rinkeby
            case 4000000006 {
                lzChainId := 10010
            }
            // optimism kovan
            case 4000000007 {
                lzChainId := 10011
            }
            // local2
            case 4294967294 {
                lzChainId := 65534
            }
            // local
            case 4294967295 {
                lzChainId := 65535
            }
            default {
                lzChainId := 0
            }
        }
    }

    function syn2hlg(uint32 synChainId) internal pure returns (uint32 hlgChainId) {
        return synChainId;
    }

    function hlg2syn(uint32 hlgChainId) internal pure returns (uint32 synChainId) {
        return hlgChainId;
    }

}
