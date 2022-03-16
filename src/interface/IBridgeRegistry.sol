// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

interface IBridgeRegistry {

    function setTypeAddress (uint256 contractType, address contractAddress) external;

    function getTypeAddress (uint256 contractType) external view returns(address);

}
