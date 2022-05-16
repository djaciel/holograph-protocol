HOLOGRAPH_LICENSE_HEADER

SOLIDITY_COMPILER_VERSION

import "../abstract/Initializable.sol";

import "../interface/HolographedERC20.sol";

abstract contract ERC20H is Initializable, HolographedERC20 {

    /*
     * @dev Dummy variable to prevent empty functions from making "switch to pure" warnings.
     */
    bool private _success;

    modifier onlyHolographer() {
        require(msg.sender == holographer(), "holographer only function");
        _;
    }

    /**
     * @notice Constructor is empty and not utilised.
     * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
     */
    constructor() {}

    /**
     * @notice Initializes the collection.
     * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
     */
    function init(bytes memory data) external virtual override returns (bytes4) {
        return _init(data);
    }

    function _init(bytes memory/* data*/) internal returns (bytes4) {
        require(!_isInitialized(), "ERC20: already initialized");
        address _holographer = msg.sender;
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.Holographer'), _holographer)
        }
        _setInitialized();
        return IInitializable.init.selector;
    }

    /*
     * @dev Address of Holograph ERC20 standards enforcer smart contract.
     */
    function holographer() internal view returns (address _holographer) {
        assembly {
            _holographer := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.Holographer'))
        }
    }

    function bridgeIn(uint32/* _chainId*/, address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool) {
        _success = true;
        return true;
    }

    function bridgeOut(uint32/* _chainId*/, address/* _from*/, address/* _to*/, uint256/* _amount*/) external virtual view onlyHolographer returns (bytes memory _data) {
        // just here to prevent "make pure" warning
        _data = abi.encode(holographer());
    }

    function afterApprove(address/* _owner*/, address/* _to*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeApprove(address/* _owner*/, address/* _to*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterOnERC20Received(address/* _token*/, address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeOnERC20Received(address/* _token*/, address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterBurn(address/* _owner*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeBurn(address/* _owner*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterMint(address/* _owner*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeMint(address/* _owner*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterTransfer(address/* _from*/, address/* _to*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeTransfer(address/* _from*/, address/* _to*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

}
