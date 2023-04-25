/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

/// @title Holograph Generic Standard
interface HolographedGeneric {
  // event id = 1
  function bridgeIn(uint32 _chainId, bytes calldata _data) external returns (bool success);

  // event id = 2
  function bridgeOut(uint32 _chainId, address _sender, bytes calldata _payload) external returns (bytes memory _data);
}
