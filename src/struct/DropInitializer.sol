/*SOLIDITY_COMPILER_VERSION*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

///  @param _contractName Contract name
///  @param _contractSymbol Contract symbol
///  @param _initialOwner User that owns and can mint the edition, gets royalty and sales payouts and can update the base url if needed.
///  @param _fundsRecipient Wallet/user that receives funds from sale
///  @param _editionSize Number of editions that can be minted in total. If type(uint64).max, unlimited editions can be minted as an open edition.
///  @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
///  @param _setupCalls Bytes-encoded list of setup multicalls
///  @param _metadataRenderer Renderer contract to use
///  @param _metadataRendererInit Renderer data initial contract
struct DropInitializer {
  address holographFeeManager;
  address ERC721TransferHelper;
  address factoryUpgradeGate;
  address marketFilterDAOAddress;
  string contractName;
  string contractSymbol;
  address initialOwner;
  address payable fundsRecipient;
  uint64 editionSize;
  uint16 royaltyBPS;
  bytes[] setupCalls;
  address metadataRenderer;
  bytes metadataRendererInit;
}
