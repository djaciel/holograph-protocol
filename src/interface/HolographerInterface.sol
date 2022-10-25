/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

interface HolographerInterface {
  //  // this is temporarily disabled for testnets, to not lose previous versions of Holographer contracts
  //  function getContractType() external view returns (bytes32 contractType);

  function getDeploymentBlock() external view returns (address holograph);

  function getHolograph() external view returns (address holograph);

  function getHolographEnforcer() external view returns (address);

  function getOriginChain() external view returns (uint32 originChain);

  function getSourceContract() external view returns (address sourceContract);
}
