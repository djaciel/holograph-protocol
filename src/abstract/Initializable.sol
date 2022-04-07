HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "../interface/IInitializable.sol";

abstract contract Initializable is IInitializable {

    function init(bytes memory _data) external virtual returns (bytes4);

    function _isInitialized() internal view returns (bool) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.initialized')) - 1);
        uint256 initialized;
        assembly {
            initialized := sload(precomputeslot('eip1967.Holograph.initialized'))
        }
        return (initialized > 0);
    }

    function _setInitialized() internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.initialized')) - 1);
        uint256 initialized = 1;
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.initialized'), initialized)
        }
    }

}
