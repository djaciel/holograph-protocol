// SPDX-License-Identifier: UNLICENSED

SOLIDITY_COMPILER_VERSION

import "./Verification.sol";

struct TokenData {
    bytes32 payloadHash;
    Verification payloadSignature;
    address creator;
    bytes32 arweave;
    bytes11 arweave2;
    bytes32 ipfs;
    bytes14 ipfs2;
}
