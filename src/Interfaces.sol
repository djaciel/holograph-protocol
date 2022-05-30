/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./enum/InterfaceType.sol";

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

import "./library/Base64.sol";
import "./library/Strings.sol";

contract Interfaces is Admin, Initializable {
  mapping(InterfaceType => mapping(bytes4 => bool)) private _supportedInterfaces;

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    address contractAdmin = abi.decode(data, (address));
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.admin"), contractAdmin)
    }

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
    // bytes4(keccak256(abi.encodePacked('safeTransfer(address,uint256)'))) == 0x423f6cef
    _supportedInterfaces[InterfaceType.ERC20][0x423f6cef] = true;
    // bytes4(keccak256(abi.encodePacked('safeTransfer(address,uint256,bytes)'))) == 0xeb795549
    _supportedInterfaces[InterfaceType.ERC20][0xeb795549] = true;
    // bytes4(keccak256(abi.encodePacked('safeTransferFrom(address,address,uint256)'))) == 0x42842e0e
    _supportedInterfaces[InterfaceType.ERC20][0x42842e0e] = true;
    // bytes4(keccak256(abi.encodePacked('safeTransferFrom(address,address,uint256,bytes)'))) == 0xb88d4fde
    _supportedInterfaces[InterfaceType.ERC20][0xb88d4fde] = true;
    _supportedInterfaces[InterfaceType.ERC20][
      bytes4(0x423f6cef) ^ bytes4(0xeb795549) ^ bytes4(0x42842e0e) ^ bytes4(0xb88d4fde)
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
    // bytes4(keccak256(abi.encodePacked('safeTransferFrom(address,address,uint256,bytes)'))) == 0xb88d4fde
    _supportedInterfaces[InterfaceType.ERC721][0xb88d4fde] = true;
    // bytes4(keccak256(abi.encodePacked('safeTransferFrom(address,address,uint256)'))) == 0x42842e0e
    _supportedInterfaces[InterfaceType.ERC721][0x42842e0e] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.transferFrom.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.approve.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.setApprovalForAll.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.getApproved.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.isApprovedForAll.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][
      ERC721.balanceOf.selector ^
        ERC721.ownerOf.selector ^
        0xb88d4fde ^
        0x42842e0e ^
        ERC721.transferFrom.selector ^
        ERC721.approve.selector ^
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

    // ERC721TokenReceiver
    _supportedInterfaces[InterfaceType.ERC721][ERC721TokenReceiver.onERC721Received.selector] = true;

    // CollectionURI
    _supportedInterfaces[InterfaceType.ERC721][CollectionURI.contractURI.selector] = true;

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

  receive() external payable {
    revert();
  }

  fallback() external payable {
    revert();
  }
}
