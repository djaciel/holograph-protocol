/*SOLIDITY_COMPILER_VERSION*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct DropInitializer {
  address holographFeeManager;
  address holographERC721TransferHelper;
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
