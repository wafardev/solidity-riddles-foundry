// SPDX-License-Identifier: MIT

import {Test, console} from "forge-std/Test.sol";
import {CollateralToken} from "../src/FlashLoanCTF/CollateralToken.sol";
import {AMM} from "../src/FlashLoanCTF/AMM.sol";
import {Lending} from "../src/FlashLoanCTF/Lending.sol";
import {FlashLender} from "../src/FlashLoanCTF/Flashloan.sol";

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

    function testFlashLoan() public {}
}
