/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

library Address {
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
  }

  function isZero(address account) internal pure returns (bool) {
    return (account == address(0));
  }
}
