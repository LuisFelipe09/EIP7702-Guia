// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SameAddress {
    // En esta caso observamos que la dirección del contrato es la misma que la del remitente
    function isSameAddress() public view returns (bool) {
        return address(this) == msg.sender;
    }
}
