/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

abstract contract NonReentrant {
  constructor() {}

  modifier nonReentrant() {
    require(getStatus() != 2, "ERC20: reentrant call");
    setStatus(2);
    _;
    setStatus(1);
  }

  function getStatus() internal view returns (uint256 status) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.reentrant')) - 1);
    assembly {
      status := sload(
        /* slot */
        precomputeslot("eip1967.Holograph.Bridge.reentrant")
      )
    }
  }

  function setStatus(uint256 status) internal {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.reentrant')) - 1);
    assembly {
      sstore(
        /* slot */
        precomputeslot("eip1967.Holograph.Bridge.reentrant"),
        status
      )
    }
  }
}
