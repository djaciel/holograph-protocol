/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "../abstract/Initializable.sol";

abstract contract ERC721H is Initializable {
  /**
   * @dev Address of initial creator/owner of the collection.
   */
  address internal _owner;

  modifier onlyHolographer() {
    require(msg.sender == holographer(), "ERC721: holographer only");
    _;
  }

  modifier onlyOwner() {
    if (msg.sender == holographer()) {
      require(msgSender() == _owner, "ERC721: owner only function");
    } else {
      require(msg.sender == _owner, "ERC721: owner only function");
    }
    _;
  }

  /**
   * @notice Constructor is empty and not utilised.
   * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
   */
  constructor() {}

  /**
   * @notice Initializes the collection.
   * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
   */
  function init(bytes memory data) external virtual override returns (bytes4) {
    return _init(data);
  }

  function _init(
    bytes memory /* data*/
  ) internal returns (bytes4) {
    require(!_isInitialized(), "ERC721: already initialized");
    address _holographer = msg.sender;
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.holographer"), _holographer)
    }
    _setInitialized();
    return IInitializable.init.selector;
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
      _holographer := sload(precomputeslot("eip1967.Holograph.Bridge.holographer"))
    }
  }

  function supportsInterface(bytes4) external pure returns (bool) {
    return false;
  }

  function owner() external view returns (address) {
    return _owner;
  }

  function isOwner() external view returns (bool) {
    if (msg.sender == holographer()) {
      return msgSender() == _owner;
    } else {
      return msg.sender == _owner;
    }
  }

  function isOwner(address wallet) external view returns (bool) {
    return wallet == _owner;
  }

  /**
   * @dev Defined here to suppress compiler warnings
   */
  receive() external payable {}

  /**
   * @dev Return true for any un-implemented event hooks
   */
  fallback() external payable {
    assembly {
      switch eq(sload(precomputeslot("eip1967.Holograph.Bridge.holographer")), caller())
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
