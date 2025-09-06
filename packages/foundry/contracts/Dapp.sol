// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dapp {
    // Track received amounts per token
    mapping(address => uint256) public received;

    event Deposited(
        address indexed from,
        address indexed token,
        uint256 amount
    );

    function deposit(address token, uint256 amount) external {
        require(amount > 0, "zero amount");
        bool ok = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(ok, "transfer failed");
        received[token] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    // Allow an external caller to trigger a transferFrom on behalf of `from`.
    // This is useful when a delegated contract wants to deposit tokens for the original signer.
    function depositFrom(address from, address token, uint256 amount) external {
        require(amount > 0, "zero amount");
        bool ok = IERC20(token).transferFrom(from, address(this), amount);
        require(ok, "transfer failed");
        received[token] += amount;
        emit Deposited(from, token, amount);
    }
}
