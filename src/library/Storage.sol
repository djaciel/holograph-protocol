/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

library Storage {
  function getUint32(bytes32 slot) internal view returns (uint32 output) {
    assembly {
      output := sload(slot)
    }
  }

  function setUint32(bytes32 slot, uint32 input) internal {
    assembly {
      sstore(slot, input)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 output) {
    assembly {
      output := sload(slot)
    }
  }

  function setUint256(bytes32 slot, uint256 input) internal {
    assembly {
      sstore(slot, input)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address output) {
    assembly {
      output := sload(slot)
    }
  }

  function setAddress(bytes32 slot, address input) internal {
    assembly {
      sstore(slot, input)
    }
  }

  function getBytes32(bytes32 slot) internal view returns (bytes32 output) {
    assembly {
      output := sload(slot)
    }
  }

  function setBytes32(bytes32 slot, bytes32 input) internal {
    assembly {
      sstore(slot, input)
    }
  }
}
