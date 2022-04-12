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

    mapping(uint256 => string) private _tokenURIs;

    /*
     * @dev Internal reference used for minting incremental token ids.
     */
    uint224 private _currentTokendId;

    modifier onlyHolographer() {
        require(msg.sender == _holographer, "holographer only function");
        _;
    }

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
    function tokenURI(uint256 _tokenId) external view onlyHolographer returns (string memory) {
        return _tokenURIs[_tokenId];
    }

    /*
     * @dev Sample mint where anyone can mint any token, with a custom URI
     */
    function mint(address to, string calldata URI) external {
        _currentTokendId++;
        ERC721Holograph(_holographer).sourceMint(to, _currentTokendId);
        uint256 _tokenId = ERC721Holograph(_holographer).sourceGetChainPrepend() + uint256(_currentTokendId);
        _tokenURIs[_tokenId] = URI;
    }

    function test() external pure returns (string memory) {
        return "it works!";
    }


    function bridgeIn(uint32/* _chainId*/, address/* _from*/, address/* _to*/, uint256 _tokenId, bytes calldata _data) external onlyHolographer returns (bool) {
        (string memory URI) = abi.decode(_data, (string));
        _tokenURIs[_tokenId] = URI;
        return true;
    }

    function bridgeOut(uint32/* _chainId*/, address/* _from*/, address/* _to*/, uint256 _tokenId) external view onlyHolographer returns (bytes memory _data) {
        _data = abi.encode(_tokenURIs[_tokenId]);
    }

    function afterApprove(address/* _owner*/, address/* _to*/, uint256/* _tokenId*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeApprove(address/* _owner*/, address/* _to*/, uint256/* _tokenId*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterApprovalAll(address/* _to*/, bool/* _approved*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeApprovalAll(address/* _to*/, bool/* _approved*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterBurn(address/* _owner*/, uint256 _tokenId) external onlyHolographer returns (bool success) {
        delete _tokenURIs[_tokenId];
        return _success;
    }

    function beforeBurn(address/* _owner*/, uint256/* _tokenId*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterMint() external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeMint() external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

}
