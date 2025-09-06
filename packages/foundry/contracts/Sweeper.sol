// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Sweeper {
    event Swept(
        address indexed origin,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /// @notice Sweep multiple tokens from the msg.sender to `to`.
    /// @dev When executed in the context of a delegated EOA (EIP-7702 simulation),
    ///      `msg.sender` will be the EOA and tokens will be transferred without approvals.
    function sweepTokens(
        address[] calldata tokens,
        address to,
        uint256[] calldata amounts
    ) external {
        require(tokens.length == amounts.length, "length mismatch");
        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 amt = amounts[i];
            require(amt > 0, "zero amount");
            bool ok = IERC20(tokens[i]).transfer(to, amt);
            require(ok, "transfer failed");
            emit Swept(msg.sender, tokens[i], to, amt);
        }
    }

    /// @notice Sweep multiple tokens to multiple respective recipients.
    /// @dev tokens.length == tos.length == amounts.length
    function sweepTokensToMany(
        address[] calldata tokens,
        address[] calldata tos,
        uint256[] calldata amounts
    ) external {
        require(
            tokens.length == tos.length && tokens.length == amounts.length,
            "length mismatch"
        );
        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 amt = amounts[i];
            require(amt > 0, "zero amount");
            bool ok = IERC20(tokens[i]).transfer(tos[i], amt);
            require(ok, "transfer failed");
            emit Swept(msg.sender, tokens[i], tos[i], amt);
        }
    }
}
