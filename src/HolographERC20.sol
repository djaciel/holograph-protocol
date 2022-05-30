/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/EIP712.sol";
import "./abstract/Initializable.sol";
import "./abstract/NonReentrant.sol";
import "./abstract/Owner.sol";

import "./enum/HolographERC20Event.sol";
import "./enum/InterfaceType.sol";

import "./interface/ERC20.sol";
import "./interface/ERC20Burnable.sol";
import "./interface/ERC20Holograph.sol";
import "./interface/ERC20Metadata.sol";
import "./interface/ERC20Permit.sol";
import "./interface/ERC20Receiver.sol";
import "./interface/ERC20Safer.sol";
import "./interface/ERC165.sol";
import "./interface/HolographedERC20.sol";
import "./interface/IHolograph.sol";
import "./interface/IHolographer.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";
import "./interface/IInterfaces.sol";
import "./interface/Ownable.sol";

import "./library/Address.sol";
import "./library/Base64.sol";
import "./library/Booleans.sol";
import "./library/Counters.sol";
import "./library/ECDSA.sol";
import "./library/Strings.sol";

/**
 * @title Holograph Bridgeable ERC-20 Token
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph Bridgeable ERC20 Tokens.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract HolographERC20 is Admin, Owner, Initializable, NonReentrant, EIP712, ERC20Holograph {
  using Counters for Counters.Counter;

  /**
   * @dev Configuration for events to trigger for source smart contract.
   */
  uint256 private _eventConfig;

  /**
   * @dev Mapping of all the addresse's balances.
   */
  mapping(address => uint256) private _balances;

  /**
   * @dev Mapping of all authorized operators, and capped amounts.
   */
  mapping(address => mapping(address => uint256)) private _allowances;

  /**
   * @dev Total number of token in circulation.
   */
  uint256 private _totalSupply;

  /**
   * @dev Token name.
   */
  string private _name;

  /**
   * @dev Token ticker symbol.
   */
  string private _symbol;

  /**
   * @dev Token number of decimal places.
   */
  uint8 private _decimals;

  /**
   * @dev List of used up nonces. Used in the ERC20Permit interface functionality.
   */
  mapping(address => Counters.Counter) private _nonces;

  /**
   * @dev Constructor does not accept any parameters.
   */
  constructor() {}

  /**
   * @notice Initializes the collection.
   * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
   */
  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "ERC20: already initialized");
    assembly {
      sstore(precomputeslot("eip1967.Holograph.Bridge.reentrant"), 1)
      sstore(precomputeslot("eip1967.Holograph.Bridge.owner"), caller())
    }
    (
      string memory contractName,
      string memory contractSymbol,
      uint8 contractDecimals,
      uint256 eventConfig,
      string memory domainSeperator,
      string memory domainVersion,
      bool skipInit,
      bytes memory initCode
    ) = abi.decode(data, (string, string, uint8, uint256, string, string, bool, bytes));
    _name = contractName;
    _symbol = contractSymbol;
    _decimals = contractDecimals;
    _eventConfig = eventConfig;
    if (!skipInit) {
      try IHolographer(payable(address(this))).getSourceContract() returns (address payable sourceAddress) {
        require(
          IInitializable(sourceAddress).init(initCode) == IInitializable.init.selector,
          "ERC20: could not init source"
        );
      } catch {
        revert("ERC20: could not init source");
      }
    }
    _setInitialized();
    _eip712_init(domainSeperator, domainVersion);
    return IInitializable.init.selector;
  }

  function owner() public view override returns (address) {
    return Ownable(source()).owner();
  }

  /**
   * @dev Get the source smart contract.
   */
  function source() private view returns (address) {
    return IHolographer(payable(address(this))).getSourceContract();
  }

  /**
   * @dev Get the bridge contract address.
   */
  function bridge() private view returns (address) {
    return IHolograph(IHolographer(payable(address(this))).getHolograph()).getBridge();
  }

  /**
   * @dev Get the interfaces contract address.
   */
  function interfaces() private view returns (address) {
    return IHolograph(IHolographer(payable(address(this))).getHolograph()).getInterfaces();
  }

  /**
   * @dev Get the source smart contract as bridgeable interface.
   */
  function SourceERC20() private view returns (HolographedERC20) {
    return HolographedERC20(source());
  }

  /**
   * @dev Purposefully left empty, to prevent running out of gas errors when receiving native token payments.
   */
  receive() external payable {}

  /**
   * @notice Fallback to the source contract.
   * @dev Any function call that is not covered here, will automatically be sent over to the source contract.
   */
  fallback() external payable {
    /**
     * @dev We forward the calldata to source contract via a call request.
     *  Since this replaces msg.sender with address(this), we inject original msg.sender into calldata.
     *  This allows us to protect this contract's storage layer from source contract's malicious actions.
     *  This way a source contract can simultaneously access holographer address and the real msg.sender.
     */
    address _target = source();
    assembly {
      calldatacopy(0, 0, calldatasize())
      mstore(calldatasize(), caller())
      let result := call(gas(), _target, callvalue(), 0, add(calldatasize(), 32), 0, 0)
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

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Although EIP-165 is not required for ERC20 contracts, we still decided to implement it.
   *
   * This makes it easier for external smart contracts to easily identify a valid ERC20 token contract.
   */
  function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    return IInterfaces(interfaces()).supportsInterface(InterfaceType.ERC20, interfaceId);
  }

  function allowance(address account, address spender) public view returns (uint256) {
    return _allowances[account][spender];
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return _domainSeparatorV4();
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function nonces(address account) public view returns (uint256) {
    return _nonces[account].current();
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function approve(address spender, uint256 amount) public returns (bool) {
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeApprove)) {
      require(SourceERC20().beforeApprove(msg.sender, spender, amount));
    }
    _approve(msg.sender, spender, amount);
    if (Booleans.get(_eventConfig, HolographERC20Event.afterApprove)) {
      require(SourceERC20().afterApprove(msg.sender, spender, amount));
    }
    return true;
  }

  function burn(uint256 amount) public {
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeBurn)) {
      require(SourceERC20().beforeBurn(msg.sender, amount));
    }
    _burn(msg.sender, amount);
    if (Booleans.get(_eventConfig, HolographERC20Event.afterBurn)) {
      require(SourceERC20().afterBurn(msg.sender, amount));
    }
  }

  function burnFrom(address account, uint256 amount) public returns (bool) {
    uint256 currentAllowance = _allowances[account][msg.sender];
    require(currentAllowance >= amount, "ERC20: amount exceeds allowance");
    unchecked {
      _allowances[account][msg.sender] = currentAllowance - amount;
    }
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeBurn)) {
      require(SourceERC20().beforeBurn(account, amount));
    }
    _burn(account, amount);
    if (Booleans.get(_eventConfig, HolographERC20Event.afterBurn)) {
      require(SourceERC20().afterBurn(account, amount));
    }
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 currentAllowance = _allowances[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased below zero");
    uint256 newAllowance;
    unchecked {
      newAllowance = currentAllowance - subtractedValue;
    }
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeApprove)) {
      require(SourceERC20().beforeApprove(msg.sender, spender, newAllowance));
    }
    _approve(msg.sender, spender, newAllowance);
    if (Booleans.get(_eventConfig, HolographERC20Event.afterApprove)) {
      require(SourceERC20().afterApprove(msg.sender, spender, newAllowance));
    }
    return true;
  }

  /**
   * @dev Allows the bridge to bring in tokens from another blockchain.
   */
  function holographBridgeIn(
    uint32 chainType,
    address from,
    address to,
    uint256 amount,
    bytes calldata data
  ) external returns (bytes4) {
    require(msg.sender == bridge(), "ERC20: only bridge can call");
    _mint(bridge(), amount);
    _transfer(bridge(), from, amount);
    if (from != to) {
      _transfer(from, to, amount);
    }
    if (Booleans.get(_eventConfig, 1)) {
      require(SourceERC20().bridgeIn(chainType, from, to, amount, data), "HOLOGRAPH: bridge in failed");
    }
    return ERC20Holograph.holographBridgeIn.selector;
  }

  /**
   * @dev Allows the bridge to take tokens out onto another blockchain.
   */
  function holographBridgeOut(
    uint32 chainType,
    address operator,
    address from,
    address to,
    uint256 amount
  ) external returns (bytes4 selector, bytes memory data) {
    require(msg.sender == bridge(), "ERC20: only bridge can call");
    if (operator != from) {
      uint256 currentAllowance = _allowances[from][operator];
      require(currentAllowance >= amount, "ERC20: amount exceeds allowance");
      unchecked {
        _allowances[from][operator] = currentAllowance - amount;
      }
    }
    if (from != to) {
      _transfer(from, to, amount);
    }
    _transfer(to, bridge(), amount);
    if (Booleans.get(_eventConfig, 2)) {
      data = SourceERC20().bridgeOut(chainType, from, to, amount);
    }
    _burn(bridge(), amount);
    return (ERC20Holograph.holographBridgeOut.selector, data);
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    uint256 currentAllowance = _allowances[msg.sender][spender];
    uint256 newAllowance;
    unchecked {
      newAllowance = currentAllowance + addedValue;
    }
    unchecked {
      require(newAllowance >= currentAllowance, "ERC20: increased above max value");
    }
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeApprove)) {
      require(SourceERC20().beforeApprove(msg.sender, spender, newAllowance));
    }
    _approve(msg.sender, spender, newAllowance);
    if (Booleans.get(_eventConfig, HolographERC20Event.afterApprove)) {
      require(SourceERC20().afterApprove(msg.sender, spender, newAllowance));
    }
    return true;
  }

  function onERC20Received(
    address account,
    address sender,
    uint256 amount,
    bytes calldata data
  ) public returns (bytes4) {
    require(Address.isContract(account), "ERC20: operator not contract");
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeOnERC20Received)) {
      require(SourceERC20().beforeOnERC20Received(account, sender, address(this), amount, data));
    }
    try ERC20(account).balanceOf(address(this)) returns (uint256 balance) {
      require(balance >= amount, "ERC20: balance check failed");
    } catch {
      revert("ERC20: failed getting balance");
    }
    if (Booleans.get(_eventConfig, HolographERC20Event.afterOnERC20Received)) {
      require(SourceERC20().afterOnERC20Received(account, sender, address(this), amount, data));
    }
    return ERC20Receiver.onERC20Received.selector;
  }

  function permit(
    address account,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    require(block.timestamp <= deadline, "ERC20: expired deadline");
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    //  == 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
    bytes32 structHash = keccak256(
      abi.encode(
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9,
        account,
        spender,
        amount,
        _useNonce(account),
        deadline
      )
    );
    bytes32 hash = _hashTypedDataV4(structHash);
    address signer = ECDSA.recover(hash, v, r, s);
    require(signer == account, "ERC20: invalid signature");
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeApprove)) {
      require(SourceERC20().beforeApprove(account, spender, amount));
    }
    _approve(account, spender, amount);
    if (Booleans.get(_eventConfig, HolographERC20Event.afterApprove)) {
      require(SourceERC20().afterApprove(account, spender, amount));
    }
  }

  function safeTransfer(address recipient, uint256 amount) public returns (bool) {
    return safeTransfer(recipient, amount, "");
  }

  function safeTransfer(
    address recipient,
    uint256 amount,
    bytes memory data
  ) public returns (bool) {
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeSafeTransfer)) {
      require(SourceERC20().beforeSafeTransfer(msg.sender, recipient, amount, data));
    }
    _transfer(msg.sender, recipient, amount);
    require(_checkOnERC20Received(msg.sender, recipient, amount, data), "ERC20: non ERC20Receiver");
    if (Booleans.get(_eventConfig, HolographERC20Event.afterSafeTransfer)) {
      require(SourceERC20().afterSafeTransfer(msg.sender, recipient, amount, data));
    }
    return true;
  }

  function safeTransferFrom(
    address account,
    address recipient,
    uint256 amount
  ) public returns (bool) {
    return safeTransferFrom(account, recipient, amount, "");
  }

  function safeTransferFrom(
    address account,
    address recipient,
    uint256 amount,
    bytes memory data
  ) public returns (bool) {
    if (account != msg.sender) {
      uint256 currentAllowance = _allowances[account][msg.sender];
      require(currentAllowance >= amount, "ERC20: amount exceeds allowance");
      unchecked {
        _allowances[account][msg.sender] = currentAllowance - amount;
      }
    }
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeSafeTransfer)) {
      require(SourceERC20().beforeSafeTransfer(account, recipient, amount, data));
    }
    _transfer(account, recipient, amount);
    require(_checkOnERC20Received(account, recipient, amount, data), "ERC20: non ERC20Receiver");
    if (Booleans.get(_eventConfig, HolographERC20Event.afterSafeTransfer)) {
      require(SourceERC20().afterSafeTransfer(account, recipient, amount, data));
    }
    return true;
  }

  /**
   * @dev Allows for source smart contract to burn tokens.
   */
  function sourceBurn(address from, uint256 amount) external {
    require(msg.sender == source(), "ERC20: only source can burn");
    _burn(from, amount);
  }

  /**
   * @dev Allows for source smart contract to mint tokens.
   */
  function sourceMint(address to, uint256 amount) external {
    require(msg.sender == source(), "ERC20: only source can mint");
    _mint(to, amount);
  }

  /**
   * @dev Allows for source smart contract to mint a batch of token amounts.
   */
  function sourceMintBatch(address[] calldata wallets, uint256[] calldata amounts) external {
    require(msg.sender == source(), "ERC20: only source can mint");
    for (uint256 i = 0; i < wallets.length; i++) {
      _mint(wallets[i], amounts[i]);
    }
  }

  /**
   * @dev Allows for source smart contract to transfer tokens.
   */
  function sourceTransfer(
    address from,
    address to,
    uint256 amount
  ) external {
    require(msg.sender == source(), "ERC20: only source can transfer");
    _transfer(from, to, amount);
  }

  function transfer(address recipient, uint256 amount) public returns (bool) {
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeTransfer)) {
      require(SourceERC20().beforeTransfer(msg.sender, recipient, amount));
    }
    _transfer(msg.sender, recipient, amount);
    if (Booleans.get(_eventConfig, HolographERC20Event.afterTransfer)) {
      require(SourceERC20().afterTransfer(msg.sender, recipient, amount));
    }
    return true;
  }

  function transferFrom(
    address account,
    address recipient,
    uint256 amount
  ) public returns (bool) {
    if (account != msg.sender) {
      uint256 currentAllowance = _allowances[account][msg.sender];
      require(currentAllowance >= amount, "ERC20: amount exceeds allowance");
      unchecked {
        _allowances[account][msg.sender] = currentAllowance - amount;
      }
    }
    if (Booleans.get(_eventConfig, HolographERC20Event.beforeTransfer)) {
      require(SourceERC20().beforeTransfer(account, recipient, amount));
    }
    _transfer(account, recipient, amount);
    if (Booleans.get(_eventConfig, HolographERC20Event.afterTransfer)) {
      require(SourceERC20().afterTransfer(account, recipient, amount));
    }
    return true;
  }

  function _approve(
    address account,
    address spender,
    uint256 amount
  ) internal {
    require(!Address.isZero(account), "ERC20: account is zero address");
    require(!Address.isZero(spender), "ERC20: spender is zero address");
    _allowances[account][spender] = amount;
    emit Approval(account, spender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(!Address.isZero(account), "ERC20: account is zero address");
    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;
    emit Transfer(account, address(0), amount);
  }

  function _checkOnERC20Received(
    address account,
    address recipient,
    uint256 amount,
    bytes memory data
  ) internal nonReentrant returns (bool) {
    if (Address.isContract(recipient)) {
      try ERC165(recipient).supportsInterface(0x01ffc9a7) returns (bool erc165support) {
        require(erc165support, "ERC20: no ERC165 support");
        // we have erc165 support
        if (ERC165(recipient).supportsInterface(0x534f5876)) {
          // we have eip-4524 support
          try ERC20Receiver(recipient).onERC20Received(address(this), account, amount, data) returns (bytes4 retval) {
            return retval == ERC20Receiver.onERC20Received.selector;
          } catch (bytes memory reason) {
            if (reason.length == 0) {
              revert("ERC20: non ERC20Receiver");
            } else {
              assembly {
                revert(add(32, reason), mload(reason))
              }
            }
          }
        } else {
          revert("ERC20: eip-4524 not supported");
        }
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC20: no ERC165 support");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @notice Mints tokens.
   * @dev Mint a specific amount of tokens to a specific address.
   * @param to Address to mint to.
   * @param amount Amount of tokens to mint.
   */
  function _mint(address to, uint256 amount) internal {
    require(!Address.isZero(to), "ERC20: minting to burn address");
    _totalSupply += amount;
    _balances[to] += amount;
    emit Transfer(address(0), to, amount);
  }

  function _transfer(
    address account,
    address recipient,
    uint256 amount
  ) internal {
    require(!Address.isZero(account), "ERC20: account is zero address");
    require(!Address.isZero(recipient), "ERC20: recipient is zero address");
    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _balances[recipient] += amount;
    emit Transfer(account, recipient, amount);
  }

  /**
   * @dev "Consume a nonce": return the current value and increment.
   *
   * _Available since v4.1._
   */
  function _useNonce(address account) internal returns (uint256 current) {
    Counters.Counter storage nonce = _nonces[account];
    current = nonce.current();
    nonce.increment();
  }
}
