HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/ERC721Holograph.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographFactory.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";

import "./struct/DeploymentConfig.sol";
import "./struct/Verification.sol";

/*
 * @dev This smart contract contains the actual core bridging logic.
 */
contract HolographBridge is Admin, Initializable {

    event DeployRequest(uint32 chainId, bytes data);
    event TransferErc721(uint32 toChainId, bytes data);
    event LzEvent(uint16 _dstChainId, bytes _destination, bytes _payload);

    /*
     * @dev Constructor is left empty and only the admin address is set.
     */
    constructor() Admin(false) {}

    modifier onlyOperator {
        // ultimately the goal is to do a sanity check that msg.sender is currently holding an operator license
        _;
    }

    function init(bytes memory data) external override returns (bytes4) {
        (address registry, address factory) = abi.decode(data, (address, address));
        assembly {
            sstore(precomputeslot('eip1967.Holograph.Bridge.registry'), registry)
            sstore(precomputeslot('eip1967.Holograph.Bridge.factory'), factory)
        }
        return IInitializable.init.selector;
    }

    function chainConvert(uint16 lzChainId) internal pure returns (uint32) {
        // local
        if (lzChainId == uint16(65535)) {
            return uint32(4294967295);
        }
        // local2
        if (lzChainId == uint16(65534)) {
            return uint32(4294967294);
        }
        // rinkeby
        if (lzChainId == uint16(10001)) {
            return uint32(4000000001);
        }
        // bsc testnet
        if (lzChainId == uint16(10002)) {
            return uint32(4000000002);
        }
        // fuji
        if (lzChainId == uint16(10006)) {
            return uint32(4000000003);
        }
        // mumbai
        if (lzChainId == uint16(10009)) {
            return uint32(4000000004);
        }
        // arbitrum rinkeby
        if (lzChainId == uint16(10010)) {
            return uint32(4000000006);
        }
        // optimism kovan
        if (lzChainId == uint16(10011)) {
            return uint32(4000000007);
        }
        // fantom testnet
        if (lzChainId == uint16(10012)) {
            return uint32(4000000005);
        }
        // eth
        if (lzChainId == uint16(1)) {
            return uint32(1);
        }
        // bsc
        if (lzChainId == uint16(2)) {
            return uint32(2);
        }
        // avalanche
        if (lzChainId == uint16(6)) {
            return uint32(3);
        }
        // polygon
        if (lzChainId == uint16(9)) {
            return uint32(4);
        }
        // arbitrum
        if (lzChainId == uint16(10)) {
            return uint32(6);
        }
        // optimism
        if (lzChainId == uint16(11)) {
            return uint32(7);
        }
        // fantom
        if (lzChainId == uint16(12)) {
            return uint32(5);
        }
        return uint32(0);
    }

    function chainConvert(uint32 holographChainId) internal pure returns (uint16) {
        // local
        if (holographChainId == uint32(4294967295)) {
            return uint16(65535);
        }
        // local2
        if (holographChainId == uint32(4294967294)) {
            return uint16(65534);
        }
        // rinkeby
        if (holographChainId == uint32(4000000001)) {
            return uint16(10001);
        }
        // bsc testnet
        if (holographChainId == uint32(4000000002)) {
            return uint16(10002);
        }
        // fuji
        if (holographChainId == uint32(4000000003)) {
            return uint16(10006);
        }
        // mumbai
        if (holographChainId == uint32(4000000004)) {
            return uint16(10009);
        }
        // arbitrum rinkeby
        if (holographChainId == uint32(4000000006)) {
            return uint16(10010);
        }
        // optimism kovan
        if (holographChainId == uint32(4000000007)) {
            return uint16(10011);
        }
        // fantom testnet
        if (holographChainId == uint32(4000000005)) {
            return uint16(10012);
        }
        // eth
        if (holographChainId == uint32(1)) {
            return uint16(1);
        }
        // bsc
        if (holographChainId == uint32(2)) {
            return uint16(2);
        }
        // avalanche
        if (holographChainId == uint32(3)) {
            return uint16(6);
        }
        // polygon
        if (holographChainId == uint32(4)) {
            return uint16(9);
        }
        // arbitrum
        if (holographChainId == uint32(6)) {
            return uint16(10);
        }
        // optimism
        if (holographChainId == uint32(7)) {
            return uint16(11);
        }
        // fantom
        if (holographChainId == uint32(5)) {
            return uint16(12);
        }
        return uint16(0);
    }

    // we create a custom version of this function and skip all the backend logic
    function lzReceive(uint16/* _srcChainId*/, bytes calldata/* _srcAddress*/, uint64/* _nonce*/, bytes calldata _payload) public payable onlyOperator {
        // we really don't care about anything at the moment and just send directly through
        (bool success,/* bytes memory response*/) = address(this).call(_payload);
        require(success, "failed executing payload");
    }

    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable/* _refundAddress*/, address/* _zroPaymentAddress*/, bytes calldata/* _adapterParams*/) external payable onlyOperator {
        // we really don't care about anything and just emit an event that we can leverage for multichain replication
        emit LzEvent(_dstChainId, _destination, _payload);
    }

    function erc721in(uint32 fromChain, address collection, address from, address to, uint256 tokenId, bytes calldata data) external onlyOperator {
        // all approval and validation should be done before this point
        require(IHolographRegistry(_registry()).isHolographedContract(collection), "HOLOGRAPH: not holographed");
        require(ERC721Holograph(collection).holographBridgeIn(fromChain, from, to, tokenId, data) == ERC721Holograph.holographBridgeIn.selector, "HOLOGRAPH: bridge in failed");
    }

    function erc721out(uint32 toChain, address collection, address from, address to, uint256 tokenId) external payable {
        require(IHolographRegistry(_registry()).isHolographedContract(collection), "HOLOGRAPH: not holographed");
        ERC721Holograph erc721 = ERC721Holograph(collection);
        require(erc721.exists(tokenId), "HOLOGRAPH: token doesn't exist");
        address tokenOwner = erc721.ownerOf(tokenId);
        require(tokenOwner == msg.sender || erc721.getApproved(tokenId) == msg.sender || erc721.isApprovedForAll(tokenOwner, msg.sender), "HOLOGRAPH: not approved/owner");
        (bytes4 selector, bytes memory data) = erc721.holographBridgeOut(toChain, from, to, tokenId);
        require(selector == ERC721Holograph.holographBridgeOut.selector, "HOLOGRAPH: bridge out failed");
        emit TransferErc721(toChain, abi.encode(IHolograph(0x20202020486F6c6f677261706841646472657373).getChainType(), collection, from, to, tokenId, data));
        HolographBridge(payable(address(this))).send{value:msg.value}(
            chainConvert(toChain),
            abi.encodePacked (address(this)),
            abi.encodeWithSignature(
                "erc721in(uint32,address,address,address,uint256,bytes)",
                IHolograph(0x20202020486F6c6f677261706841646472657373).getChainType(),
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

    function deployIn(bytes calldata data) external {
        (DeploymentConfig memory config, Verification memory signature, address signer) = abi.decode(data, (DeploymentConfig, Verification, address));
        IHolographFactory(_factory()).deployHolographableContract(config, signature, signer);
    }

    function deployOut(uint32 toChain, DeploymentConfig calldata config, Verification calldata signature, address signer) external {
        emit DeployRequest(toChain, abi.encode(config, signature, signer));
    }

    function _factory() internal view returns (address factory) {
        assembly {
            factory := sload(precomputeslot('eip1967.Holograph.Bridge.factory'))
        }
    }

    function _registry() internal view returns (address registry) {
        assembly {
            registry := sload(precomputeslot('eip1967.Holograph.Bridge.registry'))
        }
    }

}
