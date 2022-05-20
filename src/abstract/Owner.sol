/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

abstract contract Owner {
  constructor(bool useSender) {
    address ownerAddress = (useSender ? msg.sender : tx.origin);
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.owner')) - 1);
    assembly {
      sstore(
        /* slot */
        precomputeslot("eip1967.Holograph.Bridge.owner"),
        ownerAddress
      )
    }
  }

  modifier onlyOwner() virtual {
    require(msg.sender == getOwner(), "HOLOGRAPH: owner only function");
    _;
  }

  function owner() public view returns (address) {
    return getOwner();
  }

  function getOwner() public view returns (address ownerAddress) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.owner')) - 1);
    assembly {
      ownerAddress := sload(
        /* slot */
        precomputeslot("eip1967.Holograph.Bridge.owner")
      )
    }
  }

  function setOwner(address ownerAddress) public onlyOwner {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.owner')) - 1);
    assembly {
      sstore(
        /* slot */
        precomputeslot("eip1967.Holograph.Bridge.owner"),
        ownerAddress
      )
    }
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "HOLOGRAPH: zero address");
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.owner"), newOwner)
    }
  }
}
