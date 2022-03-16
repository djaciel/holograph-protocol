// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "../abstract/Admin.sol";

contract BridgeRegistryProxy is Admin {

    constructor() Admin(false) {
    }

    function getRegistry() public view returns (address registry) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.registry')) - 1);
        assembly {
            registry := sload(/* slot */0x63977dd6aa472ab198eb6317e51a708dcd54071f91b31dbbe4fe11f9c9cce1ca)
        }
    }

    function setRegistry(address registry) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.registry')) - 1);
        assembly {
            sstore(/* slot */0x63977dd6aa472ab198eb6317e51a708dcd54071f91b31dbbe4fe11f9c9cce1ca, registry)
        }
    }

    receive() external payable {
    }

    fallback() external payable {
        address registry = getRegistry();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), registry, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

}
