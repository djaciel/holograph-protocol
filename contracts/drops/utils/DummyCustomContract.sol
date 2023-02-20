// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../../abstract/Initializable.sol";

contract DummyCustomContract is Initializable {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.holographer')) - 1)
   */
  bytes32 constant _holographerSlot = 0xe9fcff60011c1a99f7b7244d1f2d9da93d79ea8ef3654ce590d775575255b2bd;
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.owner')) - 1)
   */
  bytes32 constant _ownerSlot = 0xb56711ba6bd3ded7639fc335ee7524fe668a79d7558c85992e3f8494cf772777;

  modifier onlyHolographer() {
    require(msg.sender == holographer(), "DROPS: holographer only");
    _;
  }

  modifier onlyOwner() {
    if (msg.sender == holographer()) {
      require(msgSender() == _getOwner(), "DROPS: owner only function");
    } else {
      require(msg.sender == _getOwner(), "DROPS: owner only function");
    }
    _;
  }

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "DROPS: already initialized");
    address _holographer = msg.sender;
    assembly {
      sstore(_ownerSlot, caller())
      sstore(_holographerSlot, _holographer)
    }
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  /**
   * @dev The Holographer passes original msg.sender via calldata. This function extracts it.
   */
  function msgSender() internal pure returns (address sender) {
    assembly {
      sender := calldataload(sub(calldatasize(), 0x20))
    }
  }

  /**
   * @dev Address of Holograph ERC721 standards enforcer smart contract.
   */
  function holographer() internal view returns (address _holographer) {
    assembly {
      _holographer := sload(_holographerSlot)
    }
  }

  function supportsInterface(bytes4) external pure returns (bool) {
    return false;
  }

  /**
   * @dev Address of initial creator/owner of the collection.
   */
  function owner() external view returns (address) {
    return _getOwner();
  }

  function isOwner() external view returns (bool) {
    if (msg.sender == holographer()) {
      return msgSender() == _getOwner();
    } else {
      return msg.sender == _getOwner();
    }
  }

  function isOwner(address wallet) external view returns (bool) {
    return wallet == _getOwner();
  }

  function _getOwner() internal view returns (address ownerAddress) {
    assembly {
      ownerAddress := sload(_ownerSlot)
    }
  }

  function _setOwner(address ownerAddress) internal {
    assembly {
      sstore(_ownerSlot, ownerAddress)
    }
  }

  function withdraw() external virtual onlyOwner {
    payable(_getOwner()).transfer(address(this).balance);
  }

  /**
   * @dev This function is unreachable unless custom contract address is called directly.
   *      Please use custom payable functions for accepting native value.
   */
  receive() external payable {
    revert("DROPS: unreachable code");
  }

  /**
   * @dev Return true for any un-implemented event hooks
   */
  fallback() external payable {
    assembly {
      switch eq(sload(_holographerSlot), caller())
      case 1 {
        mstore(0x80, 0x0000000000000000000000000000000000000000000000000000000000000001)
        return(0x80, 0x20)
      }
      default {
        revert(0x00, 0x00)
      }
    }
  }
}
