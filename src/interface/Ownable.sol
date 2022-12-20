/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

interface Ownable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function owner() external view returns (address);

  function transferOwnership(address _newOwner) external;

  function isOwner() external view returns (bool);

  function isOwner(address wallet) external view returns (bool);
}
