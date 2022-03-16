// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./abstract/Admin.sol";

contract SecureStorage is Admin {

    /**
     * @dev Boolean indicating if storage writing is locked. Used to prevent delegated contracts access.
     */
    bool private _locked;

    /**
     * @dev Address of contract owner. This address can run all onlyOwner functions.
     */
    address private _owner;

    modifier unlocked() {
        require(!_locked, "CXIP: storage locked");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner || msg.sender == getAdmin(), "CXIP: unauthorised msg sender");
        _;
    }

    modifier nonReentrant() {
        require(!_locked, "CXIP: storage already locked");
        _locked = true;
        _;
        _locked = false;
    }

    constructor() Admin(false) {
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function setOwner(address owner) public onlyOwner {
        _owner = owner;
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

    /**
     * @notice Transfers ownership of the collection.
     * @dev Can't be the zero address.
     * @param newOwner Address of new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner unlocked {
        require(newOwner != address(0), "CXIP: zero address");
        _owner = newOwner;
    }

}
