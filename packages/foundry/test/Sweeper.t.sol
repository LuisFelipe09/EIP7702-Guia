// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../contracts/MockERC20.sol";
import {Sweeper} from "../contracts/Sweeper.sol";

contract SweeperTest is Test {
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    Sweeper public sweeper;

    address BOB_ADDRESS = vm.addr(0xB0B);
    uint256 BOB_PK = 0xB0B;
    address RECEIVER = vm.addr(0xC0C);

    function setUp() public {
        tokenA = new MockERC20();
        tokenB = new MockERC20();
        sweeper = new Sweeper();

        tokenA.mint(BOB_ADDRESS, 1000);
        tokenB.mint(BOB_ADDRESS, 2000);
    }

    function testSweepMultipleTokens() public {
        address[] memory tokens = new address[](2);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        // Bob delegates to sweeper
        vm.signAndAttachDelegation(address(sweeper), BOB_PK);

        vm.startPrank(BOB_ADDRESS);
        // Call via the EOA address so the implementation runs in EOA context
        Sweeper(BOB_ADDRESS).sweepTokens(tokens, RECEIVER, amounts);
        vm.stopPrank();

        // Check balances
        assertEq(tokenA.balanceOf(RECEIVER), amounts[0]);
        assertEq(tokenB.balanceOf(RECEIVER), amounts[1]);
        assertEq(tokenA.balanceOf(BOB_ADDRESS), 1000 - amounts[0]);
        assertEq(tokenB.balanceOf(BOB_ADDRESS), 2000 - amounts[1]);
    }

    function testSweepToMultipleDestinations() public {
        // Prepare three tokens and three recipients
        MockERC20 tokenC = new MockERC20();
        tokenA.mint(BOB_ADDRESS, 500);
        tokenB.mint(BOB_ADDRESS, 500);
        tokenC.mint(BOB_ADDRESS, 500);

        address[] memory tokens = new address[](3);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);
        tokens[2] = address(tokenC);

        address[] memory tos = new address[](3);
        tos[0] = vm.addr(0xD0D);
        tos[1] = vm.addr(0xE0E);
        tos[2] = vm.addr(0xF0F);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10;
        amounts[1] = 20;
        amounts[2] = 30;

        vm.signAndAttachDelegation(address(sweeper), BOB_PK);

        vm.startPrank(BOB_ADDRESS);
        Sweeper(BOB_ADDRESS).sweepTokensToMany(tokens, tos, amounts);
        vm.stopPrank();

        assertEq(MockERC20(tokens[0]).balanceOf(tos[0]), amounts[0]);
        assertEq(MockERC20(tokens[1]).balanceOf(tos[1]), amounts[1]);
        assertEq(MockERC20(tokens[2]).balanceOf(tos[2]), amounts[2]);
    }
}
