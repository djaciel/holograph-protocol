// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "../abstract/Admin.sol";

contract BridgeFactoryProxy is Admin {

    constructor() Admin(false) {}

    function getFactory() public view returns (address factory) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.factory')) - 1);
        assembly {
            factory := sload(/* slot */0x40873c98ec1e021b58a4c3d2335551a22c8705bf1e593aeec50f857d010897c6)
        }
    }

    function setFactory(address factory) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.BRIDGE.factory')) - 1);
        assembly {
            sstore(/* slot */0x40873c98ec1e021b58a4c3d2335551a22c8705bf1e593aeec50f857d010897c6, factory)
        }
    }

    receive() external payable {
    }

    fallback() external payable {
        address factory = getFactory();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), factory, 0, calldatasize(), 0, 0)
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
