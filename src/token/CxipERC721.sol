/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/ERC721H.sol";

import "../enum/TokenUriType.sol";

import "../interface/ERC721Holograph.sol";
import "../interface/IHolographInterfaces.sol";
import "../interface/IHolograph.sol";
import "../interface/IHolographer.sol";

/**
 * @title CXIP ERC-721 Collection that is bridgeable via Holograph
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph Bridgeable ERC721 NFTs.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract CxipERC721 is ERC721H {
  /**
   * @dev Internal reference used for minting incremental token ids.
   */
  uint224 private _currentTokenId;

  /**
   * @dev Enum of type of token URI to use globally for the entire contract.
   */
  TokenUriType private _uriType;

  /**
   * @dev Enum mapping of type of token URI to use for specific tokenId.
   */
  mapping(uint256 => TokenUriType) private _tokenUriType;

  /**
   * @dev Mapping of IPFS URIs for tokenIds.
   */
  mapping(uint256 => mapping(TokenUriType => string)) private _tokenURIs;

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
    // we set this as default type since that's what Mint is currently using
    _uriType = TokenUriType.IPFS;
    address owner = abi.decode(data, (address));
    _setOwner(owner);
    // run underlying initializer logic
    return _init(data);
  }

  /**
   * @notice Get's the URI of the token.
   * @return string The URI.
   */
  function tokenURI(uint256 _tokenId) external view onlyHolographer returns (string memory) {
    TokenUriType uriType = _tokenUriType[_tokenId];
    if (uriType == TokenUriType.UNDEFINED) {
      uriType = _uriType;
    }
    return
      string(
        abi.encodePacked(
          IHolographInterfaces(IHolograph(IHolographer(holographer()).getHolograph()).getInterfaces()).getUriPrepend(
            uriType
          ),
          _tokenURIs[_tokenId][uriType]
        )
      );
  }

  function cxipMint(
    uint224 tokenId,
    TokenUriType uriType,
    string calldata tokenUri
  ) external onlyHolographer onlyOwner {
    ERC721Holograph H721 = ERC721Holograph(holographer());
    uint256 chainPrepend = H721.sourceGetChainPrepend();
    if (tokenId == 0) {
      _currentTokenId += 1;
      while (
        H721.exists(chainPrepend + uint256(_currentTokenId)) || H721.burned(chainPrepend + uint256(_currentTokenId))
      ) {
        _currentTokenId += 1;
      }
      tokenId = _currentTokenId;
    }
    H721.sourceMint(msgSender(), tokenId);
    uint256 id = chainPrepend + uint256(tokenId);
    if (uriType == TokenUriType.UNDEFINED) {
      uriType = _uriType;
    }
    _tokenUriType[id] = uriType;
    _tokenURIs[id][uriType] = tokenUri;
  }

  function bridgeIn(
    uint32, /* _chainId*/
    address, /* _from*/
    address, /* _to*/
    uint256 _tokenId,
    bytes calldata _data
  ) external onlyHolographer returns (bool) {
    (TokenUriType uriType, string memory tokenUri) = abi.decode(_data, (TokenUriType, string));
    _tokenUriType[_tokenId] = uriType;
    _tokenURIs[_tokenId][uriType] = tokenUri;
    return true;
  }

  function bridgeOut(
    uint32, /* _chainId*/
    address, /* _from*/
    address, /* _to*/
    uint256 _tokenId
  ) external view onlyHolographer returns (bytes memory _data) {
    TokenUriType uriType = _tokenUriType[_tokenId];
    if (uriType == TokenUriType.UNDEFINED) {
      uriType = _uriType;
    }
    _data = abi.encode(uriType, _tokenURIs[_tokenId][uriType]);
  }

  function afterBurn(
    address, /* _owner*/
    uint256 _tokenId
  ) external onlyHolographer returns (bool) {
    TokenUriType uriType = _tokenUriType[_tokenId];
    if (uriType == TokenUriType.UNDEFINED) {
      uriType = _uriType;
    }
    delete _tokenURIs[_tokenId][uriType];
    return true;
  }
}
