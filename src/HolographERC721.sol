HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";
import "./abstract/Owner.sol";

import "./interface/ERC165.sol";
import "./interface/ERC721Holograph.sol";
import "./interface/ERC721TokenReceiver.sol";
import "./interface/HolographedERC721.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographer.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";
import "./interface/IPA1D.sol";

import "./library/Address.sol";
import "./library/Base64.sol";
import "./library/Booleans.sol";
import "./library/Strings.sol";

/**
 * @title Holograph Bridgeable ERC-721 Collection
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph Bridgeable ERC721 NFTs.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract HolographERC721 is Admin, Owner, ERC721Holograph, Initializable  {

    /**
     * @dev Configuration for events to trigger for source smart contract.
     */
    uint256 private _eventConfig;

    /**
     * @dev Collection name.
     */
    string private _name;

    /**
     * @dev Collection symbol.
     */
    string private _symbol;

    /**
     * @dev Collection royalty base points.
     */
    uint16 private _bps;

    /**
     * @dev Array of all token ids in collection.
     */
    uint256[] private _allTokens;

    /**
     * @dev Map of token id to array index of _ownedTokens.
     */
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev Token id to wallet (owner) address map.
     */
    mapping(uint256 => address) private _tokenOwner;

    /**
     * @dev 1-to-1 map of token id that was assigned an approved operator address.
     */
    mapping(uint256 => address) private _tokenApprovals;

    /**
     * @dev Map of total tokens owner by a specific address.
     */
    mapping(address => uint256) private _ownedTokensCount;

    /**
     * @dev Map of array of token ids owned by a specific address.
     */
    mapping(address => uint256[]) private _ownedTokens;

    /**
     * @notice Map of full operator approval for a particular address.
     * @dev Usually utilised for supporting marketplace proxy wallets.
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Mapping from token id to position in the allTokens array.
     */
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @notice Constructor is empty and not utilised.
     * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
     */
    constructor() Admin(false) Owner(true) {
    }

    /**
     * @notice Gets a base64 encoded contract JSON file.
     * @return string The URI.
     */
    function contractURI() external view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        "{",
                            "\"name\":\"", _name, "\",",
                            "\"description\":\"", _name, "\",",
                            "\"seller_fee_basis_points\":", Strings.uint2str(_bps), ",",
                            "\"fee_recipient\":\"", Strings.toAsciiString(address(this)), "\"",
                        "}"
                    )
                )
            )
        );
    }

    /**
     * @notice Gets the name of the collection.
     * @return string The collection name.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @notice Shows the interfaces the contracts support
     * @dev Must add new 4 byte interface Ids here to acknowledge support
     * @param interfaceId ERC165 style 4 byte interfaceId.
     * @return bool True if supported.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x780e9d63 || // ERC721Enumerable
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x150b7a02 || // ERC721TokenReceiver
            interfaceId == 0xe8a3d485 || // contractURI()
            ERC165(royalties()).supportsInterface(interfaceId) || // check if royalties supports interface
            ERC165(source()).supportsInterface(interfaceId) // check if source supports interface
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Gets the collection's symbol.
     * @return string The symbol.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Get's the URI of the token.
     * @dev Defaults the the Arweave URI
     * @return string The URI.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721: token does not exist");
        return ERC721Metadata(source()).tokenURI(tokenId);
    }

    /**
     * @notice Get list of tokens owned by wallet.
     * @param wallet The wallet address to get tokens for.
     * @return uint256[] Returns an array of token ids owned by wallet.
     */
    function tokensOfOwner(address wallet) external view returns (uint256[] memory) {
        return _ownedTokens[wallet];
    }

    /**
     * @notice Adds a new address to the token's approval list.
     * @dev Requires the sender to be in the approved addresses.
     * @param to The address to approve.
     * @param tokenId The affected token.
     */
    function approve(address to, uint256 tokenId) external payable {
        address tokenOwner = _tokenOwner[tokenId];
        require(to != tokenOwner, "ERC721: cannot approve self");
        require(_isApproved(msg.sender, tokenId), "ERC721: not approved sender");
        if (Booleans.get(_eventConfig, 5)) {
            require(SourceERC721().beforeApprove(tokenOwner, to, tokenId));
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
        if (Booleans.get(_eventConfig, 4)) {
            require(SourceERC721().afterApprove(tokenOwner, to, tokenId));
        }
    }

    /**
     * @notice Burns the token.
     * @dev The sender must be the owner or approved.
     * @param tokenId The token to burn.
     */
    function burn(uint256 tokenId) external {
        require(_isApproved(msg.sender, tokenId), "ERC721: not approved sender");
        address wallet = _tokenOwner[tokenId];
        if (Booleans.get(_eventConfig, 8)) {
            require(SourceERC721().beforeBurn(wallet, tokenId));
        }
        _burn(wallet, tokenId);
        if (Booleans.get(_eventConfig, 7)) {
            require(SourceERC721().afterBurn(wallet, tokenId));
        }
    }

    /**
     * @dev Allows the bridge to bring in a token from another blockchain.
     *  Note: function selector 0x2dd69ea4 is bytes4(keccak256("holographBridgeIn(address,address,uint256,bytes)"))
     */
    function holographBridgeIn(address from, address to, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        require(msg.sender == bridge(),  "ERC721: only bridge can call");
        if (_exists(tokenId)) {
            // we transfer token out of bridge contract
            require(_tokenOwner[tokenId] == bridge(), "ERC721: bridge not token owner");
            _transferFrom(bridge(), to, tokenId);
        } else {
            // we mint the token
            _mint(from, tokenId);
            if (from != to) {
                _transferFrom(from, to, tokenId);
            }
        }
        if (Booleans.get(_eventConfig, 1)) {
            require(SourceERC721().bridgeIn(from, to, tokenId, data));
        }
        return 0x2dd69ea4;
    }

    /**
     * @dev Allows the bridge to take a token out onto another blockchain.
     *  Note: function selector 0x57aeff0a is bytes4(keccak256("holographBridgeOut(address,address,uint256)"))
     */
    function holographBridgeOut(address from, address to, uint256 tokenId) external returns (bytes4, bytes memory data) {
        require(msg.sender == bridge(),  "ERC721: only bridge can call");
        if (from != to) {
            _transferFrom(from, to, tokenId);
        }
        _transferFrom(to, bridge(), tokenId);
        if (Booleans.get(_eventConfig, 2)) {
            return (0x57aeff0a, SourceERC721().bridgeOut(from, to, tokenId));
        } else {
            return (0x57aeff0a, "");
        }
    }

    /**
     * @notice Initializes the collection.
     * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
     */
    function init(bytes memory data) external override returns (bytes4) {
        (
            string memory contractName,
            string memory contractSymbol,
            uint16 contractBps,
            uint256 eventConfig,
            bytes memory initCode
        ) = abi.decode(data, (string, string, uint16, uint256, bytes));
        _name = contractName;
        _symbol = contractSymbol;
        _bps = contractBps;
        _eventConfig = eventConfig;
        try IHolographer(payable(address(this))).getSourceContract() returns (address payable sourceAddress) {
            require(IInitializable(sourceAddress).init(initCode) == IInitializable.init.selector, "initialization failed");
        } catch {
            // we do nothing
        }
//         (bool success, bytes memory returnData) = royalties().delegatecall(
//             abi.encodeWithSignature("init(bytes)", abi.encode(address(this), uint256(contractBps)))
//         );
//         (bytes4 selector) = abi.decode(returnData, (bytes4));
//         require(success && selector == IInitializable.init.selector, "initialization failed");
        return IInitializable.init.selector;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * @param from cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must exist and be owned by `from`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * @param from cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must exist and be owned by `from`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable {
        require(_isApproved(msg.sender, tokenId), "ERC721: not approved sender");
        if (Booleans.get(_eventConfig, 12)) {
            require(SourceERC721().beforeSafeTransfer(from, to, tokenId, data));
        }
        _transferFrom(from, to, tokenId);
        if (Address.isContract(to)) {
            // NEED TO CHECK FOR ERC165 SUPPORT FIRST!!!
            // THEN CHECK FOR TOKEN RECEIVER INTERFACE SUPPORT
            require(
                ERC721TokenReceiver(to).onERC721Received(address(this), from, tokenId, data) == 0x150b7a02,
                "ERC721: onERC721Received failed"
            );
        }
        if (Booleans.get(_eventConfig, 11)) {
            require(SourceERC721().afterSafeTransfer(from, to, tokenId, data));
        }
    }

    /**
     * @notice Adds a new approved operator.
     * @dev Allows platforms to sell/transfer all your NFTs. Used with proxy contracts like OpenSea/Rarible.
     * @param to The address to approve.
     * @param approved Turn on or off approval status.
     */
    function setApprovalForAll(address to, bool approved) external {
        require(to != msg.sender, "ERC721: cannot approve self");
        if (Booleans.get(_eventConfig, 6)) {
            require(SourceERC721().beforeApprovalAll(to, approved));
        }
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
        if (Booleans.get(_eventConfig, 5)) {
            require(SourceERC721().afterApprovalAll(to, approved));
        }
    }

    /**
     * @dev Allows for source smart contract to burn a token.
     *  Note: this is put in place to make sure that custom logic could be implemented for merging, gamification, etc.
     *  Note: token cannot be burned if it's locked by bridge.
     */
    function sourceBurn(uint256 tokenId) external {
        require(msg.sender == source(), "ERC721: only source can burn");
        address wallet = _tokenOwner[tokenId];
        require(wallet != bridge(), "ERC721: token is bridged");
        _burn(wallet, tokenId);
    }

    /**
     * @dev Allows for source smart contract to mint a token.
     */
    function sourceMint(address to, uint224 tokenId) external {
        require(msg.sender == source(), "ERC721: only source can mint");
        // uint32 is reserved for chain id to be used
        // we need to get current chain id, and prepend it to tokenId
        // this will prevent possible tokenId overlap if minting simultaneously on multiple chains is possible
        uint256 token = uint256(bytes32(abi.encodePacked(_chain(), tokenId)));
        _mint(to, token);
    }

    /**
     * @dev Allows source to get the prepend for their tokenIds.
     */
    function sourceGetChainPrepend() external view returns (uint256) {
        require(msg.sender == source(), "ERC721: only source can mint");
        return uint256(bytes32(abi.encodePacked(_chain(), uint224(0))));
    }

    /**
     * @dev Allows for source smart contract to mint a batch of tokens.
     */
    function sourceMintBatch(address to, uint224[] calldata tokenIds) external {
        require(msg.sender == source(), "ERC721: only source can mint");
        uint32 chain = _chain();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(to, uint256(bytes32(abi.encodePacked(chain, tokenIds[i]))));
        }
    }

    /**
     * @dev Allows for source smart contract to mint a batch of tokens.
     */
    function sourceMintBatch(address[] calldata wallets, uint224[] calldata tokenIds) external {
        require(msg.sender == source(), "ERC721: only source can mint");
        uint32 chain = _chain();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mint(wallets[i], uint256(bytes32(abi.encodePacked(chain, tokenIds[i]))));
        }
    }

    /**
     * @dev Allows for source smart contract to mint a batch of tokens.
     */
    function sourceMintBatchIncremental(address to, uint224 startingTokenId, uint256 length) external {
        require(msg.sender == source(), "ERC721: only source can mint");
        uint32 chain = _chain();
        for (uint256 i = 0; i < length; i++) {
            _mint(to, uint256(bytes32(abi.encodePacked(chain, startingTokenId))));
            startingTokenId++;
        }
    }

    /**
     * @dev Allows for source smart contract to transfer a token.
     *  Note: this is put in place to make sure that custom logic could be implemented for merging, gamification, etc.
     *  Note: token cannot be transfered if it's locked by bridge.
     */
    function sourceTransfer(address to, uint256 tokenId) external {
        require(msg.sender == source(), "ERC721: only source can transfer");
        address wallet = _tokenOwner[tokenId];
        require(wallet != bridge(), "ERC721: token is bridged");
        _transferFrom(wallet, to, tokenId);
    }

    /**
     * @notice Transfers `tokenId` token from `msg.sender` to `to`.
     * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * @param to cannot be the zero address.
     * @param tokenId token must be owned by `from`.
     */
    function transfer(address to, uint256 tokenId) external payable {
        transferFrom(msg.sender, to, tokenId, "");
    }

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * @param from  cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must be owned by `from`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable {
        transferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * @param from  cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must be owned by `from`.
     * @param data additional data to pass.
     */
    function transferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable {
        require(_isApproved(msg.sender, tokenId), "ERC721: not approved sender");
        if (Booleans.get(_eventConfig, 14)) {
            require(SourceERC721().beforeTransfer(from, to, tokenId, data));
        }
        _transferFrom(from, to, tokenId);
        if (Booleans.get(_eventConfig, 13)) {
            require(SourceERC721().afterTransfer(from, to, tokenId, data));
        }
    }

    /**
     * @notice Get total number of tokens owned by wallet.
     * @dev Used to see total amount of tokens owned by a specific wallet.
     * @param wallet Address for which to get token balance.
     * @return uint256 Returns an integer, representing total amount of tokens held by address.
     */
    function balanceOf(address wallet) public view returns (uint256) {
        require(!Address.isZero(wallet), "ERC721: zero address");
        return _ownedTokensCount[wallet];
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return !Address.isZero(_tokenOwner[tokenId]);
    }

    /**
     * @notice Gets the approved address for the token.
     * @dev Single operator set for a specific token. Usually used for one-time very specific authorisations.
     * @param tokenId Token id to get approved operator for.
     * @return address Approved address for token.
     */
    function getApproved(uint256 tokenId) external view returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @notice Checks if the address is approved.
     * @dev Includes references to OpenSea and Rarible marketplace proxies.
     * @param wallet Address of the wallet.
     * @param operator Address of the marketplace operator.
     * @return bool True if approved.
     */
    function isApprovedForAll(address wallet, address operator) external view returns (bool) {
        return _operatorApprovals[wallet][operator];
    }

    /**
     * @notice Checks who the owner of a token is.
     * @dev The token must exist.
     * @param tokenId The token to look up.
     * @return address Owner of the token.
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        address tokenOwner = _tokenOwner[tokenId];
        require(!Address.isZero(tokenOwner), "ERC721: token does not exist");
        return tokenOwner;
    }

    /**
     * @notice Get token by index.
     * @dev Used in conjunction with totalSupply function to iterate over all tokens in collection.
     * @param index Index of token in array.
     * @return uint256 Returns the token id of token located at that index.
     */
    function tokenByIndex(uint256 index) external view returns (uint256) {
        require(index < _allTokens.length, "ERC721: index out of bounds");
        return _allTokens[index];
    }

    /**
     * @notice Get token from wallet by index instead of token id.
     * @dev Helpful for wallet token enumeration where token id info is not yet available. Use in conjunction with balanceOf function.
     * @param wallet Specific address for which to get token for.
     * @param index Index of token in array.
     * @return uint256 Returns the token id of token located at that index in specified wallet.
     */
    function tokenOfOwnerByIndex(address wallet, uint256 index) external view returns (uint256) {
        require(index < balanceOf(wallet), "ERC721: index out of bounds");
        return _ownedTokens[wallet][index];
    }

    /**
     * @notice Total amount of tokens in the collection.
     * @dev Ignores burned tokens.
     * @return uint256 Returns the total number of active (not burned) tokens.
     */
    function totalSupply() external view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @notice Empty function that is triggered by external contract on NFT transfer.
     * @dev We have this blank function in place to make sure that external contract sending in NFTs don't error out.
     * @dev Since it's not being used, the _operator variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _from variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _tokenId variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * @return bytes4 Returns the interfaceId of onERC721Received.
     */
    function onERC721Received(address, /*_operator*/ address, /*_from*/ uint256, /*_tokenId*/ bytes calldata /*_data*/) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    /**
     * @dev Add a newly minted token into managed list of tokens.
     * @param to Address of token owner for which to add the token.
     * @param tokenId Id of token to add.
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokensCount[to];
        _ownedTokensCount[to]++;
        _ownedTokens[to].push(tokenId);
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @notice Burns the token.
     * @dev All validation needs to be done before calling this function.
     * @param wallet Address of current token owner.
     * @param tokenId The token to burn.
     */
    function _burn(address wallet, uint256 tokenId) private {
        _clearApproval(tokenId);
        _tokenOwner[tokenId] = address(0);
        emit Transfer(wallet, address(0), tokenId);
        _removeTokenFromOwnerEnumeration(wallet, tokenId);
    }

    /**
     * @notice Deletes a token from the approval list.
     * @dev Removes from count.
     * @param tokenId T.
     */
    function _clearApproval(uint256 tokenId) private {
        delete _tokenApprovals[tokenId];
    }

    /**
     * @notice Mints an NFT.
     * @dev Can to mint the token to the zero address and the token cannot already exist.
     * @param to Address to mint to.
     * @param tokenId The new token.
     */
    function _mint(address to, uint256 tokenId) private {
        require(!Address.isZero(to), "ERC721: minting to burn address");
        require(!_exists(tokenId), "ERC721: token already exists");
        _tokenOwner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        delete _allTokensIndex[tokenId];
        delete _allTokens[lastTokenIndex];
        _allTokens.pop();
    }

    /**
     * @dev Remove a token from managed list of tokens.
     * @param from Address of token owner for which to remove the token.
     * @param tokenId Id of token to remove.
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        _removeTokenFromAllTokensEnumeration(tokenId);
        _ownedTokensCount[from]--;
        uint256 lastTokenIndex = _ownedTokensCount[from];
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if(tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        if(lastTokenIndex == 0) {
            delete _ownedTokens[from];
        } else {
            delete _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from].pop();
        }
    }

    /**
     * @dev Primary internal function that handles the transfer/mint/burn functionality.
     * @param from Address from where token is being transferred. Zero address means it is being minted.
     * @param to Address to whom the token is being transferred. Zero address means it is being burned.
     * @param tokenId Id of token that is being transferred/minted/burned.
     */
    function _transferFrom(address from, address to, uint256 tokenId) private {
        require(_tokenOwner[tokenId] == from, "ERC721: token not owned");
        require(!Address.isZero(to), "ERC721: use burn instead");
        _clearApproval(tokenId);
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _chain() private view returns (uint32) {
        uint32 currentChain = IHolograph(0x20202020486f6c6f677261706841646472657373).getChainType();
        if (currentChain != IHolographer(payable(address(this))).getOriginChain()) {
            return currentChain;
        }
        return uint32(0);
    }

    /**
     * @notice Checks if the token owner exists.
     * @dev If the address is the zero address no owner exists.
     * @param tokenId The affected token.
     * @return bool True if it exists.
     */
    function _exists(uint256 tokenId) private view returns (bool) {
        address tokenOwner = _tokenOwner[tokenId];
        return !Address.isZero(tokenOwner);
    }

    /**
     * @notice Checks if the address is an approved one.
     * @dev Uses inlined checks for different usecases of approval.
     * @param spender Address of the spender.
     * @param tokenId The affected token.
     * @return bool True if approved.
     */
    function _isApproved(address spender, uint256 tokenId) private view returns (bool) {
        require(_exists(tokenId));
        address tokenOwner = _tokenOwner[tokenId];
        return (
            spender == tokenOwner
            || _tokenApprovals[tokenId] == spender
            || _operatorApprovals[tokenOwner][spender]
        );
    }

    /**
     * @dev Get the source smart contract as bridgeable interface.
     */
    function SourceERC721() private view returns (HolographedERC721) {
        return HolographedERC721(source());
    }

    /**
     * @dev Get the bridge contract address.
     */
    function bridge() private view returns (address) {
        return IHolograph(0x20202020486f6c6f677261706841646472657373).getBridge();
    }

    /**
     * @dev Get the bridge contract address.
     */
    function royalties() private view returns (address) {
        return IHolographRegistry(
            IHolograph(
                0x20202020486f6c6f677261706841646472657373
            ).getRegistry()
        ).getContractTypeAddress(0x0000000000000000000000000000000000000000000000000000000050413144);
    }

    /**
     * @dev Get the source smart contract.
     */
    function source() private view returns (address) {
        return IHolographer(payable(address(this))).getSourceContract();
    }

    /**
     * @notice Fallback to the source contract.
     * @dev Any function call that is not covered here, will automatically be sent over to the source contract.
     */
    fallback() external {
        // we check if royalties support the function, send there, otherwise revert to source
        address pa1d = royalties();
        address _target;
        if (IPA1D(pa1d).supportsFunction(msg.sig)) {
            _target = pa1d;
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
            }
        } else {
            _target = source();
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := call(gas(), _target, 0, 0, calldatasize(), 0, 0)
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

}
