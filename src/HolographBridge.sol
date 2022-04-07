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

    function init(bytes memory/* data*/) external override returns (bytes4) {
        require(!_isInitialized(), "HOLOGRAPH: already initialized");
        _setInitialized();
        return IInitializable.init.selector;
    }

}
