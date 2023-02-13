// SPDX-License-Identifier: MIT

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Initializable.sol";

import {IHolographFeeManager} from "./interfaces/IHolographFeeManager.sol";
import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";
import {IOperatorFilterRegistry} from "./interfaces/IOperatorFilterRegistry.sol";
import {IHolographERC721Drop} from "./interfaces/IHolographERC721Drop.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";
import {IAccessControlUpgradeable} from "./interfaces/IAccessControlUpgradeable.sol";
import {IERC721Upgradeable} from "./interfaces/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "./interfaces/IERC721ReceiverUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "./interfaces/IERC721MetadataUpgradeable.sol";
import {IERC165Upgradeable} from "./interfaces/IERC165Upgradeable.sol";
import {IERC2981Upgradeable} from "./interfaces/IERC2981Upgradeable.sol";
import {IERC721AUpgradeable} from "./interfaces/IERC721AUpgradeable.sol";

import {DropInitializer} from "../struct/DropInitializer.sol";

library Strings {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }
}

library MerkleProof {
  /**
   * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
   * defined by `root`. For this, a `proof` must be provided, containing
   * sibling hashes on the branch from the leaf to the root of the tree. Each
   * pair of leaves and each pair of pre-images are assumed to be sorted.
   */
  function verify(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    return processProof(proof, leaf) == root;
  }

  /**
   * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
   * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
   * hash matches the root of the tree. When processing the proof, the pairs
   * of leafs & pre-images are assumed to be sorted.
   *
   * _Available since v4.4._
   */
  function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];
      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = _efficientHash(computedHash, proofElement);
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = _efficientHash(proofElement, computedHash);
      }
    }
    return computedHash;
  }

  function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
}

library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   *
   * [IMPORTANT]
   * ====
   * You shouldn't rely on `isContract` to protect against flash loan attacks!
   *
   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
   * constructor.
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, "Address: low-level delegate call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
   * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
   *
   * _Available since v4.8._
   */
  function verifyCallResultFromTarget(
    address target,
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  /**
   * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason or using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    // Look for revert reason and bubble it up if present
    if (returndata.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

library AddressUpgradeable {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   *
   * [IMPORTANT]
   * ====
   * You shouldn't rely on `isContract` to protect against flash loan attacks!
   *
   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
   * constructor.
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract ERC165 is IERC165Upgradeable {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165Upgradeable).interfaceId;
  }
}

abstract contract AccessControlUpgradeable is Initializable, Context, IAccessControlUpgradeable, ERC165 {
  function __AccessControl_init() internal onlyInitializing {}

  function __AccessControl_init_unchained() internal onlyInitializing {}

  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if `_msgSender()` is missing `role`.
   * Overriding this function changes the behavior of the {onlyRole} modifier.
   *
   * Format of the revert message is described in {_checkRole}.
   *
   * _Available since v4.6._
   */
  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, _msgSender());
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   */
  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            "AccessControl: account ",
            Strings.toHexString(uint160(account), 20),
            " is missing role ",
            Strings.toHexString(uint256(role), 32)
          )
        )
      );
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been revoked `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) public virtual override {
    require(account == _msgSender(), "AccessControl: can only renounce roles for self");

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   *
   * NOTE: This function is deprecated in favor of {_grantRole}.
   */
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * Internal function without access restriction.
   */
  function _grantRole(bytes32 role, address account) internal virtual {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * Internal function without access restriction.
   */
  function _revokeRole(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

abstract contract ReentrancyGuardUpgradeable is Initializable {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  function __ReentrancyGuard_init() internal onlyInitializing {
    __ReentrancyGuard_init_unchained();
  }

  function __ReentrancyGuard_init_unchained() internal onlyInitializing {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}

abstract contract PublicMulticall {
  /**
   * @dev Receives and executes a batch of function calls on this contract.
   */
  function multicall(bytes[] memory data) public virtual returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      results[i] = Address.functionDelegateCall(address(this), data[i]);
    }
  }
}

abstract contract ERC721AUpgradeable is Initializable, Context, ERC165, IERC721AUpgradeable {
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
    __ERC721A_init_unchained(name_, symbol_);
  }

  function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
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
    if (operator == _msgSender()) revert ApproveToCaller();

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
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

    bool isApprovedOrOwner = (_msgSender() == from ||
      isApprovedForAll(from, _msgSender()) ||
      getApproved(tokenId) == _msgSender());

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
      bool isApprovedOrOwner = (_msgSender() == from ||
        isApprovedForAll(from, _msgSender()) ||
        getApproved(tokenId) == _msgSender());

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
    try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[42] private __gap;
}

contract OwnableSkeleton is IOwnable {
  address private _owner;

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _setOwner(address newAddress) internal {
    emit OwnershipTransferred(_owner, newAddress);
    _owner = newAddress;
  }
}

contract FundsReceiver {
  event FundsReceived(address indexed source, uint256 amount);

  receive() external payable {
    emit FundsReceived(msg.sender, msg.value);
  }
}

contract ERC721DropStorageV1 {
  /// @notice Configuration for NFT minting contract storage
  IHolographERC721Drop.Configuration public config;

  /// @notice Sales configuration
  IHolographERC721Drop.SalesConfiguration public salesConfig;

  /// @dev Mapping for presale mint counts by address to allow public mint limit
  mapping(address => uint256) public presaleMintsByAddress;
}

/**
 * @notice HOLOGRAPH NFT contract for Drops and Editions
 *
 * @dev For drops: assumes 1. linear mint order, 2. max number of mints needs to be less than max_uint64
 *
 */
contract HolographERC721Drop is
  Initializable,
  ERC721AUpgradeable,
  IERC2981Upgradeable,
  ReentrancyGuardUpgradeable,
  AccessControlUpgradeable,
  IHolographERC721Drop,
  PublicMulticall,
  OwnableSkeleton,
  FundsReceiver,
  ERC721DropStorageV1
{
  /// @dev keep track of initialization state (Initializable)
  bool private _initialized;
  bool private _initializing;

  /// @dev This is the max mint batch size for the optimized ERC721A mint contract
  uint256 constant MAX_MINT_BATCH_SIZE = 8;

  /// @dev Gas limit to send funds
  uint256 constant FUNDS_SEND_GAS_LIMIT = 210_000;

  /// @notice Access control roles
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");
  bytes32 public constant SALES_MANAGER_ROLE = keccak256("SALES_MANAGER");

  /// @dev HOLOGRAPH transfer helper address for auto-approval
  address public holographERC721TransferHelper;

  /// @dev Holograph Fee Manager address
  IHolographFeeManager public holographFeeManager;

  /// @notice Max royalty BPS
  uint16 constant MAX_ROYALTY_BPS = 50_00;

  address public marketFilterAddress;

  IOperatorFilterRegistry public operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  /// @notice Only allow for users with admin access
  modifier onlyAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
      revert Access_OnlyAdmin();
    }

    _;
  }

  /// @notice Only a given role has access or admin
  /// @param role role to check for alongside the admin role
  modifier onlyRoleOrAdmin(bytes32 role) {
    if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) && !hasRole(role, _msgSender())) {
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

  /// @dev Initialize a new drop contract
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");

    // TODO: OZ Initializable pattern (review)
    _initialized = false;
    _initializing = true;

    DropInitializer memory initializer = abi.decode(initPayload, (DropInitializer));
    holographFeeManager = IHolographFeeManager(initializer.holographFeeManager);
    holographERC721TransferHelper = initializer.holographERC721TransferHelper;
    marketFilterAddress = initializer.marketFilterAddress;

    // Setup ERC721A
    // Call to ERC721AUpgradeable init has been replaced with the following
    // __ERC721A_init(initializer.contractName, initializer.contractSymbol);
    _name = initializer.contractName;
    _symbol = initializer.contractSymbol;
    _currentIndex = _startTokenId();

    // Setup AccessControl
    // TODO: OZ Initializable pattern. AccessControl does not set anything in _init_ (review)
    // Setup access control
    // __AccessControl_init();
    // Setup the owner role
    _setupRole(DEFAULT_ADMIN_ROLE, initializer.initialOwner);
    // Set ownership to original sender of contract call
    _setOwner(initializer.initialOwner);

    if (initializer.setupCalls.length > 0) {
      // Setup temporary role
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      // Execute setupCalls
      multicall(initializer.setupCalls);
      // Remove temporary role
      _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // TODO: OZ Initializable pattern. Need to initialize to _NOT_ENTERED (review)
    // Setup re-entracy guard
    // __ReentrancyGuard_init();

    if (config.royaltyBPS > MAX_ROYALTY_BPS) {
      revert Setup_RoyaltyPercentageTooHigh(MAX_ROYALTY_BPS);
    }

    // Setup config variables
    config.editionSize = initializer.editionSize;
    config.metadataRenderer = IMetadataRenderer(initializer.metadataRenderer);
    config.royaltyBPS = initializer.royaltyBPS;
    config.fundsRecipient = initializer.fundsRecipient;

    // TODO: Need to make sure to initialize the metadata renderer
    IMetadataRenderer(initializer.metadataRenderer).initializeWithData(initializer.metadataRendererInit);

    // TODO: OZ Initializable pattern (review)
    _initializing = false;
    _initialized = true;

    // Holograph initialization
    _setInitialized();
    return InitializableInterface.init.selector;
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

  /// @dev Get royalty information for token
  /// @param _salePrice Sale price for the token
  function royaltyInfo(uint256, uint256 _salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    if (config.fundsRecipient == address(0)) {
      return (config.fundsRecipient, 0);
    }
    return (config.fundsRecipient, (_salePrice * config.royaltyBPS) / 10_000);
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

  /// @dev Gets the holograph fee for amount of withdraw
  /// @param amount amount of funds to get fee for
  function holographFeeForAmount(uint256 amount) public returns (address payable, uint256) {
    (address payable recipient, uint256 bps) = holographFeeManager.getWithdrawFeesBps(address(this));
    return (recipient, (amount * bps) / 10_000);
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
      _numberMinted(_msgSender()) + quantity - presaleMintsByAddress[_msgSender()] >
      salesConfig.maxSalePurchasePerAddress
    ) {
      revert Purchase_TooManyForAddress();
    }

    _mintNFTs(_msgSender(), quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IHolographERC721Drop.Sale({
      to: _msgSender(),
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
          abi.encode(_msgSender(), maxQuantity, pricePerToken)
        )
      )
    ) {
      revert Presale_MerkleNotApproved();
    }

    if (msg.value != pricePerToken * quantity) {
      revert Purchase_WrongPrice(pricePerToken * quantity);
    }

    presaleMintsByAddress[_msgSender()] += quantity;
    if (presaleMintsByAddress[_msgSender()] > maxQuantity) {
      revert Presale_TooManyForAddress();
    }

    _mintNFTs(_msgSender(), quantity);
    uint256 firstMintedTokenId = _lastMintedTokenId() - quantity;

    emit IHolographERC721Drop.Sale({
      to: _msgSender(),
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
    if (from != msg.sender && address(operatorFilterRegistry).code.length > 0) {
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
  function setOwner(address newOwner) public onlyAdmin {
    _setOwner(newOwner);
  }

  /// @notice Set a new metadata renderer
  /// @param newRenderer new renderer address to use
  /// @param setupRenderer data to setup new renderer with
  function setMetadataRenderer(IMetadataRenderer newRenderer, bytes memory setupRenderer) external onlyAdmin {
    config.metadataRenderer = newRenderer;

    if (setupRenderer.length > 0) {
      newRenderer.initializeWithData(setupRenderer);
    }

    emit UpdatedMetadataRenderer({sender: _msgSender(), renderer: newRenderer});
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

    emit SalesConfigChanged(_msgSender());
  }

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
  //          ! ALT  /  caller is not admin or SALES_MANAGER_ROLE?    !
  //          !_____/      |                          |               !
  //          !            | revert Access_OnlyAdmin()|               !
  //          !            | <-------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                          |
  //                       |                          |----.
  //                       |                          |    | set sales configuration
  //                       |                          |<---'
  //                       |                          |
  //                       |                          |----.
  //                       |                          |    | emit SalesConfigChanged()
  //                       |                          |<---'
  //                     Caller                  ,----+-----.
  //                       ,-.                   |ERC721Drop|
  //                       `-'                   `----------'
  //                       /|\
  //                        |
  //                       / \
  /// @notice Set a different funds recipient
  /// @param newRecipientAddress new funds recipient address
  function setFundsRecipient(address payable newRecipientAddress) external onlyRoleOrAdmin(SALES_MANAGER_ROLE) {
    if (newRecipientAddress == address(0)) {
      revert Admin_InvalidFundRecipientAddress(newRecipientAddress);
    }

    config.fundsRecipient = newRecipientAddress;
    emit FundsRecipientChanged(newRecipientAddress, _msgSender());
  }

  //                       ,-.                  ,-.                      ,-.
  //                       `-'                  `-'                      `-'
  //                       /|\                  /|\                      /|\
  //                        |                    |                        |                      ,----------.
  //                       / \                  / \                      / \                     |ERC721Drop|
  //                     Caller            FeeRecipient            FundsRecipient                `----+-----'
  //                       |                    |           withdraw()   |                            |
  //                       | ------------------------------------------------------------------------->
  //                       |                    |                        |                            |
  //                       |                    |                        |                            |
  //          ________________________________________________________________________________________________________
  //          ! ALT  /  caller is not admin or manager?                  |                            |               !
  //          !_____/      |                    |                        |                            |               !
  //          !            |                    revert Access_WithdrawNotAllowed()                    |               !
  //          !            | <-------------------------------------------------------------------------               !
  //          !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //          !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    |                        |                            |
  //                       |                    |                   send fee amount                   |
  //                       |                    | <----------------------------------------------------
  //                       |                    |                        |                            |
  //                       |                    |                        |                            |
  //                       |                    |                        |             ____________________________________________________________
  //                       |                    |                        |             ! ALT  /  send unsuccesful?                                 !
  //                       |                    |                        |             !_____/        |                                            !
  //                       |                    |                        |             !              |----.                                       !
  //                       |                    |                        |             !              |    | revert Withdraw_FundsSendFailure()    !
  //                       |                    |                        |             !              |<---'                                       !
  //                       |                    |                        |             !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    |                        |             !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    |                        |                            |
  //                       |                    |                        | send remaining funds amount|
  //                       |                    |                        | <---------------------------
  //                       |                    |                        |                            |
  //                       |                    |                        |                            |
  //                       |                    |                        |             ____________________________________________________________
  //                       |                    |                        |             ! ALT  /  send unsuccesful?                                 !
  //                       |                    |                        |             !_____/        |                                            !
  //                       |                    |                        |             !              |----.                                       !
  //                       |                    |                        |             !              |    | revert Withdraw_FundsSendFailure()    !
  //                       |                    |                        |             !              |<---'                                       !
  //                       |                    |                        |             !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                       |                    |                        |             !~[noop]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
  //                     Caller            FeeRecipient            FundsRecipient                ,----+-----.
  //                       ,-.                  ,-.                      ,-.                     |ERC721Drop|
  //                       `-'                  `-'                      `-'                     `----------'
  //                       /|\                  /|\                      /|\
  //                        |                    |                        |
  //                       / \                  / \                      / \
  /// @notice This withdraws ETH from the contract to the contract owner.
  function withdraw() external nonReentrant {
    address sender = _msgSender();

    // Get fee amount
    uint256 funds = address(this).balance;
    (address payable feeRecipient, uint256 holographFee) = holographFeeForAmount(funds);

    // Check if withdraw is allowed for sender
    if (
      !hasRole(DEFAULT_ADMIN_ROLE, sender) &&
      !hasRole(SALES_MANAGER_ROLE, sender) &&
      sender != feeRecipient &&
      sender != config.fundsRecipient
    ) {
      revert Access_WithdrawNotAllowed();
    }

    // Payout HOLOGRAPH fee
    if (holographFee > 0) {
      (bool successFee, ) = feeRecipient.call{value: holographFee, gas: FUNDS_SEND_GAS_LIMIT}("");
      if (!successFee) {
        revert Withdraw_FundsSendFailure();
      }
      funds -= holographFee;
    }

    // Payout recipient
    (bool successFunds, ) = config.fundsRecipient.call{value: funds, gas: FUNDS_SEND_GAS_LIMIT}("");
    if (!successFunds) {
      revert Withdraw_FundsSendFailure();
    }

    // Emit event for indexing
    emit FundsWithdrawn(_msgSender(), config.fundsRecipient, funds, feeRecipient, holographFee);
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
    emit OpenMintFinalized(_msgSender(), config.editionSize);
  }

  /**
   *** ---------------------------------- ***
   ***                                    ***
   ***      GENERAL GETTER FUNCTIONS      ***
   ***                                    ***
   *** ---------------------------------- ***
   ***/

  /// @notice Simple override for owner interface.
  /// @return user owner address
  function owner() public view override(OwnableSkeleton, IHolographERC721Drop) returns (address) {
    return super.owner();
  }

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
    override(ERC721AUpgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return
      super.supportsInterface(interfaceId) ||
      type(IOwnable).interfaceId == interfaceId ||
      type(IERC2981Upgradeable).interfaceId == interfaceId ||
      type(IHolographERC721Drop).interfaceId == interfaceId;
  }

  // /**
  //  *** ---------------------------------- ***
  //  ***                                    ***
  //  ***        FALLBACK FUNCTIONS          ***
  //  ***                                    ***
  //  *** ---------------------------------- ***
  //  ***/

  // /**
  //  * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
  //  */
  // receive() external payable {}

  // /**
  //  * @notice Fallback to the source contract.
  //  * @dev Any function call that is not covered here, will automatically be sent over to the source contract.
  //  */
  // fallback() external payable {
  //   // Check if royalties support the function, send there, otherwise revert to source
  //   address _target;
  //   if (HolographInterfacesInterface(_interfaces()).supportsInterface(InterfaceType.ROYALTIES, msg.sig)) {
  //     _target = _royalties();
  //     assembly {
  //       calldatacopy(0, 0, calldatasize())
  //       let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
  //       returndatacopy(0, 0, returndatasize())
  //       switch result
  //       case 0 {
  //         revert(0, returndatasize())
  //       }
  //       default {
  //         return(0, returndatasize())
  //       }
  //     }
  //   } else {
  //     assembly {
  //       calldatacopy(0, 0, calldatasize())
  //       mstore(calldatasize(), caller())
  //       let result := call(gas(), sload(_sourceContractSlot), callvalue(), 0, add(calldatasize(), 0x20), 0, 0)
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
}
