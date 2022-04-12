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

    function erc721in(uint32 fromChain, address collection, address from, address to, uint256 tokenId, bytes calldata data) external onlyOperator {
        // all approval and validation should be done before this point
        require(IHolographRegistry(_registry()).isHolographedContract(collection), "HOLOGRAPH: not holographed");
        require(ERC721Holograph(collection).holographBridgeIn(fromChain, from, to, tokenId, data) == ERC721Holograph.holographBridgeIn.selector, "HOLOGRAPH: bridge in failed");
    }

    function erc721out(uint32 toChain, address collection, address from, address to, uint256 tokenId) external {
        require(IHolographRegistry(_registry()).isHolographedContract(collection), "HOLOGRAPH: not holographed");
        ERC721Holograph erc721 = ERC721Holograph(collection);
        require(erc721.exists(tokenId), "HOLOGRAPH: token doesn't exist");
        address tokenOwner = erc721.ownerOf(tokenId);
        require(tokenOwner == msg.sender || erc721.getApproved(tokenId) == msg.sender || erc721.isApprovedForAll(tokenOwner, msg.sender), "HOLOGRAPH: not approved/owner");
        (bytes4 selector, bytes memory data) = erc721.holographBridgeOut(toChain, from, to, tokenId);
        require(selector == ERC721Holograph.holographBridgeOut.selector, "HOLOGRAPH: bridge out failed");
        emit TransferErc721(toChain, abi.encode(IHolograph(0x20202020486F6c6f677261706841646472657373).getChainType(), collection, from, to, tokenId, data));
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
