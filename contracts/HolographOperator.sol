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
import "./interface/IHolographOperator.sol";
import "./interface/IHolographRegistry.sol";
import "./interface/IInitializable.sol";
import "./interface/IHolographInterfaces.sol";
import "./interface/ILayerZeroEndpoint.sol";
import "./interface/Ownable.sol";

import "./struct/OperatorJob.sol";

/**
 * @dev This smart contract contains the actual core operator logic.
 */
contract HolographOperator is Admin, Initializable, IHolographOperator {
  bytes32 constant _bridgeSlot = 0xeb87cbb21687feb327e3d58c6c16d552231d12c7a0e8115042a4165fac8a77f9;
  bytes32 constant _interfacesSlot = 0xbd3084b8c09da87ad159c247a60e209784196be2530cecbbd8f337fdd1848827;
  bytes32 constant _jobNonceSlot = 0x1cda64803f3b43503042e00863791e8d996666552d5855a78d53ee1dd4b3286d;
  bytes32 constant _lZEndpointSlot = 0x56825e447adf54cdde5f04815fcf9b1dd26ef9d5c053625147c18b7c13091686;
  bytes32 constant _registrySlot = 0xce8e75d5c5227ce29a4ee170160bb296e5dea6934b80a9bd723f7ef1e7c850e7;
  bytes32 constant _utilityTokenSlot = 0xbf76518d46db472b71aa7677a0908b8016f3dee568415ffa24055f9a670f9c37;

  /**
   * @dev Internal number (in seconds), used for defining a window for operator to execute the job.
   */
  uint256 private _blockTime;

  /**
   * @dev Minimum amount of tokens needed for bonding.
   */
  uint256 private _baseBondAmount;

  /**
   * @dev The multiplier used for calculating bonding amount for pods.
   */
  uint256 private _podMultiplier;

  /**
   * @dev The threshold used for limiting number of operators in a pod.
   */
  uint256 private _operatorThreshold;

  /**
   * @dev The threshold step used for increasing bond amount once threshold is reached.
   */
  uint256 private _operatorThresholdStep;

  /**
   * @dev The threshold divisor used for increasing bond amount once threshold is reached.
   */
  uint256 private _operatorThresholdDivisor;

  /**
   * @dev Internal mapping of operator job details for a specific job hash.
   */
  mapping(bytes32 => uint256) private _operatorJobs;

  /**
   * @dev Internal mapping of operator addresses, used for temp storage when defining an operator job.
   */
  mapping(uint256 => address) private _operatorTempStorage;

  /**
   * @dev Internal index used for storing/referencing operator temp storage.
   */
  uint32 private _operatorTempStorageCounter;

  /**
   * @dev Multi-dimensional array of available operators.
   */
  address[][] private _operatorPods;

  /**
   * @dev Internal mapping of bonded operators, to prevent double bonding.
   */
  mapping(address => uint256) private _bondedOperators;

  /**
   * @dev Internal mapping of bonded operators, to prevent double bonding.
   */
  mapping(address => uint256) private _operatorPodIndex;

  /**
   * @dev Internal mapping of bonded operator amounts.
   */
  mapping(address => uint256) private _bondedAmounts;

  modifier onlyBridge() {
    require(msg.sender == _bridge(), "HOLOGRAPH: bridge only call");
    _;
  }

  /**
   * @dev Allow calls only from LayerZero endpoint contract.
   */
  modifier onlyLZ() {
    assembly {
      // check if lzEndpoint
      switch eq(sload(_lZEndpointSlot), caller())
      case 0 {
        // check if operator is calling self, used for job estimations
        switch eq(address(), caller())
        case 0 {
          mstore(0x80, 0x08c379a000000000000000000000000000000000000000000000000000000000)
          mstore(0xa0, 0x0000002000000000000000000000000000000000000000000000000000000000)
          mstore(0xc0, 0x0000001b484f4c4f47524150483a204c5a206f6e6c7920656e64706f696e7400)
          mstore(0xe0, 0x0000000000000000000000000000000000000000000000000000000000000000)
          revert(0x80, 0xc4)
        }
      }
    }
    _;
  }

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract.
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract.
   */
  function init(bytes memory data) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address bridge, address interfaces, address registry, address utilityToken) = abi.decode(
      data,
      (address, address, address, address)
    );
    assembly {
      sstore(_adminSlot, origin())
      sstore(_bridgeSlot, bridge)
      sstore(_interfacesSlot, interfaces)
      sstore(_registrySlot, registry)
      sstore(_utilityTokenSlot, utilityToken)
    }
    _blockTime = 10; // 10 blocks allowed for execution
    unchecked {
      _baseBondAmount = 100 * (10**18); // one single token unit * 100
    }
    // how much to increase bond amount per pod
    _podMultiplier = 2; // 1, 4, 16, 64
    // starting pod max amount
    _operatorThreshold = 1000;
    // how often to increase price per each operator
    _operatorThresholdStep = 10;
    // we want to multiply by decimals, but instead will have to divide
    _operatorThresholdDivisor = 100; // == * 0.01
    // set first operator for each pod as zero address
    _operatorPods = [[address(0)]];
    // mark zero address as bonded operator, to prevent abuse
    _bondedOperators[address(0)] = 1;
    _setInitialized();
    return IInitializable.init.selector;
  }

  function lzReceive(
    uint16, /* _srcChainId*/
    bytes calldata _srcAddress,
    uint64, /* _nonce*/
    bytes calldata _payload
  ) external payable onlyLZ {
    assembly {
      let ptr := mload(0x40)
      calldatacopy(add(ptr, 0x0c), _srcAddress.offset, _srcAddress.length)
      switch eq(mload(ptr), address())
      case 0 {
        mstore(0x80, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        mstore(0xa0, 0x0000002000000000000000000000000000000000000000000000000000000000)
        mstore(0xc0, 0x0000001e484f4c4f47524150483a20756e617574686f72697a65642073656e64)
        mstore(0xe0, 0x6572000000000000000000000000000000000000000000000000000000000000)
        revert(0x80, 0xc4)
      }
    }
    // would be a good idea to check payload gas price here and if it is significantly lower than current amount, to set zero address as operator to not lock-up an operator unnecessarily
    unchecked {
      bytes32 jobHash = keccak256(_payload);
      ++_operatorTempStorageCounter;
      // use job hash, job nonce, block number, and block timestamp for generating a random number
      uint256 random = uint256(keccak256(abi.encodePacked(jobHash, _jobNonce(), block.number, block.timestamp)));
      // divide by total number of pods, use modulus/remainder
      uint256 pod = random % _operatorPods.length;
      // identify the total number of available operators in pod
      uint256 podSize = _operatorPods[pod].length;
      // select a primary operator
      uint256 operatorIndex = random % podSize;
      // If operator index is 0, then it's open season! Anyone can execute this job. First come first serve.
      // pop operator to ensure that they cannot be selected for any other job until this one completes
      // decrease pod size to accomodate popped operator
      _operatorTempStorage[_operatorTempStorageCounter] = _operatorPods[pod][operatorIndex];
      _popOperator(pod, operatorIndex);
      if (podSize > 1) {
        podSize--;
      }
      _operatorJobs[jobHash] = uint256(
        ((pod + 1) << 248) |
          (uint256(_operatorTempStorageCounter) << 216) |
          (block.number << 176) |
          (_RBH(random, podSize, 1) << 160) |
          (_RBH(random, podSize, 2) << 144) |
          (_RBH(random, podSize, 3) << 128) |
          (_RBH(random, podSize, 4) << 112) |
          (_RBH(random, podSize, 5) << 96) |
          (block.timestamp << 16) |
          0
      ); // 80 next available bit position && so far 176 bits used with only 128 left
      emit AvailableOperatorJob(jobHash, _payload);
    }
  }

  function executeJob(bytes calldata _payload) external payable {
    // we do our operator logic here
    // we will also manage gas/value here
    bytes32 hash = keccak256(_payload);
    require(_operatorJobs[hash] > 0, "HOLOGRAPH: invalid job");
    uint256 gasLimit = 0;
    uint256 gasPrice = 0;
    assembly {
      gasLimit := calldataload(sub(add(_payload.offset, _payload.length), 0x40))
      gasPrice := calldataload(sub(add(_payload.offset, _payload.length), 0x20))
    }
    OperatorJob memory job = getJobDetails(hash);
    // first check if not default operator, or if zero address operator selected
    if (job.operator != address(0)) {
      uint256 pod = job.pod - 1;
      if (job.operator != msg.sender) {
        // we are at a point where operator failed to execute
        // then check if time is still within limits
        uint256 elapsedTime = block.timestamp - uint256(job.startTimestamp);
        uint256 timeDifference = elapsedTime / job.blockTimes;
        require(timeDifference > 0, "HOLOGRAPH: operator has time");
        // at this point an operator failed to execute in given amount of time
        // we need to check if gas price was a variable
        require(gasPrice >= tx.gasprice, "HOLOGRAPH: gas spike detected");
        // we now need to check if next operator is allowed
        if (timeDifference < 6) {
          uint256 podIndex = uint256(job.fallbackOperators[timeDifference - 1]);
          // do a quick sanity check to make sure operator did not leave from index and does not result in revert
          if (podIndex < _operatorPods[pod].length) {
            // only do check if it is valid, otherwise allow anyone to do this
            address fallbackOperator = _operatorPods[pod][podIndex];
            require(fallbackOperator == msg.sender || fallbackOperator == address(0), "HOLOGRAPH: invalid fallback");
          }
        }
        // reward the current operator
        uint256 amount = _getBaseBondAmount(pod);
        // this is where we slash default operator for missing the job
        // for simplicity at this point, slashing pod base fee
        _bondedAmounts[job.operator] -= amount;
        // amount gets sent to msg.sender
        _bondedAmounts[msg.sender] += amount;
        uint256 currentBondAmount = _getCurrentBondAmount(pod);
        // check leftover bonded amount
        if (currentBondAmount >= _bondedAmounts[job.operator]) {
          // if enough bond amount leftover, put operator back in
          _operatorPods[pod].push(job.operator);
          _operatorPodIndex[job.operator] = _operatorPods[pod].length - 1;
          _bondedOperators[job.operator] = job.pod;
        } else {
          // return rest of bond amount to operator
          // and do not re-instate the operator
          // ... for now we just make that number disappear
          _bondedAmounts[job.operator] = 0;
        }
      } else {
        // put operator back in
        _operatorPods[pod].push(msg.sender);
        _operatorPodIndex[job.operator] = _operatorPods[pod].length - 1;
        _bondedOperators[msg.sender] = job.pod;
      }
    }
    //// we need to decide on a reward for operating here
    // uint256 reward = ???;
    //// operator gets sent the reward
    // _bondedOperators[msg.sender] += reward;
    // check that we have enough gas from operator to execute
    require(gasleft() > gasLimit, "HOLOGRAPH: not enough gas left");
    // now execute job
    assembly {
      calldatacopy(0, _payload.offset, sub(_payload.length, 0x40))
      let result := call(gasLimit, sload(_bridgeSlot), callvalue(), 0, sub(_payload.length, 0x40), 0, 0)
      if eq(result, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
    delete _operatorJobs[hash];
  }

  function jobEstimator(bytes calldata _payload) external payable returns (uint256) {
    assembly {
      calldatacopy(0, _payload.offset, sub(_payload.length, 0x40))
      // we purposefully trigger a revert to be made
      mstore8(0xE3, 0x00)
      let result := call(gas(), sload(_bridgeSlot), callvalue(), 0, sub(_payload.length, 0x40), 0, 0)
      // we purposefully revert if for some reason the call went through still
      if eq(result, 1) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
      mstore(0x00, gas())
      return(0x00, 0x20)
    }
  }

  /*
   * @dev Need to add an extra function to get LZ gas amount needed for their internal cross-chain message verification
   */
  function send(
    uint256 gasLimit,
    uint256 gasPrice,
    uint32 toChain,
    address msgSender,
    bytes calldata _payload
  ) external payable onlyBridge {
    ILayerZeroEndpoint lZEndpoint;
    assembly {
      lZEndpoint := sload(_lZEndpointSlot)
    }
    // need to recalculate the gas amounts for LZ to deliver message
    lZEndpoint.send{value: msg.value}(
      uint16(_interfaces().getChainId(ChainIdType.HOLOGRAPH, uint256(toChain), ChainIdType.LAYERZERO)),
      abi.encodePacked(address(this), address(this)),
      abi.encodePacked(_payload, gasLimit, gasPrice),
      payable(msgSender),
      address(this),
      abi.encodePacked(uint16(1), uint256(52000 + (_payload.length * 25)))
    );
  }

  function getJobDetails(bytes32 jobHash) public view returns (OperatorJob memory) {
    uint256 packed = _operatorJobs[jobHash];
    return
      OperatorJob(
        uint8(packed >> 248),
        uint16(_blockTime),
        _operatorTempStorage[uint32(packed >> 216)],
        uint40(packed >> 176),
        // TODO: move the bit-shifting around to have it be sequential
        uint64(packed >> 16),
        [
          uint16(packed >> 160),
          uint16(packed >> 144),
          uint16(packed >> 128),
          uint16(packed >> 112),
          uint16(packed >> 96)
        ]
      );
  }

  function getPodOperators(uint256 pod) external view returns (address[] memory operators) {
    require(_operatorPods.length >= pod, "HOLOGRAPH: pod does not exist");
    operators = _operatorPods[pod - 1];
  }

  function getPodOperators(
    uint256 pod,
    uint256 index,
    uint256 length
  ) external view returns (address[] memory operators) {
    require(_operatorPods.length >= pod, "HOLOGRAPH: pod does not exist");
    // decrease by one for easy code usage
    pod--;
    uint256 supply = _operatorPods[pod].length;
    if (index + length > supply) {
      length = supply - index;
    }
    operators = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      operators[i] = _operatorPods[pod][index + i];
    }
  }

  function getPodBondAmount(uint256 pod) external view returns (uint256 base, uint256 current) {
    base = _getBaseBondAmount(pod - 1);
    current = _getCurrentBondAmount(pod - 1);
  }

  function getBondedPod(address operator) external view returns (uint256 pod) {
    return _bondedOperators[operator];
  }

  // add top-up option

  function bondUtilityToken(
    address operator,
    uint256 amount,
    uint256 pod
  ) external {
    require(_bondedOperators[operator] == 0, "HOLOGRAPH: operator is bonded");
    unchecked {
      uint256 current = _getCurrentBondAmount(pod - 1);
      require(current <= amount, "HOLOGRAPH: bond amount too small");
      // subtract difference and only keep bond amount
      if (_operatorPods.length < pod) {
        for (uint256 i = _operatorPods.length; i <= pod; i++) {
          _operatorPods.push([address(0)]);
        }
      }
      require(_operatorPods[pod - 1].length < type(uint16).max, "HOLOGRAPH: too many operators");
      // we extract utility token amount from msg sender
      require(_utilityToken().transferFrom(msg.sender, address(this), amount), "HOLOGRAPH: token transfer failed");
      _operatorPods[pod - 1].push(operator);
      _operatorPodIndex[operator] = _operatorPods[pod - 1].length - 1;
      _bondedOperators[operator] = pod;
      _bondedAmounts[operator] = amount;
    }
  }

  function unbondUtilityToken(address operator, address recipient) external {
    require(_bondedOperators[operator] != 0, "HOLOGRAPH: operator not bonded");
    if (msg.sender != operator) {
      require(_isContract(operator), "HOLOGRAPH: operator not contract");
      // check that operator is ownable contract
      require(Ownable(operator).isOwner(msg.sender), "HOLOGRAPH: sender not owner");
    }
    uint256 amount = _bondedAmounts[operator];
    // here we subtract our fee for unbonding
    require(_utilityToken().transfer(recipient, amount), "HOLOGRAPH: token transfer failed");
    //// we need to track operator pod index for easy removal
    _popOperator(_bondedOperators[operator] - 1, _operatorPodIndex[operator]);
    _bondedOperators[operator] = 0;
    _bondedAmounts[operator] = 0;
  }

  function getLZEndpoint() external view returns (address lZEndpoint) {
    assembly {
      lZEndpoint := sload(_lZEndpointSlot)
    }
  }

  function setLZEndpoint(address lZEndpoint) external onlyAdmin {
    assembly {
      sstore(_lZEndpointSlot, lZEndpoint)
    }
  }

  function getBridge() external view returns (address bridge) {
    assembly {
      bridge := sload(_bridgeSlot)
    }
  }

  function setBridge(address bridge) external onlyAdmin {
    assembly {
      sstore(_bridgeSlot, bridge)
    }
  }

  function getInterfaces() external view returns (address interfaces) {
    assembly {
      interfaces := sload(_interfacesSlot)
    }
  }

  function setInterfaces(address interfaces) external onlyAdmin {
    assembly {
      sstore(_interfacesSlot, interfaces)
    }
  }

  function getRegistry() external view returns (address registry) {
    assembly {
      registry := sload(_registrySlot)
    }
  }

  function setRegistry(address registry) external onlyAdmin {
    assembly {
      sstore(_registrySlot, registry)
    }
  }

  function getUtilityToken() external view returns (address utilityToken) {
    assembly {
      utilityToken := sload(_utilityTokenSlot)
    }
  }

  function setUtilityToken(address utilityToken) external onlyAdmin {
    assembly {
      sstore(_utilityTokenSlot, utilityToken)
    }
  }

  function _bridge() private view returns (address bridge) {
    assembly {
      bridge := sload(_bridgeSlot)
    }
  }

  function _interfaces() private view returns (IHolographInterfaces interfaces) {
    assembly {
      interfaces := sload(_interfacesSlot)
    }
  }

  function _registry() private view returns (address registry) {
    assembly {
      registry := sload(_registrySlot)
    }
  }

  function _utilityToken() private view returns (ERC20Holograph utilityToken) {
    assembly {
      utilityToken := sload(_utilityTokenSlot)
    }
  }

  /**
   * @dev Internal nonce used for randomness.
   *      We increment it on each return.
   */
  function _jobNonce() private returns (uint256 jobNonce) {
    assembly {
      jobNonce := add(sload(_jobNonceSlot), 0x0000000000000000000000000000000000000000000000000000000000000001)
      sstore(_jobNonceSlot, jobNonce)
    }
  }

  function _popOperator(uint256 pod, uint256 operatorIndex) private {
    if (operatorIndex > 0) {
      unchecked {
        address operator = _operatorPods[pod][operatorIndex];
        // remove operator pod reference
        _bondedOperators[operator] = 0;
        _operatorPodIndex[operator] = 0;
        uint256 lastIndex = _operatorPods[pod].length - 1;
        if (lastIndex != operatorIndex) {
          _operatorPods[pod][operatorIndex] = _operatorPods[pod][lastIndex];
        }
        delete _operatorPods[pod][lastIndex];
        _operatorPods[pod].pop();
      }
    }
  }

  function _getBaseBondAmount(uint256 pod) private view returns (uint256) {
    return (_podMultiplier**pod) * _baseBondAmount;
  }

  function _getCurrentBondAmount(uint256 pod) private view returns (uint256) {
    uint256 current = (_podMultiplier**pod) * _baseBondAmount;
    if (_operatorPods.length < pod) {
      return current;
    }
    uint256 threshold = _operatorThreshold / (2**pod);
    uint256 position = _operatorPods[pod].length;
    if (position > threshold) {
      position -= threshold;
      //       current += (current / _operatorThresholdDivisor) * position;
      current += (current / _operatorThresholdDivisor) * (position / _operatorThresholdStep);
    }
    return current;
  }

  function _RBH(
    uint256 random,
    uint256 podSize,
    uint256 n
  ) private view returns (uint256) {
    unchecked {
      return (random + uint256(blockhash(block.number - n))) % podSize;
    }
  }

  function _isContract(address contractAddress) private view returns (bool) {
    bytes32 codehash;
    assembly {
      codehash := extcodehash(contractAddress)
    }
    return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
  }
}
