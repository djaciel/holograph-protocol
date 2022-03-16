// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./abstract/Admin.sol";

/*
 * @dev This smart contract stores the different source codes that have been prepared and can be used for bridging.
 * @dev We will store here the layer 1 for ERC721 and ERC1155 smart contracts.
 * @dev This way it can be super easy to upgrade/update the source code once, and have all smart contracts automatically updated.
 */
contract BridgeRegistry is Admin {

    /*
     * @dev Storage slot for saving contract type to contract address references.
     */
    mapping(uint256 => address) private _typeAddresses;

    /*
     * @dev Constructor is left empty and only the admin address is set.
     */
    constructor() Admin(false) {
    }

    /*
     * @dev Returns the contract address for a contract type.
     */
    function getTypeAddress (uint256 contractType) public view returns(address) {
        return _typeAddresses[contractType];
    }

    /*
     * @dev Sets the contract address for a contract type.
     */
    function setTypeAddress (uint256 contractType, address contractAddress) public onlyAdmin {
        require(_typeAddresses[contractType] == address(0), "CXIP: contract type already set");
        _typeAddresses[contractType] = contractAddress;
    }

}
