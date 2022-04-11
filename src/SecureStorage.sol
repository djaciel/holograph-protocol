HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";
import "./abstract/Owner.sol";

import "./interface/IInitializable.sol";

contract SecureStorage is Admin, Owner, Initializable {

    /**
     * @dev Boolean indicating if storage writing is locked. Used to prevent delegated contracts access.
     */
    bool private _locked;

    modifier unlocked() {
        require(!_locked, "HOLOGRAPH: storage locked");
        _;
    }

    modifier onlyOwner() override {
        require(msg.sender == getOwner() || msg.sender == getAdmin(), "HOLOGRAPH: unauthorised sender");
        _;
    }

    modifier nonReentrant() {
        require(!_locked, "HOLOGRAPH: storage IS locked");
        _locked = true;
        _;
        _locked = false;
    }

    constructor() Admin(false) Owner(false) {}

    function init(bytes memory data) external override returns (bytes4) {
        (address owner) = abi.decode(data, (address));
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.owner'), owner)
        }
        return IInitializable.init.selector;
    }

    function getSlot(bytes32 slot) public view returns (bytes32 data) {
        assembly {
            data := sload(slot)
        }
    }

    function setSlot(bytes32 slot, bytes32 data) public unlocked onlyOwner {
        assembly {
            sstore(slot, data)
        }
    }

    function lock(bool position) public onlyOwner nonReentrant {
        _locked = position;
    }

}
