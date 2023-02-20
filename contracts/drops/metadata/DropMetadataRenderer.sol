// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../../abstract/Initializable.sol";

import {IMetadataRenderer} from "../interfaces/IMetadataRenderer.sol";
import {MetadataRenderAdminCheck} from "./MetadataRenderAdminCheck.sol";

library StringsUpgradeable {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }
}

/// @notice Drops metadata system
contract DropMetadataRenderer is Initializable, IMetadataRenderer, MetadataRenderAdminCheck {
  error MetadataFrozen();

  /// Event to mark updated metadata information
  event MetadataUpdated(
    address indexed target,
    string metadataBase,
    string metadataExtension,
    string contractURI,
    uint256 freezeAt
  );

  /// @notice Hash to mark updated provenance hash
  event ProvenanceHashUpdated(address indexed target, bytes32 provenanceHash);

  /// @notice Struct to store metadata info and update data
  struct MetadataURIInfo {
    string base;
    string extension;
    string contractURI;
    uint256 freezeAt;
  }

  /// @notice NFT metadata by contract
  mapping(address => MetadataURIInfo) public metadataBaseByContract;

  /// @notice Optional provenance hashes for NFT metadata by contract
  mapping(address => bytes32) public provenanceHashes;

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @dev A blank init function is required to be able to call genesisDeriveFutureAddress to get the deterministic address
   * @dev Since no data is required to be intialized the selector is just returned and _setInitialized() does not need to be called
   */
  function init(
    bytes memory /* initPayload */
  ) external pure override returns (bytes4) {
    return InitializableInterface.init.selector;
  }

  /// @notice Standard init for drop metadata from root drop contract
  /// @param data passed in for initialization
  function initializeWithData(bytes memory data) external {
    // data format: string baseURI, string newContractURI
    (string memory initialBaseURI, string memory initialContractURI) = abi.decode(data, (string, string));
    _updateMetadataDetails(msg.sender, initialBaseURI, "", initialContractURI, 0);
  }

  /// @notice Update the provenance hash (optional) for a given nft
  /// @param target target address to update
  /// @param provenanceHash provenance hash to set
  function updateProvenanceHash(address target, bytes32 provenanceHash) external requireSenderAdmin(target) {
    provenanceHashes[target] = provenanceHash;
    emit ProvenanceHashUpdated(target, provenanceHash);
  }

  /// @notice Update metadata base URI and contract URI
  /// @param baseUri new base URI
  /// @param newContractUri new contract URI (can be an empty string)
  function updateMetadataBase(
    address target,
    string memory baseUri,
    string memory newContractUri
  ) external requireSenderAdmin(target) {
    _updateMetadataDetails(target, baseUri, "", newContractUri, 0);
  }

  /// @notice Update metadata base URI, extension, contract URI and freezing detailsUpdate metadata base URI, extension, contract URI and freezing detailsUpdate metadata base URI, extension, contract URI and freezing detailsUpdate metadata base URI, extension, contract URI and freezing detailsUpdate metadata base URI, extension, contract URI and freezing detailsUpdate metadata base URI, extension, contract URI and freezing detailsUpdate metadata base URI, extension, contract URI and freezing detailsUpdate metadata base URI, extension, contract URI and freezing details
  /// @param target target contract to update metadata for
  /// @param metadataBase new base URI to update metadata with
  /// @param metadataExtension new extension to append to base metadata URI
  /// @param freezeAt time to freeze the contract metadata at (set to 0 to disable)
  function updateMetadataBaseWithDetails(
    address target,
    string memory metadataBase,
    string memory metadataExtension,
    string memory newContractURI,
    uint256 freezeAt
  ) external requireSenderAdmin(target) {
    _updateMetadataDetails(target, metadataBase, metadataExtension, newContractURI, freezeAt);
  }

  /// @notice Internal metadata update function
  /// @param metadataBase Base URI to update metadata for
  /// @param metadataExtension Extension URI to update metadata for
  /// @param freezeAt timestamp to freeze metadata (set to 0 to disable freezing)
  function _updateMetadataDetails(
    address target,
    string memory metadataBase,
    string memory metadataExtension,
    string memory newContractURI,
    uint256 freezeAt
  ) internal {
    if (freezeAt != 0 && freezeAt > block.timestamp) {
      revert MetadataFrozen();
    }

    metadataBaseByContract[target] = MetadataURIInfo({
      base: metadataBase,
      extension: metadataExtension,
      contractURI: newContractURI,
      freezeAt: freezeAt
    });
    emit MetadataUpdated({
      target: target,
      metadataBase: metadataBase,
      metadataExtension: metadataExtension,
      contractURI: newContractURI,
      freezeAt: freezeAt
    });
  }

  /// @notice A contract URI for the given drop contract
  /// @dev reverts if a contract uri is not provided
  /// @return contract uri for the contract metadata
  function contractURI() external view override returns (string memory) {
    string memory uri = metadataBaseByContract[msg.sender].contractURI;
    if (bytes(uri).length == 0) revert();
    return uri;
  }

  /// @notice A token URI for the given drops contract
  /// @dev reverts if a contract uri is not set
  /// @return token URI for the given token ID and contract (set by msg.sender)
  function tokenURI(uint256 tokenId) external view override returns (string memory) {
    MetadataURIInfo memory info = metadataBaseByContract[msg.sender];

    if (bytes(info.base).length == 0) revert();

    return string(abi.encodePacked(info.base, StringsUpgradeable.toString(tokenId), info.extension));
  }
}
