HOLOGRAPH_LICENSE_HEADER

SOLIDITY_COMPILER_VERSION

import "../abstract/ERC20H.sol";

import "../interface/ERC20.sol";
import "../interface/ERC20Holograph.sol";
import "../interface/IHolograph.sol";
import "../interface/IHolographer.sol";

import "../library/Strings.sol";

/**
 * @title Holograph token (aka hToken), used to wrap and bridge native tokens across blockchains.
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph's Bridgeable ERC20 Tokens.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract hToken is ERC20H {

    /*
     * @dev Address of initial creator/owner of the contract.
     */
    address private _owner;

    /*
     * @dev Sample fee for unwrapping.
     */
    uint16 private _feeBp; // 100.00%

    /*
     * @dev List of supported Wrapped Tokens (equivalent), on current-chain.
     */
    mapping(address => bool) private _supportedWrappers;

    /*
     * @dev Event that is triggered when native token is converted into hToken.
     */
    event Deposit(address indexed from, uint256 amount);

    /*
     * @dev Event that is triggered when ERC20 token is converted into hToken.
     */
    event Deposit(address indexed token, address indexed from, uint256 amount);

    /*
     * @dev Event that is triggered when hToken is converted into native token.
     */
    event Withdrawal(address indexed to, uint256 amount);

    /*
     * @dev Event that is triggered when hToken is converted into ERC20 token.
     */
    event Withdrawal(address indexed token, address indexed to, uint256 amount);

    modifier onlyOwner(address msgSender) {
        require(msgSender == _owner, "owner only function");
        _;
    }

    /**
     * @notice Constructor is empty and not utilised.
     * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
     */
    constructor() {}

    /**
     * @notice Initializes the token.
     * @dev Special function to allow a one time initialisation on deployment.
     */
    function init(bytes memory data) external override returns (bytes4) {
        (address owner, uint16 fee) = abi.decode(data, (address, uint16));
        _owner = owner;
        _feeBp = fee;
        // run underlying initializer logic
        return _init(data);
    }

    /*
     * @dev Send native token value, get back hToken equivalent.
     * @param recipient Address of where to send the hToken(s) to.
     */
    function holographNativeToken(address msgSender, address recipient) external payable onlyHolographer {
        require(
            (
                IHolographer(holographer()).getOriginChain()
                == IHolograph(0x20202020486f6c6f677261706841646472657373).getChainType()
            ),
            "hToken: not native token"
        );
        require(msg.value > 0, "hToken: no value received");
        if (recipient == address(0)) {
            recipient = msgSender;
        }
        ERC20Holograph(holographer()).sourceMint(recipient, msg.value);
        emit Deposit(msgSender, msg.value);
    }

    /*
     * @dev Send hToken, get back native token value equivalent.
     * @param recipient Address of where to send the native token(s) to.
     */
    function extractNativeToken(address msgSender, address payable recipient, uint256 amount) external onlyHolographer {
        require(ERC20(address(this)).balanceOf(msgSender) >= amount, "hToken: not enough hToken(s)");
        require(
            (
                IHolographer(holographer()).getOriginChain()
                == IHolograph(0x20202020486f6c6f677261706841646472657373).getChainType()
            ),
            "hToken: not on native chain"
        );
        require(address(this).balance >= amount, "hToken: not enough native tokens");
        ERC20Holograph(holographer()).sourceBurn(msgSender, amount);
        // HERE WE NEED TO ADD FEE MECHANISM TO EXTRACT xx.xxxx% FROM NATIVE TOKEN AMOUNT
        // THIS SHOULD GO SOMEWHERE TO REWARD CAPITAL PROVIDERS
        uint256 fee = (amount / 10000) * _feeBp;
        // for now we just leave fee in contract balance
        //
        // amount is updated to reflect fee subtraction
        amount = amount - fee;
        recipient.transfer(amount);
        emit Withdrawal(recipient, amount);
    }

    /*
     * @dev Send supported wrapped token, get back hToken equivalent.
     * @param recipient Address of where to send the hToken(s) to.
     */
    function holographWrappedToken(address msgSender, address token, address recipient, uint256 amount) external onlyHolographer {
        require(_supportedWrappers[token], "hToken: unsupported token type");
        ERC20 erc20 = ERC20(token);
        require(erc20.allowance(msgSender, address(this)) >= amount, "hToken: allowance too low");
        uint256 previousBalance = erc20.balanceOf(address(this));
        require(erc20.transferFrom(msgSender, address(this), amount), "hToken: ERC20 transfer failed");
        uint256 currentBalance = erc20.balanceOf(address(this));
        uint256 difference = currentBalance - previousBalance;
        require(difference >= 0, "hToken: no tokens transferred");
        if (difference < amount) {
            // adjust for fee-based mechanisms
            // this allows for discrepancies to not fail the entire operation
            amount = difference;
        }
        if (recipient == address(0)) {
            recipient = msgSender;
        }
        ERC20Holograph(holographer()).sourceMint(recipient, amount);
        emit Deposit(token, msgSender, amount);
    }

    /*
     * @dev Send hToken, get back native token value equivalent.
     * @param recipient Address of where to send the native token(s) to.
     */
    function extractWrappedToken(address msgSender, address token, address payable recipient, uint256 amount) external onlyHolographer {
        require(_supportedWrappers[token], "hToken: unsupported token type");
        require(ERC20(address(this)).balanceOf(msgSender) >= amount, "hToken: not enough hToken(s)");
        ERC20 erc20 = ERC20(token);
        uint256 previousBalance = erc20.balanceOf(address(this));
        require(previousBalance >= amount, "hToken: not enough ERC20 tokens");
        if (recipient == address(0)) {
            recipient = payable(msgSender);
        }
        // HERE WE NEED TO ADD FEE MECHANISM TO EXTRACT xx.xxxx% FROM NATIVE TOKEN AMOUNT
        // THIS SHOULD GO SOMEWHERE TO REWARD CAPITAL PROVIDERS
        uint256 fee = (amount / 10000) * _feeBp;
        uint256 adjustedAmount = amount - fee;
        // for now we just leave fee in contract balance
        erc20.transfer(recipient, adjustedAmount);
        uint256 currentBalance = erc20.balanceOf(address(this));
        uint256 difference = currentBalance - previousBalance;
        require(difference == adjustedAmount, "hToken: incorrect new balance");
        ERC20Holograph(holographer()).sourceBurn(msgSender, amount);
        emit Withdrawal(token, recipient, adjustedAmount);
    }

    function availableNativeTokens(address/* msgSender*/) external view onlyHolographer returns (uint256) {
        if (IHolographer(holographer()).getOriginChain() == IHolograph(0x20202020486f6c6f677261706841646472657373).getChainType()) {
            return address(this).balance;
        } else {
            return 0;
        }
    }

    function availableWrappedTokens(address/* msgSender*/, address token) external view onlyHolographer returns (uint256) {
        require(_supportedWrappers[token], "hToken: unsupported token type");
        return ERC20(token).balanceOf(address(this));
    }

    function test(address msgSender) external view onlyHolographer returns (string memory) {
        return string(abi.encodePacked("hToken works!\nmgs.sender == ", Strings.toHexString(msgSender)));
    }

    function updateSupportedWrapper(address msgSender, address token, bool supported) external onlyHolographer onlyOwner(msgSender) {
        _supportedWrappers[token] = supported;
    }

}
