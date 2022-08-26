// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

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
   * @dev Internal nonce used for randomness.
   */
  uint256 private _jobNonce;

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
      switch eq(sload(0x7bef7d8d97f57f9aa64de319c8598b5cdc7c3d2715fc02428415a98281ca6bdc), caller())
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
      sstore(0x5705f5753aa4f617eef2cae1dada3d3355e9387b04d19191f09b545e684ca50d, origin())

      sstore(0x7eefc8e705e14d34b5d1d6c3ea7f4e20cecb5956b182bac952a455d9372b87e2, factory)
      sstore(0x1eee493315beeac80829afd0aaa340f3821cabe68571a2743478e81638a3d94d, holograph)
      sstore(0x23e584d4fb363739321c1e56c9bcdc29517a4c57065f8502226c995fd15b2472, interfaces)
      sstore(0x7bef7d8d97f57f9aa64de319c8598b5cdc7c3d2715fc02428415a98281ca6bdc, operator)
      sstore(0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349, registry)
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

  /* !!! PROVIDING SUPPORT FOR OLD VERSION !!! */
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

  /* !!! PROVIDING SUPPORT FOR OLD VERSION !!! */
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

  /* !!! PROVIDING SUPPORT FOR OLD VERSION !!! */
  function deployIn(bytes calldata data) external onlyBridge {
    (DeploymentConfig memory config, Verification memory signature, address signer) = abi.decode(
      data,
      (DeploymentConfig, Verification, address)
    );
    _factory().deployHolographableContract(config, signature, signer);
  }

  function erc721in(
    uint256 nonce,
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
    _jobNonce++;
    _operator().send{value: msg.value}(
      toChain,
      msg.sender,
      abi.encodeWithSignature(
        "erc721in(uint256,uint32,address,address,address,uint256,bytes)",
        _jobNonce,
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
    uint256 nonce,
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
    _jobNonce++;
    _operator().send{value: msg.value}(
      toChain,
      msg.sender,
      abi.encodeWithSignature(
        "erc20in(uint256,uint32,address,address,address,uint256,bytes)",
        _jobNonce,
        _holograph().getChainType(),
        token,
        from,
        to,
        amount,
        data
      )
    );
  }

  function deployIn(
    uint256 nonce,
    uint32 fromChain,
    bytes calldata data
  ) external onlyBridge {
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
    _jobNonce++;
    _operator().send{value: msg.value}(
      toChain,
      msg.sender,
      abi.encodeWithSignature(
        "deployIn(uint256,uint32,bytes)",
        _jobNonce,
        _holograph().getChainType(),
        abi.encode(config, signature, signer)
      )
    );
  }

  function _factory() private view returns (IHolographFactory factory) {
    assembly {
      factory := sload(0x7eefc8e705e14d34b5d1d6c3ea7f4e20cecb5956b182bac952a455d9372b87e2)
    }
  }

  function _holograph() private view returns (IHolograph holograph) {
    assembly {
      holograph := sload(0x1eee493315beeac80829afd0aaa340f3821cabe68571a2743478e81638a3d94d)
    }
  }

  function _interfaces() private view returns (IInterfaces interfaces) {
    assembly {
      interfaces := sload(0x23e584d4fb363739321c1e56c9bcdc29517a4c57065f8502226c995fd15b2472)
    }
  }

  function _operator() private view returns (IHolographOperator operator) {
    assembly {
      operator := sload(0x7bef7d8d97f57f9aa64de319c8598b5cdc7c3d2715fc02428415a98281ca6bdc)
    }
  }

  function _registry() private view returns (IHolographRegistry registry) {
    assembly {
      registry := sload(0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349)
    }
  }

  function getFactory() external view returns (address factory) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factory')) - 1);
    assembly {
      factory := sload(0x7eefc8e705e14d34b5d1d6c3ea7f4e20cecb5956b182bac952a455d9372b87e2)
    }
  }

  function setFactory(address factory) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.factory')) - 1);
    assembly {
      sstore(0x7eefc8e705e14d34b5d1d6c3ea7f4e20cecb5956b182bac952a455d9372b87e2, factory)
    }
  }

  function getHolograph() external view returns (address holograph) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.holograph')) - 1);
    assembly {
      holograph := sload(0x1eee493315beeac80829afd0aaa340f3821cabe68571a2743478e81638a3d94d)
    }
  }

  function setHolograph(address holograph) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.holograph')) - 1);
    assembly {
      sstore(0x1eee493315beeac80829afd0aaa340f3821cabe68571a2743478e81638a3d94d, holograph)
    }
  }

  function getInterfaces() external view returns (address interfaces) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.interfaces')) - 1);
    assembly {
      interfaces := sload(0x23e584d4fb363739321c1e56c9bcdc29517a4c57065f8502226c995fd15b2472)
    }
  }

  function setInterfaces(address interfaces) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.interfaces')) - 1);
    assembly {
      sstore(0x23e584d4fb363739321c1e56c9bcdc29517a4c57065f8502226c995fd15b2472, interfaces)
    }
  }

  function getOperator() external view returns (address operator) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.operator')) - 1);
    assembly {
      operator := sload(0x7bef7d8d97f57f9aa64de319c8598b5cdc7c3d2715fc02428415a98281ca6bdc)
    }
  }

  function setOperator(address operator) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.operator')) - 1);
    assembly {
      sstore(0x7bef7d8d97f57f9aa64de319c8598b5cdc7c3d2715fc02428415a98281ca6bdc, operator)
    }
  }

  function getRegistry() external view returns (address registry) {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
    assembly {
      registry := sload(0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349)
    }
  }

  function setRegistry(address registry) external onlyAdmin {
    // The slot hash has been precomputed for gas optimizaion
    // bytes32 slot = bytes32(uint256(keccak256('eip1967.Holograph.Bridge.registry')) - 1);
    assembly {
      sstore(0x460c4059d72b144253e5fc4e2aacbae2bcd6362c67862cd58ecbab0e7b10c349, registry)
    }
  }
}
