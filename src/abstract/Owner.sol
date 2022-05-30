/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

abstract contract Owner {
  /**
   * @dev Event emitted when contract owner is changed.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {}

  modifier onlyOwner() virtual {
    require(msg.sender == getOwner(), "HOLOGRAPH: owner only function");
    _;
  }

  function owner() public view virtual returns (address) {
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
    address previousOwner = getOwner();
    assembly {
      sstore(
        /* slot */
        precomputeslot("eip1967.Holograph.Bridge.owner"),
        ownerAddress
      )
    }
    emit OwnershipTransferred(previousOwner, ownerAddress);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "HOLOGRAPH: zero address");
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.owner"), newOwner)
    }
  }

  function ownerCall(address target, bytes calldata data) external payable onlyOwner {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
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
