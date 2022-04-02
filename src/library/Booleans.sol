// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

library Booleans {
    function get(uint256 _packedBools, uint256 _boolNumber) internal pure returns (bool) {
        uint256 flag = (_packedBools >> _boolNumber) & uint256(1);
        return (flag == 1 ? true : false);
    }

    function set(uint256 _packedBools, uint256 _boolNumber, bool _value) internal pure returns (uint256) {
        if (_value) {
            return _packedBools | (uint256(1) << _boolNumber);
        } else {
            return _packedBools & ~(uint256(1) << _boolNumber);
        }
    }
}
