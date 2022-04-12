HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/IHolograph.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";

/*
 * @dev This contract is a binder. It puts together all the variables to make the underlying contracts functional and be bridgeable.
 */
contract Holographer is Admin, Initializable {

    /*
     * @dev Constructor is left empty and only the admin address is set.
     */
    constructor() Admin(true) {}

    function init(bytes memory data) external override returns (bytes4) {
        require(!_isInitialized(), "HOLOGRAPHER: already initialized");
        (bytes memory encoded, bytes memory initCode) = abi.decode(data, (bytes, bytes));
        (uint32 originChain, address holograph, address secureStorage, bytes32 contractType, address sourceContract) = abi.decode(encoded, (uint32, address, address, bytes32, address));
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.originChain'), originChain)
            sstore(precomputeslot('eip1967.Holograph.Bridge.holograph'), holograph)
            sstore(precomputeslot('eip1967.Holograph.Bridge.secureStorage'), secureStorage)
            sstore(precomputeslot('eip1967.Holograph.Bridge.contractType'), contractType)
            sstore(precomputeslot('eip1967.Holograph.Bridge.sourceContract'), sourceContract)
        }
        (bool success, bytes memory returnData) = getHolographEnforcer().delegatecall(
            abi.encodeWithSignature("init(bytes)", initCode)
        );
        (bytes4 selector) = abi.decode(returnData, (bytes4));
        require(success && selector == IInitializable.init.selector, "initialization failed");
        _setInitialized();
        return IInitializable.init.selector;
    }

    /*
     * @dev Returns a hardcoded address for the Holograph smart contract that controls and enforces the ERC standards.
     * @dev The choice to use this approach was taken to prevent storage slot overrides.
     */
    function getHolographEnforcer() public view returns (address payable) {
        address holograph;
        bytes32 contractType;
        assembly {
            holograph := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.holograph'))
            contractType := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.contractType'))
        }
        return payable(
            IHolographRegistry(
                IHolograph(
                    holograph
                ).getRegistry()
            ).getContractTypeAddress(contractType)
        );
    }

    /*
     * @dev Returns the original chain that contract was deployed on.
     */
    function getOriginChain() public view returns (uint32 originChain) {
        assembly {
            originChain := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.originChain'))
        }
    }

    /*
     * @dev Returns a hardcoded address for the custom secure storage contract deployed in parallel with this contract deployment.
     */
    function getSecureStorage() public view returns (address secureStorage) {
        assembly {
            secureStorage := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.secureStorage'))
        }
    }

    /*
     * @dev Returns a hardcoded address for the custom secure storage contract deployed in parallel with this contract deployment.
     */
    function getSourceContract() public view returns (address payable sourceContract) {
        assembly {
            sourceContract := sload(/* slot */precomputeslot('eip1967.Holograph.Bridge.sourceContract'))
        }
    }

    /*
     * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
     */
    receive() external payable {}

    /*
     * @dev Hard-coded registry address and contract type are put inside the fallback to make sure that the contract cannot be modified.
     * @dev This takes the underlying address source code, runs it, and uses current address for storage.
     */
    fallback() external payable {
        address holographEnforcer = getHolographEnforcer();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), holographEnforcer, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

}
