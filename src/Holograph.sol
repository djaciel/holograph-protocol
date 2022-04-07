HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;


import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IInitializable.sol";

contract Holograph is Admin, Initializable {

    constructor() Admin(false) {}

    function init(bytes memory data) external override returns (bytes4) {
        require(!_isInitialized(), "HOLOGRAPH: already initialized");
        (address bridge, address factory, address registry) = abi.decode(data, (address, address, address));
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.bridgeAddress'), bridge)
            sstore(precomputeslot('eip1967.Holograph.Bridge.factoryAddress'), factory)
            sstore(precomputeslot('eip1967.Holograph.Bridge.registryAddress'), registry)
        }
        _setInitialized();
        return IInitializable.init.selector;
    }

    function getBridge() external view returns (address bridgeAddress) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.bridgeAddress')) - 1);
        assembly {
            bridgeAddress := sload(precomputeslot('eip1967.Holograph.Bridge.bridgeAddress'))
        }
    }

    function setBridge(address bridgeAddress) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.bridgeAddress')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.bridgeAddress'), bridgeAddress)
        }
    }

    function getFactory() external view returns (address factoryAddress) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factoryAddress')) - 1);
        assembly {
            factoryAddress := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.factoryAddress'))
        }
    }

    function setFactory(address factoryAddress) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factoryAddress')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.factoryAddress'), factoryAddress)
        }
    }

    function getRegistry() external view returns (address registryAddress) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registryAddress')) - 1);
        assembly {
            registryAddress := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.registryAddress'))
        }
    }

    function setRegistry(address registryAddress) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registryAddress')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.registryAddress'), registryAddress)
        }
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

}
