HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

interface IInitializable {

    function init(bytes memory _data) external returns (bytes4);

}
