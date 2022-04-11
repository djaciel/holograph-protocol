HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IInitializable.sol";

contract Holograph is Admin, Initializable {

    constructor() Admin(false) {}

    function init(bytes memory data) external override returns (bytes4) {
        require(!_isInitialized(), "HOLOGRAPH: already initialized");
        (uint32 chainType, address registry, address factory, address bridge, address secureStorage) = abi.decode(data, (uint32, address, address, address, address));
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.chainType'), chainType)
            sstore(precomputeslot('eip1967.Holograph.Bridge.registry'), registry)
            sstore(precomputeslot('eip1967.Holograph.Bridge.factory'), factory)
            sstore(precomputeslot('eip1967.Holograph.Bridge.bridge'), bridge)
            sstore(precomputeslot('eip1967.Holograph.Bridge.secureStorage'), secureStorage)
        }
        _setInitialized();
        return IInitializable.init.selector;
    }

    /*
     * @dev Returns an integer value of the chain type that the factory is currently on.
     * @dev For example:
     *                   1 = Ethereum mainnet
     *                   2 = Binance Smart Chain mainnet
     *                   3 = Avalanche mainnet
     *                   4 = Polygon mainnet
     *                   etc.
     */
    function getChainType() public view returns (uint32 chainType) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.chainType')) - 1);
        assembly {
            chainType := sload(precomputeslot('eip1967.Holograph.Bridge.chainType'))
        }
    }

    /*
     * @dev Sets the chain type that the factory is currently on.
     */
    function setChainType(uint32 chainType) public onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.chainType')) - 1);
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.chainType'), chainType)
        }
    }

    function getBridge() external view returns (address bridge) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.bridge')) - 1);
        assembly {
            bridge := sload(precomputeslot('eip1967.Holograph.Bridge.bridge'))
        }
    }

    function setBridge(address bridge) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.bridge')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.bridge'), bridge)
        }
    }

    function getFactory() external view returns (address factory) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factory')) - 1);
        assembly {
            factory := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.factory'))
        }
    }

    function setFactory(address factory) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factory')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.factory'), factory)
        }
    }

    function getRegistry() external view returns (address registry) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
        assembly {
            registry := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.registry'))
        }
    }

    function setRegistry(address registry) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.registry'), registry)
        }
    }

    function getSecureStorage() external view returns (address secureStorage) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
        assembly {
            secureStorage := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.secureStorage'))
        }
    }

    function setSecureStorage(address secureStorage) external onlyAdmin {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.secureStorage')) - 1);
        assembly {
            sstore(/* slot */precomputeslot('eip1967.Holograph.Bridge.secureStorage'), secureStorage)
        }
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

}
