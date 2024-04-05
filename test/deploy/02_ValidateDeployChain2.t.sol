// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Test, Vm, console} from "forge-std/Test.sol";
// import {HolographInterfaces} from "../../../contracts/HolographInterfaces.sol";
// import {Holographer} from "../../../contracts/HolographInterfaces.sol";
import {MyContractTest} from "../TestSetup.t.sol";
import {Constants} from "../utils/Constants.sol";

contract ValidateDeployChain2 is Test {
  uint256 localHost2Fork;
  string LOCALHOST2_RPC_URL = vm.envString("LOCALHOST2_RPC_URL");

  // HolographInterfaces public holographInterfaces;

  function setUp() public {
    // super.setUp();
    localHost2Fork = vm.createFork(LOCALHOST2_RPC_URL);
    vm.selectFork(localHost2Fork);
    // holographInterfaces = new HolographInterfaces();
  }

  function testSelectFork() public {
    assertEq(vm.activeFork(), localHost2Fork);
  }

  // function testHolographInterfaces() public {
  //   bytes memory bytecode = abi.encodePacked(
  //     vm.getCode("HolographInterfaces.sol:HolographInterfaces"),
  //     holographInterfaces
  //   );

  //   address IholographAddress;
  //   assembly {
  //     IholographAddress := create(0, add(bytecode, 0x20), mload(bytecode))
  //   }
  //   bytes memory bytecodeDeployed = vm.getDeployedCode("HolographInterfaces.sol:HolographInterfaces");
  //   assertEq0(IholographAddress.code, bytecodeDeployed);
  // }

  // function testHolographInterfaces2() public {
  //   bytes memory bytecodeDeployed = vm.getDeployedCode("HolographInterfaces.sol:HolographInterfaces");
  //   assertEq(address(holographInterfaces).code, bytecodeDeployed);
  // }

  function testHolograph() public {
    // Holographer holographer = new Holographer();
    bytes memory bytecodeDeployed = vm.getDeployedCode("Holograph.sol:Holograph");
    assertEq(address(Constants.getHolograph()).code, bytecodeDeployed);
  }

}
