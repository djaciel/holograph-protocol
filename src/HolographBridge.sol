/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./enum/ChainIdType.sol";

import "./interface/ERC20Holograph.sol";
import "./interface/ERC721Holograph.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographBridge.sol";
import "./interface/IHolographFactory.sol";
import "./interface/IHolographOperator.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";
import "./interface/IInterfaces.sol";

import "./struct/DeploymentConfig.sol";
import "./struct/Verification.sol";

/**
 * @dev This smart contract contains the actual core bridging logic.
 */
contract HolographBridge is Admin, Initializable, IHolographBridge {
  /**
   * @dev Constructor is left empty and only the admin address is set.
   */
  constructor() {}

  modifier onlyBridge() {
    require(msg.sender == address(this), "HOLOGRAPH: bridge only call");
    _;
  }

  modifier onlyOperator() {
    assembly {
      switch eq(sload(precomputeslot("eip1967.Holograph.Bridge.operator")), caller())
      case 0 {
        mstore(0x80, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0xa0, 0x0000002000000000000000000000000000000000000000000000000000000000)
        mstore(0xc0, 0x00000018484f4c4f47524150483a206f70657261746f72206f6e6c7900000000)
        mstore(0xe0, 0x0000000000000000000000000000000000000000000000000000000000000000)
        revert(0x80, 0xc4)
      }
    }
    _;
  }

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address factory, address holograph, address interfaces, address operator, address registry) = abi.decode(
      data,
      (address, address, address, address, address)
    );
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.admin"), origin())

      sstore(precomputeslot("eip1967.Holograph.Bridge.factory"), factory)
      sstore(precomputeslot("eip1967.Holograph.Bridge.holograph"), holograph)
      sstore(precomputeslot("eip1967.Holograph.Bridge.interfaces"), interfaces)
      sstore(precomputeslot("eip1967.Holograph.Bridge.operator"), operator)
      sstore(precomputeslot("eip1967.Holograph.Bridge.registry"), registry)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  function executeJob(bytes calldata _payload) external onlyOperator {
    assembly {
      calldatacopy(0, _payload.offset, _payload.length)
      let result := callcode(gas(), address(), callvalue(), 0, _payload.length, 0, 0)
      if eq(result, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  function erc721in(
    uint32 fromChain,
    address collection,
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external onlyBridge {
    require(_registry().isHolographedContract(collection), "HOLOGRAPH: not holographed");
    require(
      ERC721Holograph(collection).holographBridgeIn(fromChain, from, to, tokenId, data) ==
        ERC721Holograph.holographBridgeIn.selector,
      "HOLOGRAPH: bridge in failed"
    );
  }

  function erc721out(
    uint32 toChain,
    address collection,
    address from,
    address to,
    uint256 tokenId
  ) external payable {
    require(_registry().isHolographedContract(collection), "HOLOGRAPH: not holographed");
    ERC721Holograph erc721 = ERC721Holograph(collection);
    require(erc721.exists(tokenId), "HOLOGRAPH: token doesn't exist");
    address tokenOwner = erc721.ownerOf(tokenId);
    require(
      tokenOwner == msg.sender ||
        erc721.getApproved(tokenId) == msg.sender ||
        erc721.isApprovedForAll(tokenOwner, msg.sender),
      "HOLOGRAPH: not approved/owner"
    );
    require(to != address(0), "HOLOGRAPH: zero address");
    (bytes4 selector, bytes memory data) = erc721.holographBridgeOut(toChain, from, to, tokenId);
    require(selector == ERC721Holograph.holographBridgeOut.selector, "HOLOGRAPH: bridge out failed");
    _operator().send{value: msg.value}(
      toChain,
      msg.sender,
      abi.encodeWithSignature(
        "erc721in(uint32,address,address,address,uint256,bytes)",
        _holograph().getChainType(),
        collection,
        from,
        to,
        tokenId,
        data
      )
    );
  }

  function erc20in(
    uint32 fromChain,
    address token,
    address from,
    address to,
    uint256 amount,
    bytes calldata data
  ) external onlyBridge {
    require(_registry().isHolographedContract(token), "HOLOGRAPH: not holographed");
    require(
      ERC20Holograph(token).holographBridgeIn(fromChain, from, to, amount, data) ==
        ERC20Holograph.holographBridgeIn.selector,
      "HOLOGRAPH: bridge in failed"
    );
  }

  function erc20out(
    uint32 toChain,
    address token,
    address from,
    address to,
    uint256 amount
  ) external payable {
    require(_registry().isHolographedContract(token), "HOLOGRAPH: not holographed");
    ERC20Holograph erc20 = ERC20Holograph(token);
    require(erc20.balanceOf(from) >= amount, "HOLOGRAPH: not enough tokens");
    (bytes4 selector, bytes memory data) = erc20.holographBridgeOut(toChain, msg.sender, from, to, amount);
    require(selector == ERC20Holograph.holographBridgeOut.selector, "HOLOGRAPH: bridge out failed");
    _operator().send{value: msg.value}(
      toChain,
      msg.sender,
      abi.encodeWithSignature(
        "erc20in(uint32,address,address,address,uint256,bytes)",
        _holograph().getChainType(),
        token,
        from,
        to,
        amount,
        data
      )
    );
  }

  function deployIn(bytes calldata data) external onlyBridge {
    (DeploymentConfig memory config, Verification memory signature, address signer) = abi.decode(
      data,
      (DeploymentConfig, Verification, address)
    );
    _factory().deployHolographableContract(config, signature, signer);
  }

  function deployOut(
    uint32 toChain,
    DeploymentConfig calldata config,
    Verification calldata signature,
    address signer
  ) external payable {
    _operator().send{value: msg.value}(
      toChain,
      msg.sender,
      abi.encodeWithSignature("deployIn(bytes)", abi.encode(config, signature, signer))
    );
  }

  function _factory() private view returns (IHolographFactory factory) {
    assembly {
      factory := sload(precomputeslot("eip1967.Holograph.Bridge.factory"))
    }
  }

  function _holograph() private view returns (IHolograph holograph) {
    assembly {
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
    }
  }

  function _interfaces() private view returns (IInterfaces interfaces) {
    assembly {
      interfaces := sload(precomputeslot("eip1967.Holograph.Bridge.interfaces"))
    }
  }

  function _operator() private view returns (IHolographOperator operator) {
    assembly {
      operator := sload(precomputeslot("eip1967.Holograph.Bridge.operator"))
    }
  }

  function _registry() private view returns (IHolographRegistry registry) {
    assembly {
      registry := sload(precomputeslot("eip1967.Holograph.Bridge.registry"))
    }
  }

  function getFactory() external view returns (address factory) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factory')) - 1);
    assembly {
      factory := sload(precomputeslot("eip1967.Holograph.Bridge.factory"))
    }
  }

  function setFactory(address factory) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factory')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.factory"), factory)
    }
  }

  function getHolograph() external view returns (address holograph) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.holograph')) - 1);
    assembly {
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
    }
  }

  function setHolograph(address holograph) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.holograph')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.factory"), holograph)
    }
  }

  function getInterfaces() external view returns (address interfaces) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.interfaces')) - 1);
    assembly {
      interfaces := sload(precomputeslot("eip1967.Holograph.Bridge.interfaces"))
    }
  }

  function setInterfaces(address interfaces) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.interfaces')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.interfaces"), interfaces)
    }
  }

  function getOperator() external view returns (address operator) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.operator')) - 1);
    assembly {
      operator := sload(precomputeslot("eip1967.Holograph.Bridge.operator"))
    }
  }

  function setOperator(address operator) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.operator')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.operator"), operator)
    }
  }

  function getRegistry() external view returns (address registry) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
    assembly {
      registry := sload(precomputeslot("eip1967.Holograph.Bridge.registry"))
    }
  }

  function setRegistry(address registry) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.registry"), registry)
    }
  }
}
