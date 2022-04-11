HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

abstract contract Owner {

    constructor (bool useSender) {
        address owner = (useSender ? msg.sender : tx.origin);
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.owner')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.owner'), owner)
        }
    }

    modifier onlyOwner() virtual {
        require(msg.sender == getOwner(), "HOLOGRAPH: owner only function");
        _;
    }

    function getOwner() public view returns (address owner) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.owner')) - 1);
        assembly {
            owner := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.owner'))
        }
    }

    function setOwner(address owner) public onlyOwner {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.owner')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.owner'), owner)
        }
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "HOLOGRAPH: zero address");
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.owner'), newOwner)
        }
    }

}
