HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IInitializable.sol";

/*
 * @dev This smart contract contains the actual core bridging logic.
 */
contract HolographBridge is Admin, Initializable {

    /*
     * @dev Constructor is left empty and only the admin address is set.
     */
    constructor() Admin(false) {}

    function init(bytes memory data) external override returns (bytes4) {
        (address registry, address factory) = abi.decode(data, (address, address));
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.registry'), registry)
            sstore(precomputeslot('eip1967.Holograph.Bridge.factory'), factory)
        }
        return IInitializable.init.selector;
    }

}
