HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

interface IHolographer {

    function getOriginChain() external view returns (uint32);

    function getHolographEnforcer() external view returns (address payable);

    function getSecureStorage() external pure returns (address);

    function getSourceContract() external pure returns (address payable);

}
