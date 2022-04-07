HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

abstract contract Admin {

    constructor (bool useSender) {
        address admin = (useSender ? msg.sender : tx.origin);
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.admin')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.admin'), admin)
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "HOLOGRAPH: admin only function");
        _;
    }

    function getAdmin() public view returns (address admin) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.admin')) - 1);
        assembly {
            admin := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.admin'))
        }
    }

    function setAdmin(address admin) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.admin')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.admin'), admin)
        }
    }

}
