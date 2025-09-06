// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Batcher {
    event BatchExecuted(
        address indexed origin,
        address token,
        address target,
        uint256 amount
    );

    // Convenience: approve the Dapp and then call depositFrom to move tokens from the original signer.
    function batchApproveAndDeposit(
        address token,
        address dapp,
        uint256 amount
    ) external {
        require(amount > 0, "zero amount");
        bool ok = IERC20(token).approve(dapp, amount);
        require(ok, "approve failed");

        // call depositFrom(msg.sender, token, amount)
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("depositFrom(address,address,uint256)")),
            msg.sender,
            token,
            amount
        );
        (bool success, ) = dapp.call(data);
        require(success, "depositFrom failed");

        emit BatchExecuted(msg.sender, token, dapp, amount);
    }
}
