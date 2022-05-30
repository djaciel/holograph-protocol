/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/ERC721H.sol";

import "../interface/ERC721Holograph.sol";

import "../struct/TokenData.sol";

/**
 * @title CXIP ERC-721 Collection that is bridgeable via Holograph
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph Bridgeable ERC721 NFTs.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract CxipERC721 is ERC721H {
  /**
   * @dev Token data mapped by token id.
   */
  mapping(uint256 => TokenData) private _tokenData;

  /**
   * @dev Internal reference used for minting incremental token ids.
   */
  uint224 private _currentTokenId;

  /**
   * @notice Constructor is empty and not utilised.
   * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
   */
  constructor() {}

  /**
   * @notice Initializes the collection.
   * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
   */
  function init(bytes memory data) external override returns (bytes4) {
    address owner = abi.decode(data, (address));
    _owner = owner;
    // run underlying initializer logic
    return _init(data);
  }

  /**
   * @notice Get's the URI of the token.
   * @dev Defaults the the Arweave URI
   * @return string The URI.
   */
  function tokenURI(uint256 _tokenId) external view onlyHolographer returns (string memory) {
    return
      string(abi.encodePacked("https://arweave.net/", _tokenData[_tokenId].arweave, _tokenData[_tokenId].arweave2));
  }

  function cxipMint(uint224 tokenId, TokenData calldata tokenData) external onlyHolographer onlyOwner {
    ERC721Holograph H721 = ERC721Holograph(holographer());
    if (tokenId == 0) {
      while (H721.exists(uint256(_currentTokenId)) || H721.burned(uint256(_currentTokenId))) {
        _currentTokenId += 1;
      }
      tokenId = _currentTokenId;
    }
    H721.sourceMint(tokenData.creator, tokenId);
    uint256 id = H721.sourceGetChainPrepend() + uint256(tokenId);
    _tokenData[id] = tokenData;
  }

  function bridgeIn(
    uint32, /* _chainId*/
    address, /* _from*/
    address, /* _to*/
    uint256 _tokenId,
    bytes calldata _data
  ) external onlyHolographer returns (bool) {
    TokenData memory tokenData = abi.decode(_data, (TokenData));
    _tokenData[_tokenId] = tokenData;
    return true;
  }

  function bridgeOut(
    uint32, /* _chainId*/
    address, /* _from*/
    address, /* _to*/
    uint256 _tokenId
  ) external view onlyHolographer returns (bytes memory _data) {
    _data = abi.encode(_tokenData[_tokenId]);
  }

  function afterBurn(
    address, /* _owner*/
    uint256 _tokenId
  ) external onlyHolographer returns (bool) {
    delete _tokenData[_tokenId];
    return true;
  }
}
