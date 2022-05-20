/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/ERC20Holograph.sol";
import "./interface/ERC721Holograph.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographFactory.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";

import "./library/ChainId.sol";

import "./struct/DeploymentConfig.sol";
import "./struct/Verification.sol";

/*
 * @dev This smart contract contains the actual core bridging logic.
 */
contract HolographBridge is Admin, Initializable {
  event DeployRequest(uint32 toChainId, bytes data);
  event TransferErc721(uint32 toChainId, bytes data);
  event TransferErc20(uint32 toChainId, bytes data);
  event LzEvent(uint16 _dstChainId, bytes _destination, bytes _payload);

  /*
   * @dev Constructor is left empty and only the admin address is set.
   */
  constructor() Admin(false) {}

  modifier onlyOperator() {
    // ultimately the goal is to do a sanity check that msg.sender is currently holding an operator license
    _;
  }

  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address holograph, address registry, address factory) = abi.decode(data, (address, address, address));
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.holograph"), holograph)
      sstore(precomputeslot("eip1967.Holograph.Bridge.registry"), registry)
      sstore(precomputeslot("eip1967.Holograph.Bridge.factory"), factory)
    }
    _setInitialized();
    return IInitializable.init.selector;
  }

  // we create a custom version of this function and skip all the backend logic
  function lzReceive(
    uint16, /* _srcChainId*/
    bytes calldata, /* _srcAddress*/
    uint64, /* _nonce*/
    bytes calldata _payload
  ) public payable onlyOperator {
    // we really don't care about anything at the moment and just send directly through
    (
      bool success, /* bytes memory response*/

    ) = address(this).call(_payload);
    require(success, "failed executing payload");
  }

  function send(
    uint16 _dstChainId,
    bytes calldata _destination,
    bytes calldata _payload,
    address payable, /* _refundAddress*/
    address, /* _zroPaymentAddress*/
    bytes calldata /* _adapterParams*/
  ) external payable onlyOperator {
    // we really don't care about anything and just emit an event that we can leverage for multichain replication
    emit LzEvent(_dstChainId, _destination, _payload);
  }

  function erc721in(
    uint32 fromChain,
    address collection,
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external onlyOperator {
    // all approval and validation should be done before this point
    require(IHolographRegistry(_registry()).isHolographedContract(collection), "HOLOGRAPH: not holographed");
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
    require(IHolographRegistry(_registry()).isHolographedContract(collection), "HOLOGRAPH: not holographed");
    ERC721Holograph erc721 = ERC721Holograph(collection);
    require(erc721.exists(tokenId), "HOLOGRAPH: token doesn't exist");
    address tokenOwner = erc721.ownerOf(tokenId);
    require(
      tokenOwner == msg.sender ||
        erc721.getApproved(tokenId) == msg.sender ||
        erc721.isApprovedForAll(tokenOwner, msg.sender),
      "HOLOGRAPH: not approved/owner"
    );
    (bytes4 selector, bytes memory data) = erc721.holographBridgeOut(toChain, from, to, tokenId);
    require(selector == ERC721Holograph.holographBridgeOut.selector, "HOLOGRAPH: bridge out failed");
    emit TransferErc721(
      toChain,
      abi.encode(IHolograph(_holograph()).getChainType(), collection, from, to, tokenId, data)
    );
    HolographBridge(payable(address(this))).send{value: msg.value}(
      ChainId.hlg2lz(toChain),
      abi.encodePacked(address(this)),
      abi.encodeWithSignature(
        "erc721in(uint32,address,address,address,uint256,bytes)",
        IHolograph(_holograph()).getChainType(),
        collection,
        from,
        to,
        tokenId,
        data
      ),
      payable(msg.sender),
      address(this),
      bytes("")
    );
  }

  function erc20in(
    uint32 fromChain,
    address token,
    address from,
    address to,
    uint256 amount,
    bytes calldata data
  ) external onlyOperator {
    // all approval and validation should be done before this point
    require(IHolographRegistry(_registry()).isHolographedContract(token), "HOLOGRAPH: not holographed");
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
    require(IHolographRegistry(_registry()).isHolographedContract(token), "HOLOGRAPH: not holographed");
    ERC20Holograph erc20 = ERC20Holograph(token);
    require(erc20.balanceOf(from) >= amount, "HOLOGRAPH: not enough tokens");
    (bytes4 selector, bytes memory data) = erc20.holographBridgeOut(toChain, msg.sender, from, to, amount);
    require(selector == ERC20Holograph.holographBridgeOut.selector, "HOLOGRAPH: bridge out failed");
    emit TransferErc20(toChain, abi.encode(IHolograph(_holograph()).getChainType(), token, from, to, amount, data));
    HolographBridge(payable(address(this))).send{value: msg.value}(
      ChainId.hlg2lz(toChain),
      abi.encodePacked(address(this)),
      abi.encodeWithSignature(
        "erc20in(uint32,address,address,address,uint256,bytes)",
        IHolograph(_holograph()).getChainType(),
        token,
        from,
        to,
        amount,
        data
      ),
      payable(msg.sender),
      address(this),
      bytes("")
    );
  }

  function deployIn(bytes calldata data) external {
    (DeploymentConfig memory config, Verification memory signature, address signer) = abi.decode(
      data,
      (DeploymentConfig, Verification, address)
    );
    IHolographFactory(_factory()).deployHolographableContract(config, signature, signer);
  }

  function deployOut(
    uint32 toChain,
    DeploymentConfig calldata config,
    Verification calldata signature,
    address signer
  ) external {
    emit DeployRequest(toChain, abi.encode(config, signature, signer));
  }

  function _holograph() internal view returns (address holograph) {
    assembly {
      holograph := sload(precomputeslot("eip1967.Holograph.Bridge.holograph"))
    }
  }

  function _factory() internal view returns (address factory) {
    assembly {
      factory := sload(precomputeslot("eip1967.Holograph.Bridge.factory"))
    }
  }

  function _registry() internal view returns (address registry) {
    assembly {
      registry := sload(precomputeslot("eip1967.Holograph.Bridge.registry"))
    }
  }
}
