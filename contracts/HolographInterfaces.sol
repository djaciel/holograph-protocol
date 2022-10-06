// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

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
    _supportedInterfaces[InterfaceType.ERC20][0x423f6cef] = true;
    _supportedInterfaces[InterfaceType.ERC20][0xeb795549] = true;
    _supportedInterfaces[InterfaceType.ERC20][0x42842e0e] = true;
    _supportedInterfaces[InterfaceType.ERC20][0xb88d4fde] = true;
    _supportedInterfaces[InterfaceType.ERC20][
      bytes4(0x423f6cef) ^
        bytes4(0xeb795549) ^
        bytes4(0x42842e0e) ^
        bytes4(0xb88d4fde)
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
    _supportedInterfaces[InterfaceType.ERC721][0x42842e0e] = true;
    _supportedInterfaces[InterfaceType.ERC721][0xb88d4fde] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.transferFrom.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.approve.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.setApprovalForAll.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.getApproved.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][ERC721.isApprovedForAll.selector] = true;
    _supportedInterfaces[InterfaceType.ERC721][
      ERC721.balanceOf.selector ^
        ERC721.ownerOf.selector ^
        0x42842e0e ^
        0xb88d4fde ^
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
