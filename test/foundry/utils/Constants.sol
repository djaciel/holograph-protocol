// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// NOTE: These are the addresses of the Holograph Protocol that depends on a couple .env variables being set
//       Those variable are:
//         HOLOGRAPH_ENVIRONMENT="develop"
//         DEVELOP_DEPLOYMENT_SALT=1000
//         DEPLOYER=0xff22437ccbedfffafa93a9f1da2e8c19c1711052799acf3b58ae5bebb5c6bd7b
//         LOCALHOST_DEPLOYER_SECRET=something
//
// These addresses are for the develop environment ONLY on localhost and are not meant to be used in production.
// They are generated from a localhost deployment using the custom HolographGenesisLocal.sol contract that is a
// modified version of the HolographGenesis.sol contract.
//
// The reason we use a custom version of the HolographGenesis.sol contract is because the original contract has
// dedicated approved deployers that do not include local test accounts. This allows us to test the Holograph Protocol
// on localhost without having to modify the original HolographGenesis.sol contract.
library Constants {
  function getHolographGenesis() internal pure returns (address) {
    return address(0x4c3BA951A7ea09b5BB57230F63a89D36A07B2992);
  }

  function getHolograph() internal pure returns (address) {
    return address(0x17253175f447ca4B560a87a3F39591DFC7A021e3);
  }

  function getHolographBridgeProxy() internal pure returns (address) {
    return address(0x53D2B46b341385bC7e022667Eb1860505073D43a);
  }

  function getHolographFactoryProxy() internal pure returns (address) {
    return address(0xcE2cDFDF0b9D45F8Bd2D3CCa4033527301903FDe);
  }

  function getHolographOperatorProxy() internal pure returns (address) {
    return address(0xABc5a4C81D3033cf920b982E75D1080b91AA0EF9);
  }

  function getHolographRegistryProxy() internal pure returns (address) {
    return address(0xB47C0E0170306583AA979bF30c0407e2bFE234b2);
  }

  function getHolographTreasuryProxy() internal pure returns (address) {
    return address(0x65115A3Be2Aa1F267ccD7499e720088060c7ccd2);
  }

  function getHolographInterfaces() internal pure returns (address) {
    return address(0x67F6394693bd2B46BBE87627F0E581faD80C7B57);
  }

  function getHolographRoyalties() internal pure returns (address) {
    return address(0xbF8f7474D7aCbb87E270FEDA9A5CBB7f766887E3);
  }

  function getHolographUtilityToken() internal pure returns (address) {
    return address(0x56BA455232a82784F17C33c577124EF208D931ED);
  }

  function getDropsPriceOracleProxy() internal pure returns (address) {
    return address(0x655FC5B66322AEF43A01dBc7198e08ab163662c3);
  }

  function getDummyDropsPriceOracle() internal pure returns (address) {
    return address(0x98E2Ed9849B14E541454Ae6202b4cA06627269C1);
  }

  function getDropsEventConfig() internal pure returns (uint256) {
    return 0x0000000000000000000000000000000000000000000000000000000000040000;
  }
}
