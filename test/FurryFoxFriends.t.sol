// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {FurryFoxFriends} from "../src/FurryFoxFriends.sol";

pragma solidity ^0.8.0;

contract FurryFoxFriendsTest is Test {
    FurryFoxFriends furryFoxFriends;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.startPrank(victim);
        furryFoxFriends = new FurryFoxFriends();
        vm.stopPrank();
        vm.deal(attacker, 1 ether);
    }

    function testFurryFoxFriends() public {
        bytes32[] memory proof = new bytes32[](0);
        bytes32 leaf = bytes32(0);
        assertEq(furryFoxFriends.balanceOf(attacker), 0);

        vm.prank(attacker);
        furryFoxFriends.presaleMint(proof, leaf);
        assert(furryFoxFriends.balanceOf(attacker) >= 1);
    }
}
