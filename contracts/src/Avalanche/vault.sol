// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

contract vault {

    address public owner;
    uint256 public balance;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
        balance = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= balance, "Insufficient balance in vault");
        balance -= amount;
        payable(owner).transfer(amount);
        emit Withdraw(owner, amount);
    }
}