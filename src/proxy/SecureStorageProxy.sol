HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "../abstract/Admin.sol";
import "../abstract/Initializable.sol";

import "../interface/IInitializable.sol";

contract SecureStorageProxy is Admin, Initializable {

    constructor() Admin(true) {}

    function init(bytes memory data) external override returns (bytes4) {
        require(!_isInitialized(), "HOLOGRAPH: already initialized");
        (address secureStorage, bytes memory initCode) = abi.decode(data, (address, bytes));
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.secureStorage'), secureStorage)
        }
        (bool success, bytes memory returnData) = secureStorage.delegatecall(
            abi.encodeWithSignature("init(bytes)", initCode)
        );
        (bytes4 selector) = abi.decode(returnData, (bytes4));
        require(success && selector == IInitializable.init.selector, "initialization failed");

        _setInitialized();
        return IInitializable.init.selector;
    }

    function getSecureStorage() external view returns (address secureStorage) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
        assembly {
            secureStorage := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.secureStorage'))
        }
    }

    function setSecureStorage(address secureStorage) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.secureStorage'), secureStorage)
        }
    }

    receive() external payable {}

    fallback() external payable {
        assembly {
            let secureStorage := sload(precomputeslot('eip1967.Holograph.Bridge.secureStorage'))
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), secureStorage, 0, calldatasize(), 0, 0)
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
