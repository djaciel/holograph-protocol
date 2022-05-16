// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

library Signature {
    function Derive(
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory encoded
    )
        internal
        pure
        returns (
            address derived1,
            address derived2,
            address derived3,
            address derived4
        )
    {
        bytes32 encoded32;
        assembly {
            encoded32 := mload(add(encoded, 32))
        }
        derived1 = ecrecover(encoded32, v, r, s);
        derived2 = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32)), v, r, s);
        encoded32 = keccak256(encoded);
        derived3 = ecrecover(encoded32, v, r, s);
        encoded32 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32));
        derived4 = ecrecover(encoded32, v, r, s);
    }

    function PackMessage(bytes memory encoded, bool geth) internal pure returns (bytes32) {
        bytes32 hash = keccak256(encoded);
        if (geth) {
            hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        }
        return hash;
    }

    function Valid(
        address target,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory encoded
    ) internal pure returns (bool) {
        bytes32 encoded32;
        address derived;
        if (encoded.length == 32) {
            assembly {
                encoded32 := mload(add(encoded, 32))
            }
            derived = ecrecover(encoded32, v, r, s);
            if (target == derived) {
                return true;
            }
            derived = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32)), v, r, s);
            if (target == derived) {
                return true;
            }
        }
        bytes32 hash = keccak256(encoded);
        derived = ecrecover(hash, v, r, s);
        if (target == derived) {
            return true;
        }
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        derived = ecrecover(hash, v, r, s);
        return target == derived;
    }
}
