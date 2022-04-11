HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "./interface/ERC721Holograph.sol";
import "./interface/HolographedERC721.sol";
import "./interface/IInitializable.sol";

/**
 * @title Sample ERC-721 Collection that is bridgeable via Holograph
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph Bridgeable ERC721 NFTs.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract SampleERC721 is IInitializable, HolographedERC721  {

    /*
     * @dev Address of initial creator/owner of the collection.
     */
    address private _owner;

    /*
     * @dev Address of Holograph ERC721 standards enforcer smart contract.
     */
    address private _holographer;

    /*
     * @dev Dummy variable to prevent empty functions from making "switch to pure" warnings.
     */
    bool private _success;

    /*
     * @dev Dummy variable to prevent empty functions from making "switch to pure" warnings.
     */
    bytes private _data;

    mapping(uint256 => string) private _tokenURIs;

    /**
     * @notice Constructor is empty and not utilised.
     * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
     */
    constructor() {}

    /**
     * @notice Initializes the collection.
     * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
     */
    function init(bytes memory data) external returns (bytes4) {
        _holographer = msg.sender;
        (address owner) = abi.decode(data, (address));
        _owner = owner;
        return IInitializable.init.selector;
    }

    /**
     * @notice Get's the URI of the token.
     * @dev Defaults the the Arweave URI
     * @return string The URI.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function test() external pure returns (string memory) {
        return "it works!";
    }

    function bridgeIn(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external returns (bool success) {
        // dummy input to prevent "switch to view" warnings
        _success = true;
        return _success;
    }

    function bridgeOut(address/* _from*/, address/* _to*/, uint256/* _tokenId*/) external returns (bytes memory/* _data*/) {
        // dummy input to prevent "switch to view" warnings
        _success = true;
        return _data;
    }

    function afterApprove(address/* _owner*/, address/* _to*/, uint256/* _tokenId*/) external view returns (bool success) {
        return _success;
    }

    function beforeApprove(address/* _owner*/, address/* _to*/, uint256/* _tokenId*/) external view returns (bool success) {
        return _success;
    }

    function afterApprovalAll(address/* _to*/, bool/* _approved*/) external view returns (bool success) {
        return _success;
    }

    function beforeApprovalAll(address/* _to*/, bool/* _approved*/) external view returns (bool success) {
        return _success;
    }

    function afterBurn(address/* _owner*/, uint256/* _tokenId*/) external view returns (bool success) {
        return _success;
    }

    function beforeBurn(address/* _owner*/, uint256/* _tokenId*/) external view returns (bool success) {
        return _success;
    }

    function afterMint() external view returns (bool success) {
        return _success;
    }

    function beforeMint() external view returns (bool success) {
        return _success;
    }

    function afterSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external view returns (bool success) {
        return _success;
    }

    function beforeSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external view returns (bool success) {
        return _success;
    }

    function afterTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external view returns (bool success) {
        return _success;
    }

    function beforeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external view returns (bool success) {
        return _success;
    }

}
