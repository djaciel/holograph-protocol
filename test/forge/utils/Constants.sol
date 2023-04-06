// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// NOTE: These are the addresses of the Holograph Protocol that depends on a couple .env variables being set
//       Those variable are:
//         HOLOGRAPH_ENVIRONMENT="develop"
//         DEVELOP_DEPLOYMENT_SALT=1000
//         DEPLOYER=0xff22437ccbedfffafa93a9f1da2e8c19c1711052799acf3b58ae5bebb5c6bd7b
library Constants {
  function getHolographGenesis() internal pure returns (address) {
    return address(0x0C8aF56F7650a6E3685188d212044338c21d3F73);
  }

  function getHolograph() internal pure returns (address) {
    return address(0xd752b07E796b2C7A6dA24d660822C7bc51802DCa);
  }

  function getHolographBridge() internal pure returns (address) {
    return address(0xD0a093f5cCCf592eEb5B8E4c09d75706E80596DF);
  }

  function getHolographFactory() internal pure returns (address) {
    return address(0x5Db4dB97fDfFB29cD85eA5484C3722095c413fc7);
  }

  function getHolographOperator() internal pure returns (address) {
    return address(0x8a859b477678ff4eb5a6e9e169A31107785Ed1E0);
  }

  function getHolographRegistry() internal pure returns (address) {
    return address(0x7650afc7E875c1FCC987AB437967fF707f1b600f);
  }

  function getHolographTreasury() internal pure returns (address) {
    return address(0x3A4fb9f77789f8cdbae9B13D5f733A150ac5ca09);
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

  function getOpenseaRoyaltiesRegistry() internal pure returns (address) {
    return address(0x000000000000AAeB6D7670E522A718067333cd4E);
  }

  function getDropsPriceOracleProxy() internal pure returns (address) {
    return address(0xA3Db09EEC42BAfF7A50fb8F9aF90A0e035Ef3302);
  }

  function getDropsEventConfig() internal pure returns (uint256) {
    return 0x0000000000000000000000000000000000000000000000000000000000065000;
  }
}
