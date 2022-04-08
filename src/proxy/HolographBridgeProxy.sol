HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import "../interface/IInitializable.sol";

contract HolographBridgeProxy is Admin, Initializable {

    constructor() Admin(false) {}

    function init(bytes memory data) external override returns (bytes4) {
        require(!_isInitialized(), "HOLOGRAPH: already initialized");
        (address bridge) = abi.decode(data, (address));
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.bridge'), bridge)
        }
        _setInitialized();
        return IInitializable.init.selector;
    }

    function getBridge() external view returns (address bridge) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.bridge')) - 1);
        assembly {
            bridge := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.bridge'))
        }
    }

    function setBridge(address bridge) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.bridge')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.bridge'), bridge)
        }
    }

    receive() external payable {
    }

    fallback() external payable {
        assembly {
            let bridge := sload(precomputeslot('eip1967.Holograph.Bridge.bridge'))
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), bridge, 0, calldatasize(), 0, 0)
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
