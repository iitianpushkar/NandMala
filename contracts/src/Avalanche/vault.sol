// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault {
    using SafeERC20 for IERC20;

    address public owner;
    IERC20 public immutable token; // aAvaUSDC
    address public router;

    uint256 public balance; // tracked token balance

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    constructor(address _token, address _router) {
        owner = msg.sender;
        token = IERC20(_token);
        router = _router;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == router, "Not the router");
        _;
    }

    /// @notice Deposit aAvaUSDC into the vault
    function deposit(uint256 amount) external {
        require(amount > 0, "Deposit amount must be greater than zero");
        token.safeTransferFrom(msg.sender, address(this), amount);
        balance += amount;
        emit Deposit(msg.sender, amount);
    }

    /// @notice Withdraw tokens to the owner (triggered by router)
    function withdraw(uint256 amount) external onlyRouter {
        require(amount <= balance, "Insufficient balance in vault");
        balance -= amount;
        token.safeTransfer(owner, amount);
        emit Withdraw(owner, amount);
    }
}
