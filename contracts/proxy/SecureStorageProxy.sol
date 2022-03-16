// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "../abstract/Admin.sol";
import "../interface/IBridgeFactory.sol";

contract SecureStorageProxy is Admin {

    constructor() Admin(true) {
    }

    receive() external payable {
    }

    fallback() external payable {
        address secureStorage = IBridgeFactory(0x2020427269646765466163746f727950726f7879).getSecureStorage();
        assembly {
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
