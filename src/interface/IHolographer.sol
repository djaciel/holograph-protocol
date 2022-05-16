HOLOGRAPH_LICENSE_HEADER

SOLIDITY_COMPILER_VERSION

interface IHolographer {

    function getOriginChain() external view returns (uint32);

    function getHolographEnforcer() external view returns (address payable);

    function getSecureStorage() external pure returns (address);

    function getSourceContract() external pure returns (address payable);

}
