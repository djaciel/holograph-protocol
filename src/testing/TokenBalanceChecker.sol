// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./TokenERC20.sol";
import "./DummyERC20.sol";

contract TokenBalanceChecker {

    address private _owner;
    TokenERC20[] private _trackedTokens;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
		require(_owner == msg.sender, "Ownable: caller is not the owner");
		_;
	}

    constructor() {
        _setOwner(msg.sender);
        _trackedTokens.push(TokenERC20("ETH", "ETH", address(0), 18, 0));
    }

    function deployDummies(TokenERC20[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].tokenAddress = address(new DummyERC20(tokens[i].name, tokens[i].symbol, tokens[i].decimals));
            _trackedTokens.push(tokens[i]);
        }
    }

    function trackToken(TokenERC20 memory token) public onlyOwner {
        _trackedTokens.push(token);
    }

    function trackTokens(TokenERC20[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            _trackedTokens.push(tokens[i]);
        }
    }

    function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_setOwner(newOwner);
	}

    function untrackToken(uint256 index) public onlyOwner {
        uint256 lastIndex = _trackedTokens.length - 1;
        if (index != lastIndex) {
            _trackedTokens[index] = _trackedTokens[lastIndex];
        }
        delete _trackedTokens[lastIndex];
        _trackedTokens.pop();
    }

    function getBalances(address target) public view returns (TokenERC20[] memory) {
        TokenERC20[] memory foundTokens = new TokenERC20[](_trackedTokens.length);
        for (uint256 i = 0; i < _trackedTokens.length; i++) {
            foundTokens[i] = _trackedTokens[i];
            if (_trackedTokens[i].tokenAddress == address(0)) {
                foundTokens[i].balance = address(target).balance;
            } else {
                foundTokens[i].balance = DummyERC20(_trackedTokens[i].tokenAddress).balanceOf(target);
            }
        }
        return foundTokens;
    }

    function getBalances(address target, uint256 offset, uint256 length) public view returns (TokenERC20[] memory) {
        if (_trackedTokens.length - offset < length) {
            length = _trackedTokens.length - offset;
        }
        TokenERC20[] memory foundTokens = new TokenERC20[](length);
        for (uint256 i = 0; i < length; i++) {
            foundTokens[i] = _trackedTokens[i + offset];
            if (_trackedTokens[i + offset].tokenAddress == address(0)) {
                foundTokens[i].balance = address(target).balance;
            } else {
                foundTokens[i].balance = DummyERC20(_trackedTokens[i + offset].tokenAddress).balanceOf(target);
            }
        }
        return foundTokens;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function totalTrackedTokens() public view returns (uint256) {
        return _trackedTokens.length;
    }

    function trackedTokens() public view returns (TokenERC20[] memory) {
        return _trackedTokens;
    }

    function trackedTokens(uint256 offset, uint256 length) public view returns (TokenERC20[] memory) {
        if (_trackedTokens.length - offset < length) {
            // we are out of bounds
            length = _trackedTokens.length - offset;
        }
        TokenERC20[] memory tokens = new TokenERC20[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = _trackedTokens[i + offset];
        }
        return tokens;
    }

	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}

}
