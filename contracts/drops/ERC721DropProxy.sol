// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ERC721DropProxy is ERC1967Proxy {
  constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}
}

// TODO: Update the proxy to use holograph style initialization
// import "../abstract/Admin.sol";
// import "../abstract/Initializable.sol";

// import "../interface/InitializableInterface.sol";
// import "../interface/HolographRegistryInterface.sol";

// contract ERC721DropProxy is Admin, Initializable {
//   /**
//    * @dev bytes32(uint256(keccak256('eip1967.Holograph.contractType')) - 1)
//    */
//   bytes32 constant _contractTypeSlot = 0x0b671eb65810897366dd82c4cbb7d9dff8beda8484194956e81e89b8a361d9c7;
//   /**
//    * @dev bytes32(uint256(keccak256('eip1967.Holograph.registry')) - 1)
//    */
//   bytes32 constant _registrySlot = 0xce8e75d5c5227ce29a4ee170160bb296e5dea6934b80a9bd723f7ef1e7c850e7;

//   constructor() {}

//   function init(bytes memory data) external override returns (bytes4) {
//     require(!_isInitialized(), "HOLOGRAPH: already initialized");
//     (bytes32 contractType, address registry, bytes memory initCode) = abi.decode(data, (bytes32, address, bytes));
//     assembly {
//       sstore(_contractTypeSlot, contractType)
//       sstore(_registrySlot, registry)
//     }
//     (bool success, bytes memory returnData) = getERC721DropsSource().delegatecall(
//       abi.encodeWithSignature("init(bytes)", initCode)
//     );
//     bytes4 selector = abi.decode(returnData, (bytes4));
//     require(success && selector == InitializableInterface.init.selector, "initialization failed");

//     _setInitialized();
//     return InitializableInterface.init.selector;
//   }

//   function getERC721DropsSource() public view returns (address) {
//     HolographRegistryInterface registry;
//     bytes32 contractType;
//     assembly {
//       registry := sload(_registrySlot)
//       contractType := sload(_contractTypeSlot)
//     }
//     return registry.getContractTypeAddress(contractType);
//   }

//   receive() external payable {}

//   fallback() external payable {
//     address erc721DropsSource = getERC721DropsSource();
//     assembly {
//       calldatacopy(0, 0, calldatasize())
//       let result := delegatecall(gas(), erc721DropsSource, 0, calldatasize(), 0, 0)
//       returndatacopy(0, 0, returndatasize())
//       switch result
//       case 0 {
//         revert(0, returndatasize())
//       }
//       default {
//         return(0, returndatasize())
//       }
//     }
//   }
// }
