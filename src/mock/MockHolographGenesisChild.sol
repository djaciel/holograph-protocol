/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../HolographGenesis.sol";

contract MockHolographGenesisChild is HolographGenesis {
  constructor() {}

  function approveDeployerMock(address newDeployer, bool approve) external onlyDeployer {
    // TODO: Implement mock signature recovery
    bytes memory sig1 = new bytes(0);
    bytes memory sig2 = new bytes(0);

    return this.approveDeployer(1, newDeployer, approve, sig1, sig2);
  }

  function isApprovedDeployerMock(address deployer) external view returns (bool) {
    return this.isApprovedDeployer(deployer);
  }
}
