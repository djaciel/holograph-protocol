// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// NOTE: These are the addresses of the Holograph Protocol that depends on a couple .env variables being set
//       Those variable are:
//         HOLOGRAPH_ENVIRONMENT="develop"
//         DEVELOP_DEPLOYMENT_SALT=1000
//         DEPLOYER=0xff22437ccbedfffafa93a9f1da2e8c19c1711052799acf3b58ae5bebb5c6bd7b
//
// These addresses are for the develop environment ONLY on localhost and are not meant to be used in production.
// They are generated from a localhost deployment using the custom HolographGenesisLocal.sol contract that is a
// modified version of the HolographGenesis.sol contract.
//
// The reason we use a custom version of the HolographGenesis.sol contract is because the original contract has
// dedicated approved deployers that do not include local test accounts. This allows us to test the Holograph Protocol
//  on localhost without having to modify the original HolographGenesis.sol contract.
library Constants {
  function getHolographGenesis() internal pure returns (address) {
    return address(0x4c3BA951A7ea09b5BB57230F63a89D36A07B2992);
  }

  function getHolograph() internal pure returns (address) {
    return address(0xB437D70130A322754Db56558416355e059f3de27);
  }

  function getHolographBridgeProxy() internal pure returns (address) {
    return address(0x84bdA3bd21D89cFA5F3419aEdFD83673be5D0840);
  }

  function getHolographFactoryProxy() internal pure returns (address) {
    return address(0x25e262fEB323AcB483D7b238b0F7670391Bc1905);
  }

  function getHolographOperatorProxy() internal pure returns (address) {
    return address(0x47D450c263FeC68dc46c4684Ca6A8f76736aa8d8);
  }

  function getHolographRegistryProxy() internal pure returns (address) {
    return address(0x1d56d0aa75C583F995745437F0E14aF82e5807b7);
  }

  function getHolographTreasuryProxy() internal pure returns (address) {
    return address(0x3c26247540919827E6CcfE901F345259a090eCe8);
  }

  function getHolographInterfaces() internal pure returns (address) {
    return address(0xd7Eb41796aA985ef6E1777cb5f4c613a8a94331B);
  }

  function getHolographRoyalties() internal pure returns (address) {
    return address(0xe2A99e15Dcbe380AeD48ea387AFF67b18287deA8);
  }

  function getHolographUtilityToken() internal pure returns (address) {
    return address(0xe92664b2a60541b4c24512091374FC036d8Cb738);
  }

  function getDropsPriceOracleProxy() internal pure returns (address) {
    return address(0xeA7f4C52cbD4CF1036CdCa8B16AcA11f5b09cF6E);
  }

  function getDropsEventConfig() internal pure returns (uint256) {
    return 0x0000000000000000000000000000000000000000000000000000000000065000;
  }
}
