// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./interface/IBridgeRegistry.sol";

/*
 * @dev This contract is a binder. It puts together all the variables to make the underlying contracts functional and be bridgeable.
 */
contract BridgeableContract is Admin {

    /*
     * @dev Constructor is left empty and only the admin address is set.
     */
    constructor() Admin(true) {
    }

    /*
     * @dev Returns a hardcoded address for the custom secure storage contract deployed in parallel with this contract deployment.
     * @dev The choice to use this approach was taken to prevent storage slot overrides.
     */
    function getSecureStorage() public pure returns (address) {
        return 0x53656375726553746f7261676541646472657373;
    }

    /*
     * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
     */
    receive() external payable {
    }

    /*
     * @dev Hard-coded registry address and contract type are put inside the fallback to make sure that the contract cannot be modified.
     * @dev This takes the underlying address source code, runs it, and uses current address for storage.
     */
    fallback() external payable {
        address _target = IBridgeRegistry(0x20427269646765526567697374727950726f7879).getTypeAddress(100720653802902414284285709932406411645314037931866031175238873523629937516205);
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
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
