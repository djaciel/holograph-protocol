/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./enum/ChainIdType.sol";
import "./enum/InterfaceType.sol";
import "./enum/TokenUriType.sol";

import "./interface/CollectionURI.sol";
import "./interface/ERC20.sol";
import "./interface/ERC20Burnable.sol";
import "./interface/ERC20Metadata.sol";
import "./interface/ERC20Permit.sol";
import "./interface/ERC20Safer.sol";
import "./interface/ERC165.sol";
import "./interface/ERC721.sol";
import "./interface/ERC721Enumerable.sol";
import "./interface/ERC721Metadata.sol";
import "./interface/ERC721TokenReceiver.sol";
import "./interface/IInitializable.sol";
import "./interface/IPA1D.sol";

import "./library/Base64.sol";
import "./library/Strings.sol";

contract HolographInterfaces is Admin, Initializable {
  mapping(InterfaceType => mapping(bytes4 => bool)) private _supportedInterfaces;
  mapping(ChainIdType => mapping(uint256 => mapping(ChainIdType => uint256))) private _chainIdMap;
  mapping(TokenUriType => string) private _prependURI;

  constructor() {
    _prependURI[TokenUriType.IPFS] = "ipfs://";
    _prependURI[TokenUriType.HTTPS] = "https://";
    _prependURI[TokenUriType.ARWEAVE] = "ar://";

    // ERC20

    // ERC165
    _supportedInterfaces[InterfaceType.ERC20][ERC165.supportsInterface.selector] = true;

    // ERC20
    _supportedInterfaces[InterfaceType.ERC20][ERC20.allowance.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20.approve.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20.balanceOf.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20.totalSupply.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20.transfer.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20.transferFrom.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][
      ERC20.allowance.selector ^
        ERC20.approve.selector ^
        ERC20.balanceOf.selector ^
        ERC20.totalSupply.selector ^
        ERC20.transfer.selector ^
        ERC20.transferFrom.selector
    ] = true;

    // ERC20Metadata
    _supportedInterfaces[InterfaceType.ERC20][ERC20Metadata.name.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20Metadata.symbol.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20Metadata.decimals.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][
      ERC20Metadata.name.selector ^ ERC20Metadata.symbol.selector ^ ERC20Metadata.decimals.selector
    ] = true;

    // ERC20Burnable
    _supportedInterfaces[InterfaceType.ERC20][ERC20Burnable.burn.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20Burnable.burnFrom.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20Burnable.burn.selector ^ ERC20Burnable.burnFrom.selector] = true;

    // ERC20Safer
    _supportedInterfaces[InterfaceType.ERC20][functionsig("safeTransfer(address,uint256)")] = true;
    _supportedInterfaces[InterfaceType.ERC20][functionsig("safeTransfer(address,uint256,bytes)")] = true;
    _supportedInterfaces[InterfaceType.ERC20][functionsig("safeTransferFrom(address,address,uint256)")] = true;
    _supportedInterfaces[InterfaceType.ERC20][functionsig("safeTransferFrom(address,address,uint256,bytes)")] = true;
    _supportedInterfaces[InterfaceType.ERC20][
      bytes4(functionsig("safeTransfer(address,uint256)")) ^
        bytes4(functionsig("safeTransfer(address,uint256,bytes)")) ^
        bytes4(functionsig("safeTransferFrom(address,address,uint256)")) ^
        bytes4(functionsig("safeTransferFrom(address,address,uint256,bytes)"))
    ] = true;

    // ERC20Permit
    _supportedInterfaces[InterfaceType.ERC20][ERC20Permit.permit.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20Permit.nonces.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][ERC20Permit.DOMAIN_SEPARATOR.selector] = true;
    _supportedInterfaces[InterfaceType.ERC20][
      ERC20Permit.permit.selector ^ ERC20Permit.nonces.selector ^ ERC20Permit.DOMAIN_SEPARATOR.selector
    ] = true;

    // ERC721

    // ERC165
    _supportedInterfaces[InterfaceType.ERC721][ERC165.supportsInterface.selector] = true;

    // ERC721
    _supportedInterfaces[InterfaceType.ERC721][ERC721.balanceOf.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.ownerOf.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][functionsig("safeTransferFrom(address,address,uint256)")] = true;
    _supportedInterfaces[InterfaceType.ERC721][functionsig("safeTransferFrom(address,address,uint256,bytes)")] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.transferFrom.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.approve.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.setApprovalForAll.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.getApproved.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.isApprovedForAll.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][
      ERC721.balanceOf.selector ^
        ERC721.ownerOf.selector ^
        functionsig("safeTransferFrom(address,address,uint256)") ^
        functionsig("safeTransferFrom(address,address,uint256,bytes)") ^
        ERC721.transferFrom.selector ^
        ERC721.approve.selector ^
        ERC721.setApprovalForAll.selector ^
        ERC721.getApproved.selector ^
        ERC721.isApprovedForAll.selector
    ] = true;

    // ERC721Enumerable
    _supportedInterfaces[InterfaceType.ERC721][ERC721Enumerable.totalSupply.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721Enumerable.tokenByIndex.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721Enumerable.tokenOfOwnerByIndex.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][
      ERC721Enumerable.totalSupply.selector ^
        ERC721Enumerable.tokenByIndex.selector ^
        ERC721Enumerable.tokenOfOwnerByIndex.selector
    ] = true;

    // ERC721Metadata
    _supportedInterfaces[InterfaceType.ERC721][ERC721Metadata.name.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721Metadata.symbol.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721Metadata.tokenURI.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][
      ERC721Metadata.name.selector ^ ERC721Metadata.symbol.selector ^ ERC721Metadata.tokenURI.selector
    ] = true;

    // adding ERC20-like-Metadata support for Etherscan totalSupply fix
    _supportedInterfaces[InterfaceType.ERC721][ERC20Metadata.decimals.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][
      ERC721Metadata.name.selector ^ ERC721Metadata.symbol.selector ^ ERC20Metadata.decimals.selector
    ] = true;

    // ERC721TokenReceiver
    _supportedInterfaces[InterfaceType.ERC721][ERC721TokenReceiver.onERC721Received.selector] = true;

    // CollectionURI
    _supportedInterfaces[InterfaceType.ERC721][CollectionURI.contractURI.selector] = true;

    // PA1D
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.initPA1D.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.configurePayouts.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getPayoutInfo.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getEthPayout.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getTokenPayout.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getTokensPayout.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.supportsInterface.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.setRoyalties.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.royaltyInfo.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getFeeBps.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getFeeRecipients.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getFeeBps.selector ^ IPA1D.getFeeRecipients.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getRoyalties.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getFees.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.tokenCreator.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.calculateRoyaltyFee.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.marketContract.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.tokenCreators.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.bidSharesForToken.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getStorageSlot.selector] = true;
    _supportedInterfaces[InterfaceType.PA1D][IPA1D.getTokenAddress.selector] = true;
  }

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract.
   */
  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    address contractAdmin = abi.decode(data, (address));
    assembly {
      sstore(_adminSlot, contractAdmin)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  function contractURI(
    string calldata name,
    string calldata imageURL,
    string calldata externalLink,
    uint16 bps,
    address contractAddress
  ) external pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              name,
              '","description":"',
              name,
              '","image":"',
              imageURL,
              '","external_link":"',
              externalLink,
              '","seller_fee_basis_points":',
              Strings.uint2str(bps),
              ',"fee_recipient":"0x',
              Strings.toAsciiString(contractAddress),
              '"}'
            )
          )
        )
      );
  }

  function getUriPrepend(TokenUriType uriType) external view returns (string memory prepend) {
    prepend = _prependURI[uriType];
  }

  function updateUriPrepend(TokenUriType uriType, string calldata prepend) external onlyAdmin {
    _prependURI[uriType] = prepend;
  }

  function updateUriPrepends(TokenUriType[] calldata uriTypes, string[] calldata prepends) external onlyAdmin {
    for (uint256 i = 0; i < uriTypes.length; i++) {
      _prependURI[uriTypes[i]] = prepends[i];
    }
  }

  function getChainId(
    ChainIdType fromChainType,
    uint256 fromChainId,
    ChainIdType toChainType
  ) external view returns (uint256 toChainId) {
    return _chainIdMap[fromChainType][fromChainId][toChainType];
  }

  function updateChainIdMap(
    ChainIdType fromChainType,
    uint256 fromChainId,
    ChainIdType toChainType,
    uint256 toChainId
  ) external onlyAdmin {
    _chainIdMap[fromChainType][fromChainId][toChainType] = toChainId;
  }

  function updateChainIdMaps(
    ChainIdType[] calldata fromChainType,
    uint256[] calldata fromChainId,
    ChainIdType[] calldata toChainType,
    uint256[] calldata toChainId
  ) external onlyAdmin {
    uint256 length = fromChainType.length;
    for (uint256 i = 0; i < length; i++) {
      _chainIdMap[fromChainType[i]][fromChainId[i]][toChainType[i]] = toChainId[i];
    }
  }

  function supportsInterface(InterfaceType interfaceType, bytes4 interfaceId) external view returns (bool) {
    return _supportedInterfaces[interfaceType][interfaceId];
  }

  function updateInterface(
    InterfaceType interfaceType,
    bytes4 interfaceId,
    bool supported
  ) external onlyAdmin {
    _supportedInterfaces[interfaceType][interfaceId] = supported;
  }

  function updateInterfaces(
    InterfaceType interfaceType,
    bytes4[] calldata interfaceIds,
    bool supported
  ) external onlyAdmin {
    for (uint256 i = 0; i < interfaceIds.length; i++) {
      _supportedInterfaces[interfaceType][interfaceIds[i]] = supported;
    }
  }

  receive() external payable {
    revert();
  }

  fallback() external payable {
    revert();
  }
}
