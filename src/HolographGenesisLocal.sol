/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./interface/InitializableInterface.sol";

/**
 * @title HOLOGRAPH GENESIS
 * @dev In the beginning there was a smart contract...
 */
contract HolographGenesisLocal {
  uint32 private immutable _version;

  // Immutable addresses of the initial deployers
  address private immutable deployer1 = 0xdf5295149F367b1FBFD595bdA578BAd22e59f504;

  // Mapping of addresses that are approved deployers
  mapping(address => bool) private _approvedDeployers;

  // Events
  event Message(string message);
  event ContractDeployed(address deployedContract);

  // Modifier to restrict function calls to approved deployers
  modifier onlyDeployer() {
    require(_approvedDeployers[msg.sender], "HOLOGRAPH: deployer not approved");
    _;
  }

  /**
   * @dev Sets the initial deployers as approved upon contract creation.
   */
  constructor() {
    _version = 2;

    // Set the immutable deployers as approved
    _approvedDeployers[deployer1] = true;

    emit Message("The future is Holographic");
  }

  /**
   * @dev Deploy a contract using the EIP-1014 (create2) opcode for deterministic addresses.
   * @param chainId The chain on which to deploy
   * @param saltHash A unique salt for contract creation
   * @param secret A secret part of the salt
   * @param sourceCode The bytecode of the contract to deploy
   * @param initCode The initialization code for the contract
   */
  function deploy(
    uint256 chainId,
    bytes12 saltHash,
    bytes20 secret,
    bytes memory sourceCode,
    bytes memory initCode
  ) external onlyDeployer {
    require(chainId == block.chainid, "HOLOGRAPH: incorrect chain id");
    bytes32 salt = bytes32(abi.encodePacked(secret, saltHash));
    address contractAddress = address(
      uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(sourceCode)))))
    );
    require(!_isContract(contractAddress), "HOLOGRAPH: already deployed");
    assembly {
      contractAddress := create2(0, add(sourceCode, 0x20), mload(sourceCode), salt)
    }
    require(_isContract(contractAddress), "HOLOGRAPH: deployment failed");
    require(
      InitializableInterface(contractAddress).init(initCode) == InitializableInterface.init.selector,
      "HOLOGRAPH: initialization failed"
    );

    emit ContractDeployed(contractAddress);
  }

  /**
   * @dev Approve or revoke an address as a deployer.
   * @param newDeployer Address to approve or revoke
   * @param approve Boolean to approve or revoke
   */
  function approveDeployer(address newDeployer, bool approve) external onlyDeployer {
    _approvedDeployers[newDeployer] = approve;
  }

  /**
   * @dev Check if an address is an approved deployer.
   * @param deployer Address to check
   * @return bool representing approval status
   */
  function isApprovedDeployer(address deployer) external view returns (bool) {
    return _approvedDeployers[deployer];
  }

  /**
   * @dev Internal function to determine if an address is a deployed contract.
   * @param contractAddress The address to check
   * @return bool representing if the address is a contract
   */
  function _isContract(address contractAddress) internal view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(contractAddress)
    }
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
  }

  /**
   * @dev Returns the version number of the Genesis contract
   * @return uint32 representing the version number
   */
  function getVersion() external view returns (uint32) {
    return _version;
  }
}
