// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

contract Owner {

    constructor (bool useSender) {
        address owner = (useSender ? msg.sender : tx.origin);
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.owner')) - 1);
        assembly {
            sstore(/* slot */0xfd0f02aab78886b25f2f462042989735ae83ab4916d57e11ec158787e619d81a, owner)
        }
    }

    modifier onlyOwner() {
        require(msg.sender == getOwner(), "CXIP: owner only function");
        _;
    }

    function getOwner() public view returns (address owner) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.owner')) - 1);
        assembly {
            owner := sload(/* slot */0xfd0f02aab78886b25f2f462042989735ae83ab4916d57e11ec158787e619d81a)
        }
    }

    function setOwner(address owner) public onlyOwner {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.owner')) - 1);
        assembly {
            sstore(/* slot */0xfd0f02aab78886b25f2f462042989735ae83ab4916d57e11ec158787e619d81a, owner)
        }
    }

}
