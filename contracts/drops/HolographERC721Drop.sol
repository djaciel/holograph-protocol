// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import {NonReentrant} from "../abstract/NonReentrant.sol";
import {Owner} from "./abstract/Owner.sol";

import {Initializable} from "./abstract/Initializable.sol";
import {ERC165} from "./abstract/ERC165.sol";
import {AccessControl} from "./abstract/AccessControl.sol";

import "../interface/HolographInterface.sol";
import "../interface/HolographInterfacesInterface.sol";
import "../interface/HolographRegistryInterface.sol";
import "../interface/HolographRoyaltiesInterface.sol";
import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";
import {IOperatorFilterRegistry} from "./interfaces/IOperatorFilterRegistry.sol";
import {IHolographERC721Drop} from "./interfaces/IHolographERC721Drop.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";
import {IAccessControl} from "./interfaces/IAccessControl.sol";
import {IERC721Upgradeable} from "./interfaces/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "./interfaces/IERC721ReceiverUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "./interfaces/IERC721MetadataUpgradeable.sol";
import {IERC165Upgradeable} from "./interfaces/IERC165Upgradeable.sol";
import {IERC721AUpgradeable} from "./interfaces/IERC721AUpgradeable.sol";

import {DropInitializer} from "../struct/DropInitializer.sol";

import {Strings} from "./library/Strings.sol";
import {MerkleProof} from "./library/MerkleProof.sol";
import {Address} from "./library/Address.sol";
import {AddressUpgradeable} from "./library/AddressUpgradeable.sol";

abstract contract ERC721AUpgradeable is Initializable, ERC165, IERC721AUpgradeable {
  using AddressUpgradeable for address;
  using Strings for uint256;

  // The tokenId of the next token to be minted.
  uint256 internal _currentIndex;

  // The number of tokens burned.
  uint256 internal _burnCounter;

  // Token name
  string internal _name;

  // Token symbol
  string internal _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) internal _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializing {
    _name = name_;
    _symbol = symbol_;
    _currentIndex = _startTokenId();
  }

  /**
   * To change the starting tokenId, please override this function.
   */
  function _startTokenId() internal view virtual returns (uint256) {
    return 0;
  }

  /**
   * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
   */
  function totalSupply() public view override returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than _currentIndex - _startTokenId() times
    unchecked {
      return _currentIndex - _burnCounter - _startTokenId();
    }
  }

  /**
   * Returns the total amount of tokens minted in the contract.
   */
  function _totalMinted() internal view returns (uint256) {
    // Counter underflow is impossible as _currentIndex does not decrement,
    // and it is initialized to _startTokenId()
    unchecked {
      return _currentIndex - _startTokenId();
    }
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Upgradeable).interfaceId ||
      interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();
    return uint256(_addressData[owner].balance);
  }

  /**
   * Returns the number of tokens minted by `owner`.
   */
  function _numberMinted(address owner) internal view returns (uint256) {
    return uint256(_addressData[owner].numberMinted);
  }

  /**
   * Returns the number of tokens burned by or on behalf of `owner`.
   */
  function _numberBurned(address owner) internal view returns (uint256) {
    return uint256(_addressData[owner].numberBurned);
  }

  /**
   * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
   */
  function _getAux(address owner) internal view returns (uint64) {
    return _addressData[owner].aux;
  }

  /**
   * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
   * If there are multiple variables, please pack them into a uint64.
   */
  function _setAux(address owner, uint64 aux) internal {
    _addressData[owner].aux = aux;
  }

  /**
   * Gas spent here starts off proportional to the maximum mint batch size.
   * It gradually moves to O(1) as tokens get transferred around in the collection over time.
   */
  function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
    uint256 curr = tokenId;

    unchecked {
      if (_startTokenId() <= curr && curr < _currentIndex) {
        TokenOwnership memory ownership = _ownerships[curr];
        if (!ownership.burned) {
          if (ownership.addr != address(0)) {
            return ownership;
          }
          // Invariant:
          // There will always be an ownership that has an address and is not burned
          // before an ownership that does not have an address and is not burned.
          // Hence, curr will not underflow.
          while (true) {
            curr--;
            ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
              return ownership;
            }
          }
        }
      }
    }
    revert OwnerQueryForNonexistentToken();
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return _ownershipOf(tokenId).addr;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721AUpgradeable.ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
      revert ApprovalCallerNotOwnerNorApproved();
    }

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (operator == msg.sender) revert ApproveToCaller();

    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    _transfer(from, to, tokenId);
    if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
      revert TransferToNonERC721ReceiverImplementer();
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
  }

  /**
   * @dev Equivalent to `_safeMint(to, quantity, '')`.
   */
  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Safely mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement
   *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = _currentIndex;
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
    // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
    unchecked {
      _addressData[to].balance += uint64(quantity);
      _addressData[to].numberMinted += uint64(quantity);

      _ownerships[startTokenId].addr = to;
      _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

      uint256 updatedIndex = startTokenId;
      uint256 end = updatedIndex + quantity;

      if (to.isContract()) {
        do {
          emit Transfer(address(0), to, updatedIndex);
          if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
          }
        } while (updatedIndex != end);
        // Reentrancy protection
        if (_currentIndex != startTokenId) revert();
      } else {
        do {
          emit Transfer(address(0), to, updatedIndex++);
        } while (updatedIndex != end);
      }
      _currentIndex = updatedIndex;
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 quantity) internal {
    uint256 startTokenId = _currentIndex;
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
    // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
    unchecked {
      _addressData[to].balance += uint64(quantity);
      _addressData[to].numberMinted += uint64(quantity);

      _ownerships[startTokenId].addr = to;
      _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

      uint256 updatedIndex = startTokenId;
      uint256 end = updatedIndex + quantity;

      do {
        emit Transfer(address(0), to, updatedIndex++);
      } while (updatedIndex != end);

      _currentIndex = updatedIndex;
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

    if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

    bool isApprovedOrOwner = (msg.sender == from ||
      isApprovedForAll(from, msg.sender) ||
      getApproved(tokenId) == msg.sender);

    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
    unchecked {
      _addressData[from].balance -= 1;
      _addressData[to].balance += 1;

      TokenOwnership storage currSlot = _ownerships[tokenId];
      currSlot.addr = to;
      currSlot.startTimestamp = uint64(block.timestamp);

      // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      TokenOwnership storage nextSlot = _ownerships[nextTokenId];
      if (nextSlot.addr == address(0)) {
        // This will suffice for checking _exists(nextTokenId),
        // as a burned slot cannot contain the zero address.
        if (nextTokenId != _currentIndex) {
          nextSlot.addr = from;
          nextSlot.startTimestamp = prevOwnership.startTimestamp;
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Equivalent to `_burn(tokenId, false)`.
   */
  function _burn(uint256 tokenId) internal virtual {
    _burn(tokenId, false);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
    TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

    address from = prevOwnership.addr;

    if (approvalCheck) {
      bool isApprovedOrOwner = (msg.sender == from ||
        isApprovedForAll(from, msg.sender) ||
        getApproved(tokenId) == msg.sender);

      if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    }

    _beforeTokenTransfers(from, address(0), tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
    unchecked {
      AddressData storage addressData = _addressData[from];
      addressData.balance -= 1;
      addressData.numberBurned += 1;

      // Keep track of who burned the token, and the timestamp of burning.
      TokenOwnership storage currSlot = _ownerships[tokenId];
      currSlot.addr = from;
      currSlot.startTimestamp = uint64(block.timestamp);
      currSlot.burned = true;

      // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      TokenOwnership storage nextSlot = _ownerships[nextTokenId];
      if (nextSlot.addr == address(0)) {
        // This will suffice for checking _exists(nextTokenId),
        // as a burned slot cannot contain the zero address.
        if (nextTokenId != _currentIndex) {
          nextSlot.addr = from;
          nextSlot.startTimestamp = prevOwnership.startTimestamp;
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    _afterTokenTransfers(from, address(0), tokenId, 1);

    // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    unchecked {
      _burnCounter++;
    }
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721ReceiverUpgradeable(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   * And also called before burning one token.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   * And also called after one token has been burned.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
   * transferred to `to`.
   * - When `from` is zero, `tokenId` has been minted for `to`.
   * - When `to` is zero, `tokenId` has been burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

/**
 * @notice HOLOGRAPH NFT contract for Drops and Editions
 *
 * @dev For drops: assumes 1. linear mint order, 2. max number of mints needs to be less than max_uint64
 *
 */
contract HolographERC721Drop is
  Initializable,
  Owner,
  ERC721AUpgradeable,
  NonReentrant,
  AccessControl,
  IHolographERC721Drop
{
  /// @dev This is the max mint batch size for the optimized ERC721A mint contract
  uint256 constant MAX_MINT_BATCH_SIZE = 8;

  /// @dev Gas limit to send funds
  uint256 constant FUNDS_SEND_GAS_LIMIT = 210_000;

  /// @notice Configuration for NFT minting contract storage
  IHolographERC721Drop.Configuration public config;

  /// @notice Sales configuration
  IHolographERC721Drop.SalesConfiguration public salesConfig;

  /// @dev Mapping for presale mint counts by address to allow public mint limit
  mapping(address => uint256) public presaleMintsByAddress;

  /// @notice Access control roles
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");
  bytes32 public constant SALES_MANAGER_ROLE = keccak256("SALES_MANAGER");

  /// @dev HOLOGRAPH transfer helper address for auto-approval
  address public holographERC721TransferHelper;

  address public marketFilterAddress;

  IOperatorFilterRegistry public operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  /// @notice Only allow for users with admin access
  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
      revert Access_OnlyAdmin();
    }

    _;
  }

  /// @notice Only a given role has access or admin
  /// @param role role to check for alongside the admin role
  modifier onlyRoleOrAdmin(bytes32 role) {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(role, msg.sender)) {
      revert Access_MissingRoleOrAdmin(role);
    }

    _;
  }

  /// @notice Allows user to mint tokens at a quantity
  modifier canMintTokens(uint256 quantity) {
    if (quantity + _totalMinted() > config.editionSize) {
      revert Mint_SoldOut();
    }

    _;
  }

  function _presaleActive() internal view returns (bool) {
    return salesConfig.presaleStart <= block.timestamp && salesConfig.presaleEnd > block.timestamp;
  }

  function _publicSaleActive() internal view returns (bool) {
    return salesConfig.publicSaleStart <= block.timestamp && salesConfig.publicSaleEnd > block.timestamp;
  }

  /// @notice Presale active
  modifier onlyPresaleActive() {
    if (!_presaleActive()) {
      revert Presale_Inactive();
    }

    _;
  }

  /// @notice Public sale active
  modifier onlyPublicSaleActive() {
    if (!_publicSaleActive()) {
      revert Sale_Inactive();
    }

    _;
  }

  constructor() {}

  /**
   * @dev Receives and executes a batch of function calls on this contract.
   */
  function multicall(bytes[] memory data) public returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
  }

  /// @dev Initialize a new drop contract
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");

    (DropInitializer memory initializer, bool skipInit) = abi.decode(initPayload, (DropInitializer, bool));
    holographERC721TransferHelper = initializer.holographERC721TransferHelper;
    marketFilterAddress = initializer.marketFilterAddress;

    // Setup ERC721A
    // Call to ERC721AUpgradeable init has been replaced with the following
    // __ERC721A_init(initializer.contractName, initializer.contractSymbol);
    _name = initializer.contractName;
    _symbol = initializer.contractSymbol;
    _currentIndex = _startTokenId();

    // Setup the owner role
    _setupRole(DEFAULT_ADMIN_ROLE, initializer.initialOwner);
    // Set ownership to original sender of contract call
    address newOwner = initializer.initialOwner;
    assembly {
      sstore(_ownerSlot, newOwner)
    }

    if (initializer.setupCalls.length > 0) {
      // Setup temporary role
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      // Execute setupCalls
      multicall(initializer.setupCalls);
      // Remove temporary role
      _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    setStatus(1);

    // Setup Holograph Royalties
    if (!skipInit) {
      _royalties().delegatecall(
        abi.encodeWithSelector(
          HolographRoyaltiesInterface.initHolographRoyalties.selector,
          abi.encode(uint256(config.royaltyBPS), uint256(0))
        )
      );
    }

    // Setup config variables
    config.editionSize = initializer.editionSize;
    config.metadataRenderer = IMetadataRenderer(initializer.metadataRenderer);

    // TODO: Need to make sure to initialize the metadata renderer
    IMetadataRenderer(initializer.metadataRenderer).initializeWithData(initializer.metadataRendererInit);

    // Holograph initialization
    _setInitialized();
    return Initializable.init.selector;
  }

  /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
  function _lastMintedTokenId() internal view returns (uint256) {
    return _currentIndex - 1;
  }

  /// @notice Start token ID for minting (1-100 vs 0-99)
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @dev Getter for admin role associated with the contract to handle metadata
  /// @return boolean if address is admin
  function isAdmin(address user) external view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, user);
  }

  //        ,-.
  //        `-'
  //        /|\
  //         |             ,----------.
  //        / \            |ERC721Drop|
  //      Caller           `----+-----'
  //        |       burn()      |
  //        | ------------------>
  //        |                   |
  //        |                   |----.
  //        |                   |    | burn token
  //        |                   |<---'
  //      Caller           ,----+-----.
  //        ,-.            |ERC721Drop|
  //        `-'            `----------'
  //        /|\
  //         |
  //        / \
  /// @param tokenId Token ID to burn
  /// @notice User burn function for token id
  function burn(uint256 tokenId) public {
    _burn(tokenId, true);
  }

  /// @notice Sale details
  /// @return IHolographERC721Drop.SaleDetails sale information details
  function saleDetails() external view returns (IHolographERC721Drop.SaleDetails memory) {
    return
      IHolographERC721Drop.SaleDetails({
        publicSaleActive: _publicSaleActive(),
        presaleActive: _presaleActive(),
        publicSalePrice: salesConfig.publicSalePrice,
        publicSaleStart: salesConfig.publicSaleStart,
        publicSaleEnd: salesConfig.publicSaleEnd,
        presaleStart: salesConfig.presaleStart,
        presaleEnd: salesConfig.presaleEnd,
        presaleMerkleRoot: salesConfig.presaleMerkleRoot,
        totalMinted: _totalMinted(),
        maxSupply: config.editionSize,
        maxSalePurchasePerAddress: salesConfig.maxSalePurchasePerAddress
      });
  }

  /// @dev Number of NFTs the user has minted per address
  /// @param minter to get counts for
  function mintedPerAddress(address minter)
    external
    view
    override
    returns (IHolographERC721Drop.AddressMintDetails memory)
  {
    return
      IHolographERC721Drop.AddressMintDetails({
        presaleMints: presaleMintsByAddress[minter],
        publicMints: _numberMinted(minter) - presaleMintsByAddress[minter],
        totalMints: _numberMinted(minter)
      });
  }

  function owner() external view override(Owner, IHolographERC721Drop) returns (address) {
    return getOwner();
  }

  /// @dev Setup auto-approval for marketplace access to sell NFT
  ///      Still requires approval for module
  /// @param nftOwner owner of the nft
  /// @param operator operator wishing to transfer/burn/etc the NFTs
  function isApprovedForAll(address nftOwner, address operator)
    public
    view
    override(ERC721AUpgradeable)
    returns (bool)
  {
    if (operator == holographERC721TransferHelper) {
      return true;
    }
    return super.isApprovedForAll(nftOwner, operator);
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***     PUBLIC MINTING FUNCTIONS       ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                       ,----------.
  //                       / \                      |ERC721Drop|
  //                     Caller                     `----+-----'
  //                       |          purchase()         |
  //                       | ---------------------------->
  //                       |                             |
  //                       |                             |
  //          ___________________________________________________________
  //          ! ALT  /  drop has no tokens left for caller to mint?      !
  //          !_____/      |                             |               !
  //          !            |    revert Mint_SoldOut()    |               !
  //          !            | <----------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                             |
  //                       |                             |
  //          ___________________________________________________________
  //          ! ALT  /  public sale isn't active?        |               !
  //          !_____/      |                             |               !
  //          !            |    revert Sale_Inactive()   |               !
  //          !            | <----------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                             |
  //                       |                             |
  //          ___________________________________________________________
  //          ! ALT  /  inadequate funds sent?           |               !
  //          !_____/      |                             |               !
  //          !            | revert Purchase_WrongPrice()|               !
  //          !            | <----------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                             |
  //                       |                             |----.
  //                       |                             |    | mint tokens
  //                       |                             |<---'
  //                       |                             |
  //                       |                             |----.
  //                       |                             |    | emit IHolographERC721Drop.Sale()
  //                       |                             |<---'
  //                       |                             |
  //                       | return first minted token ID|
  //                       | <----------------------------
  //                     Caller                     ,----+-----.
  //                       ,-.                      |ERC721Drop|
  //                       `-'                      `----------'
  //                       /|\
  //                        |
  //                       / \
  /**
      @dev This allows the user to purchase/mint a edition
           at the given price in the contract.
     */
  function purchase(uint256 quantity)
    external
    payable
    nonReentrant
    canMintTokens(quantity)
    onlyPublicSaleActive
    returns (uint256)
  {
    uint256 salePrice = salesConfig.publicSalePrice;

    if (msg.value != salePrice * quantity) {
      revert Purchase_WrongPrice(salePrice * quantity);
    }

    // If max purchase per address == 0 there is no limit.
    // Any other number, the per address mint limit is that.
    if (
      salesConfig.maxSalePurchasePerAddress != 0 &&
      _numberMinted(msg.sender) + quantity - presaleMintsByAddress[msg.sender] > salesConfig.maxSalePurchasePerAddress
    ) {
      revert Purchase_TooManyForAddress();
    }

    _mintNFTs(msg.sender, quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IHolographERC721Drop.Sale({
      to: msg.sender,
      quantity: quantity,
      pricePerToken: salePrice,
      firstPurchasedTokenId: firstMintedTokenId
    });
    return firstMintedTokenId;
  }

  /// @notice Function to mint NFTs
  /// @dev (important: Does not enforce max supply limit, enforce that limit earlier)
  /// @dev This batches in size of 8 as per recommended by ERC721A creators
  /// @param to address to mint NFTs to
  /// @param quantity number of NFTs to mint
  function _mintNFTs(address to, uint256 quantity) internal {
    do {
      uint256 toMint = quantity > MAX_MINT_BATCH_SIZE ? MAX_MINT_BATCH_SIZE : quantity;
      _mint({to: to, quantity: toMint});
      quantity -= toMint;
    } while (quantity > 0);
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |         purchasePresale()         |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  drop has no tokens left for caller to mint?            !
  //          !_____/      |                                   |               !
  //          !            |       revert Mint_SoldOut()       |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  presale sale isn't active?             |               !
  //          !_____/      |                                   |               !
  //          !            |     revert Presale_Inactive()     |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  merkle proof unapproved for caller?    |               !
  //          !_____/      |                                   |               !
  //          !            | revert Presale_MerkleNotApproved()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  inadequate funds sent?                 |               !
  //          !_____/      |                                   |               !
  //          !            |    revert Purchase_WrongPrice()   |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | mint tokens
  //                       |                                   |<---'
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | emit IHolographERC721Drop.Sale()
  //                       |                                   |<---'
  //                       |                                   |
  //                       |    return first minted token ID   |
  //                       | <----------------------------------
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @notice Merkle-tree based presale purchase function
  /// @param quantity quantity to purchase
  /// @param maxQuantity max quantity that can be purchased via merkle proof #
  /// @param pricePerToken price that each token is purchased at
  /// @param merkleProof proof for presale mint
  function purchasePresale(
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  ) external payable nonReentrant canMintTokens(quantity) onlyPresaleActive returns (uint256) {
    if (
      !MerkleProof.verify(
        merkleProof,
        salesConfig.presaleMerkleRoot,
        keccak256(
          // address, uint256, uint256
          abi.encode(msg.sender, maxQuantity, pricePerToken)
        )
      )
    ) {
      revert Presale_MerkleNotApproved();
    }

    if (msg.value != pricePerToken * quantity) {
      revert Purchase_WrongPrice(pricePerToken * quantity);
    }

    presaleMintsByAddress[msg.sender] += quantity;
    if (presaleMintsByAddress[msg.sender] > maxQuantity) {
      revert Presale_TooManyForAddress();
    }

    _mintNFTs(msg.sender, quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IHolographERC721Drop.Sale({
      to: msg.sender,
      quantity: quantity,
      pricePerToken: pricePerToken,
      firstPurchasedTokenId: firstMintedTokenId
    });

    return firstMintedTokenId;
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***     ADMIN OPERATOR FILTERING       ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /// @notice Proxy to update market filter settings in the main registry contracts
  /// @notice Requires admin permissions
  /// @param args Calldata args to pass to the registry
  function updateMarketFilterSettings(bytes calldata args) external onlyAdmin returns (bytes memory) {
    (bool success, bytes memory ret) = address(operatorFilterRegistry).call(args);
    if (!success) {
      revert RemoteOperatorFilterRegistryCallFailed();
    }
    return ret;
  }

  /// @notice Manage subscription for marketplace filtering based off royalty payouts.
  /// @param enable Enable filtering to non-royalty payout marketplaces
  function manageMarketFilterSubscription(bool enable) external onlyAdmin {
    address self = address(this);
    if (marketFilterAddress == address(0)) {
      revert MarketFilterAddressNotSupportedForChain();
    }
    if (!operatorFilterRegistry.isRegistered(self) && enable) {
      operatorFilterRegistry.registerAndSubscribe(self, marketFilterAddress);
    } else if (enable) {
      operatorFilterRegistry.subscribe(self, marketFilterAddress);
    } else {
      operatorFilterRegistry.unsubscribe(self, false);
      operatorFilterRegistry.unregister(self);
    }
  }

  /// @notice Hook to filter operators (no-op if no filters are registered)
  /// @dev Part of ERC721A token hooks
  /// @param from Transfer from user
  /// @param to Transfer to user
  /// @param startTokenId Token ID to start with
  /// @param quantity Quantity of token being transferred
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override {
    if (
      from != address(0) && // skip on mints
      from != msg.sender // skip on transfers from sender
    ) {
      if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
        revert OperatorNotAllowed(msg.sender);
      }
    }
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***     ADMIN MINTING FUNCTIONS        ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |            adminMint()            |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  caller is not admin or minter role?    |               !
  //          !_____/      |                                   |               !
  //          !            | revert Access_MissingRoleOrAdmin()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  drop has no tokens left for caller to mint?            !
  //          !_____/      |                                   |               !
  //          !            |       revert Mint_SoldOut()       |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | mint tokens
  //                       |                                   |<---'
  //                       |                                   |
  //                       |    return last minted token ID    |
  //                       | <----------------------------------
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @notice Admin mint tokens to a recipient for free
  /// @param recipient recipient to mint to
  /// @param quantity quantity to mint
  function adminMint(address recipient, uint256 quantity)
    external
    onlyRoleOrAdmin(MINTER_ROLE)
    canMintTokens(quantity)
    returns (uint256)
  {
    _mintNFTs(recipient, quantity);

    return _lastMintedTokenId();
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |         adminMintAirdrop()        |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  caller is not admin or minter role?    |               !
  //          !_____/      |                                   |               !
  //          !            | revert Access_MissingRoleOrAdmin()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  drop has no tokens left for recipients to mint?        !
  //          !_____/      |                                   |               !
  //          !            |       revert Mint_SoldOut()       |               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //                       |                    _____________________________________
  //                       |                    ! LOOP  /  for all recipients        !
  //                       |                    !______/       |                     !
  //                       |                    !              |----.                !
  //                       |                    !              |    | mint tokens    !
  //                       |                    !              |<---'                !
  //                       |                    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |    return last minted token ID    |
  //                       | <----------------------------------
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @dev Mints multiple editions to the given list of addresses.
  /// @param recipients list of addresses to send the newly minted editions to
  function adminMintAirdrop(address[] calldata recipients)
    external
    override
    onlyRoleOrAdmin(MINTER_ROLE)
    canMintTokens(recipients.length)
    returns (uint256)
  {
    uint256 currentId = _currentIndex;
    uint256 startAt = currentId;

    unchecked {
      for (uint256 endAt = currentId + recipients.length; currentId < endAt; currentId++) {
        _mintNFTs(recipients[currentId - startAt], 1);
      }
    }
    return _lastMintedTokenId();
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***  ADMIN CONFIGURATION FUNCTIONS     ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                    ,----------.
  //                       / \                   |ERC721Drop|
  //                     Caller                  `----+-----'
  //                       |        setOwner()        |
  //                       | ------------------------->
  //                       |                          |
  //                       |                          |
  //          ________________________________________________________
  //          ! ALT  /  caller is not admin?          |               !
  //          !_____/      |                          |               !
  //          !            | revert Access_OnlyAdmin()|               !
  //          !            | <-------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                          |
  //                       |                          |----.
  //                       |                          |    | set owner
  //                       |                          |<---'
  //                     Caller                  ,----+-----.
  //                       ,-.                   |ERC721Drop|
  //                       `-'                   `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @dev Set new owner for royalties / opensea
  /// @param newOwner new owner to set
  function setOwner(address newOwner) public override onlyAdmin {
    assembly {
      sstore(_ownerSlot, newOwner)
    }
  }

  /// @notice Set a new metadata renderer
  /// @param newRenderer new renderer address to use
  /// @param setupRenderer data to setup new renderer with
  function setMetadataRenderer(IMetadataRenderer newRenderer, bytes memory setupRenderer) external onlyAdmin {
    config.metadataRenderer = newRenderer;

    if (setupRenderer.length > 0) {
      newRenderer.initializeWithData(setupRenderer);
    }

    emit UpdatedMetadataRenderer({sender: msg.sender, renderer: newRenderer});
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |      setSalesConfiguration()      |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  caller is not admin?                   |               !
  //          !_____/      |                                   |               !
  //          !            | revert Access_MissingRoleOrAdmin()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | set funds recipient
  //                       |                                   |<---'
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | emit FundsRecipientChanged()
  //                       |                                   |<---'
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @dev This sets the sales configuration
  /// @param publicSalePrice New public sale price
  /// @param maxSalePurchasePerAddress Max # of purchases (public) per address allowed
  /// @param publicSaleStart unix timestamp when the public sale starts
  /// @param publicSaleEnd unix timestamp when the public sale ends (set to 0 to disable)
  /// @param presaleStart unix timestamp when the presale starts
  /// @param presaleEnd unix timestamp when the presale ends
  /// @param presaleMerkleRoot merkle root for the presale information
  function setSaleConfiguration(
    uint104 publicSalePrice,
    uint32 maxSalePurchasePerAddress,
    uint64 publicSaleStart,
    uint64 publicSaleEnd,
    uint64 presaleStart,
    uint64 presaleEnd,
    bytes32 presaleMerkleRoot
  ) external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
    salesConfig.publicSalePrice = publicSalePrice;
    salesConfig.maxSalePurchasePerAddress = maxSalePurchasePerAddress;
    salesConfig.publicSaleStart = publicSaleStart;
    salesConfig.publicSaleEnd = publicSaleEnd;
    salesConfig.presaleStart = presaleStart;
    salesConfig.presaleEnd = presaleEnd;
    salesConfig.presaleMerkleRoot = presaleMerkleRoot;

    emit SalesConfigChanged(msg.sender);
  }

  //                       ,-.
  //                       `-'
  //                       /|\
  //                        |                             ,----------.
  //                       / \                            |ERC721Drop|
  //                     Caller                           `----+-----'
  //                       |       finalizeOpenEdition()       |
  //                       | ---------------------------------->
  //                       |                                   |
  //                       |                                   |
  //          _________________________________________________________________
  //          ! ALT  /  caller is not admin or SALES_MANAGER_ROLE?             !
  //          !_____/      |                                   |               !
  //          !            | revert Access_MissingRoleOrAdmin()|               !
  //          !            | <----------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |
  //                       |                    _______________________________________________________________________
  //                       |                    ! ALT  /  drop is not an open edition?                                 !
  //                       |                    !_____/        |                                                       !
  //                       |                    !              |----.                                                  !
  //                       |                    !              |    | revert Admin_UnableToFinalizeNotOpenEdition()    !
  //                       |                    !              |<---'                                                  !
  //                       |                    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | set config edition size
  //                       |                                   |<---'
  //                       |                                   |
  //                       |                                   |----.
  //                       |                                   |    | emit OpenMintFinalized()
  //                       |                                   |<---'
  //                     Caller                           ,----+-----.
  //                       ,-.                            |ERC721Drop|
  //                       `-'                            `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @notice Admin function to finalize and open edition sale
  function finalizeOpenEdition() external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
    if (config.editionSize != type(uint64).max) {
      revert Admin_UnableToFinalizeNotOpenEdition();
    }

    config.editionSize = uint64(_totalMinted());
    emit OpenMintFinalized(msg.sender, config.editionSize);
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***      GENERAL GETTER FUNCTIONS      ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /// @notice Contract URI Getter, proxies to metadataRenderer
  /// @return Contract URI
  function contractURI() external view returns (string memory) {
    return config.metadataRenderer.contractURI();
  }

  /// @notice Getter for metadataRenderer contract
  function metadataRenderer() external view returns (IMetadataRenderer) {
    return IMetadataRenderer(config.metadataRenderer);
  }

  /// @notice Token URI Getter, proxies to metadataRenderer
  /// @param tokenId id of token to get URI for
  /// @return Token URI
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) {
      revert IERC721AUpgradeable.URIQueryForNonexistentToken();
    }

    return config.metadataRenderer.tokenURI(tokenId);
  }

  /// @notice ERC165 supports interface
  /// @param interfaceId interface id to check if supported
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721AUpgradeable, AccessControl)
    returns (bool)
  {
    return
      super.supportsInterface(interfaceId) ||
      type(IOwnable).interfaceId == interfaceId ||
      type(IHolographERC721Drop).interfaceId == interfaceId;
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***        INTERFACE FUNCTIONS         ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  function _holograph() internal view returns (HolographInterface holograph) {
    assembly {
      /**
       * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
       */
      holograph := sload(0xb4107f746e9496e8452accc7de63d1c5e14c19f510932daa04077cd49e8bd77a)
    }
  }

  /**
   * @dev Get the interfaces contract address.
   */
  function _interfaces() internal view returns (address) {
    return _holograph().getInterfaces();
  }

  /**
   * @dev Get the bridge contract address.
   */
  function _royalties() internal view returns (address) {
    return
      HolographRegistryInterface(_holograph().getRegistry()).getContractTypeAddress(0x0000000000000000000000000000486f6c6f6772617068526f79616c74696573);
  }

  event FundsReceived(address indexed source, uint256 amount);

  receive() external payable {
    emit FundsReceived(msg.sender, msg.value);
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***        FALLBACK FUNCTIONS          ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /**
   * @notice Fallback to the source contract.
   * @dev Any function call that is not covered here, will automatically be sent over to the source contract.
   */
  fallback() external payable {
    // Check if royalties support the function, send there, otherwise revert to source
    address _target;
    if (HolographInterfacesInterface(_interfaces()).supportsInterface(InterfaceType.ROYALTIES, msg.sig)) {
      _target = _royalties();
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
      assembly {
        calldatacopy(0, 0, calldatasize())
        mstore(calldatasize(), caller())
        /**
         * @dev bytes32(uint256(keccak256('eip1967.Holograph.sourceContract')) - 1)
         */
        let result := call(
          gas(),
          sload(0x27d542086d1e831d40b749e7f5509a626c3047a36d160781c40d5acc83e5b074),
          callvalue(),
          0,
          add(calldatasize(), 0x20),
          0,
          0
        )
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
