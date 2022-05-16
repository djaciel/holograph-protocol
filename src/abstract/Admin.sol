HOLOGRAPH_LICENSE_HEADER

SOLIDITY_COMPILER_VERSION

abstract contract Admin {

    constructor (bool useSender) {
        address adminAddress = (useSender ? msg.sender : tx.origin);
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.admin')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.admin'), adminAddress)
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "HOLOGRAPH: admin only function");
        _;
    }

    function admin() public view returns (address) {
        return getAdmin();
    }

    function getAdmin() public view returns (address adminAddress) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.admin')) - 1);
        assembly {
            adminAddress := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.admin'))
        }
    }

    function setAdmin(address adminAddress) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.admin')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.admin'), adminAddress)
        }
    }

}
