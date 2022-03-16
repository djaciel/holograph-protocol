// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

contract Admin {

    constructor (bool useSender) {
        address admin = (useSender ? msg.sender : tx.origin);
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.admin')) - 1);
        assembly {
            sstore(/* slot */0xad03c2ba1e62e8267d0e9e41d287f5a37e9b04541bf709bd3231dbc684036f34, admin)
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "CXIP: admin only function");
        _;
    }

    function getAdmin() public view returns (address admin) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.admin')) - 1);
        assembly {
            admin := sload(/* slot */0xad03c2ba1e62e8267d0e9e41d287f5a37e9b04541bf709bd3231dbc684036f34)
        }
    }

    function setAdmin(address admin) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.admin')) - 1);
        assembly {
            sstore(/* slot */0xad03c2ba1e62e8267d0e9e41d287f5a37e9b04541bf709bd3231dbc684036f34, admin)
        }
    }

}
