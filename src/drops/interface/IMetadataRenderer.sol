// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

interface IMetadataRenderer {
  function tokenURI(uint256) external view returns (string memory);

  function contractURI() external view returns (string memory);

  function initializeWithData(bytes memory initData) external;
}
