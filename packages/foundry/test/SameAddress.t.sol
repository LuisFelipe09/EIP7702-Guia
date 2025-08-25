// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SameAddress} from "../contracts/sameAddress.sol";

contract SameAddressTest is Test {
    SameAddress public sameAddress;
    address BOB_ADDRESS = vm.addr(0xB0B); // EOA que delega (o actúa como tx.origin)
    uint256 BOB_PK = 0xB0B; // Clave privada para Bob (simulada por Foundry)
    address ALICE_ADDRESS = vm.addr(0xAAA); // EOA que delega (o actúa como tx.origin)
    uint256 ALICE_PK = 0xAAA; // Clave privada para Alice (simulada por Foundry)

    function setUp() public {
        vm.deal(BOB_ADDRESS, 1 ether); // Dar ETH a Bob para las transacciones
        sameAddress = new SameAddress();
    }

    function testIsSameAddress() public {
        vm.signAndAttachDelegation(address(sameAddress), BOB_PK);

        vm.startPrank(BOB_ADDRESS);
        bool result = SameAddress(BOB_ADDRESS).isSameAddress();
        vm.stopPrank();

        assertTrue(result);
    }

    function testDelegateCallIsSameAddress() public {
        vm.signAndAttachDelegation(address(sameAddress), BOB_PK);

        vm.startPrank(ALICE_ADDRESS);
        address contractAddr = address(SameAddress(BOB_ADDRESS));
        bool result = SameAddress(BOB_ADDRESS).isSameAddress();
        bool isContract;
        uint32 size;
        assembly {
            size := extcodesize(contractAddr)
        }
        isContract = size > 0;
        vm.stopPrank();

        assertFalse(result);
        assertTrue(isContract);
    }

    function testDelegateNotIsContract() public {
        vm.signAndAttachDelegation(address(sameAddress), BOB_PK);

        vm.startPrank(ALICE_ADDRESS);

        address result = address(SameAddress(ALICE_ADDRESS));
        bool isContract;
        uint32 size;
        assembly {
            size := extcodesize(result)
        }
        isContract = size > 0;
        vm.stopPrank();

        assertFalse(isContract);
    }
}
