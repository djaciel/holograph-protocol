HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "../abstract/Admin.sol";

contract HolographRegistryProxy is Admin {

    constructor() Admin(false) {
    }

    function getRegistry() external view returns (address registry) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
        assembly {
            registry := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.registry'))
        }
    }

    function setRegistry(address registry) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.registry'), registry)
        }
    }

    receive() external payable {
    }

    fallback() external payable {
        assembly {
            let registry := sload(precomputeslot('eip1967.Holograph.Bridge.registry'))
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
