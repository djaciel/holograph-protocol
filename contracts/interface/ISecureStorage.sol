// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

interface ISecureStorage {

    function getOwner() external view returns (address);

    function setOwner(address owner) external;

    function getSlot(bytes32 slot) external view returns (bytes32 data);

    function setSlot(bytes32 slot, bytes32 data) external;

    function lock(bool position) external;

}
