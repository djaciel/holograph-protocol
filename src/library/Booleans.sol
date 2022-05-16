// SPDX-License-Identifier: UNLICENSED

SOLIDITY_COMPILER_VERSION

import "../enum/HolographERC20Event.sol";
import "../enum/HolographERC721Event.sol";

library Booleans {

    function get(uint256 _packedBools, HolographERC20Event _eventName) internal pure returns (bool) {
        return get(_packedBools, uint256(_eventName));
    }

    function get(uint256 _packedBools, HolographERC721Event _eventName) internal pure returns (bool) {
        return get(_packedBools, uint256(_eventName));
    }

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
