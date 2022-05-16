// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

             - one bridge, infinite possibilities -


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

pragma solidity 0.8.12;

import "../abstract/Initializable.sol";

import "../interface/HolographedERC20.sol";

abstract contract ERC20H is Initializable, HolographedERC20 {

    /*
     * @dev Dummy variable to prevent empty functions from making "switch to pure" warnings.
     */
    bool private _success;

    modifier onlyHolographer() {
        require(msg.sender == holographer(), "holographer only function");
        _;
    }

    /**
     * @notice Constructor is empty and not utilised.
     * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
     */
    constructor() {}

    /**
     * @notice Initializes the collection.
     * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
     */
    function init(bytes memory data) external virtual override returns (bytes4) {
        return _init(data);
    }

    function _init(bytes memory/* data*/) internal returns (bytes4) {
        require(!_isInitialized(), "ERC20: already initialized");
        address _holographer = msg.sender;
        assembly {
            sstore(/* slot */0x6e5f8ca8411e7bcc0b4514ebbbdd1e5a67471d01255657bdeed111c1c4204aec, _holographer)
        }
        _setInitialized();
        return IInitializable.init.selector;
    }

    /*
     * @dev Address of Holograph ERC20 standards enforcer smart contract.
     */
    function holographer() internal view returns (address _holographer) {
        assembly {
            _holographer := sload(/* slot */0x6e5f8ca8411e7bcc0b4514ebbbdd1e5a67471d01255657bdeed111c1c4204aec)
        }
    }

    function bridgeIn(uint32/* _chainId*/, address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool) {
        _success = true;
        return true;
    }

    function bridgeOut(uint32/* _chainId*/, address/* _from*/, address/* _to*/, uint256/* _amount*/) external virtual view onlyHolographer returns (bytes memory _data) {
        // just here to prevent "make pure" warning
        _data = abi.encode(holographer());
    }

    function afterApprove(address/* _owner*/, address/* _to*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeApprove(address/* _owner*/, address/* _to*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterOnERC20Received(address/* _token*/, address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeOnERC20Received(address/* _token*/, address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterBurn(address/* _owner*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeBurn(address/* _owner*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterMint(address/* _owner*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeMint(address/* _owner*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _amount*/, bytes calldata/* _data*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function afterTransfer(address/* _from*/, address/* _to*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

    function beforeTransfer(address/* _from*/, address/* _to*/, uint256/* _amount*/) external virtual onlyHolographer returns (bool success) {
        _success = true;
        return _success;
    }

}
