// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Utils {
  function stringToBytes32(string memory input) public pure returns (bytes32) {
    bytes memory stringBytes = bytes(input);
    require(stringBytes.length <= 32, "Input string must be less than or equal to 32 bytes");
    bytes memory result = new bytes(32);
    assembly {
      mstore(add(result, 32), mload(add(stringBytes, 32)))
    }

    bytes32 finalResult;
    assembly {
      finalResult := mload(add(result, 32))
    }
    return finalResult >> (8 * (32 - stringBytes.length));
  }
}
