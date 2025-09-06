// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../contracts/MockERC20.sol";
import {Dapp} from "../contracts/Dapp.sol";
import {Batcher} from "../contracts/Batcher.sol";

contract BatcherTest is Test {
    MockERC20 public token;
    Dapp public dapp;
    Batcher public batcher;

    address BOB_ADDRESS = vm.addr(0xB0B);
    uint256 BOB_PK = 0xB0B;

    function setUp() public {
        token = new MockERC20();
        dapp = new Dapp();
        batcher = new Batcher();

        // Fund Bob with tokens
        token.mint(BOB_ADDRESS, 1 ether);

        // Fund Bob with ETH for txs
        vm.deal(BOB_ADDRESS, 1 ether);
    }

    function testBatchApproveAndDeposit() public {
        uint256 amount = 0.5 ether;

        // Simulate EIP-7702 delegation: Bob authorizes `batcher` implementation
        vm.signAndAttachDelegation(address(batcher), BOB_PK);

        vm.startPrank(BOB_ADDRESS);
        // Call the batcher via the delegated EOA address so the implementation runs in the EOA context
        Batcher(BOB_ADDRESS).batchApproveAndDeposit(
            address(token),
            address(dapp),
            amount
        );
        vm.stopPrank();

        // Verify dapp received tokens
        uint256 received = dapp.received(address(token));
        assertEq(received, amount);

        // Verify balances: Bob's token balance decreased
        assertEq(token.balanceOf(BOB_ADDRESS), (1 ether - amount));
    }
}
