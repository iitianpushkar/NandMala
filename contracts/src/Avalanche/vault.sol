// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Router.sol";
import { MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";

interface IaToken {
    function scaledBalanceOf(address user) external view returns (uint256);
    function POOL() external view returns (address);
}

interface IAavePool {
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function getReserveNormalizedIncome(address asset) external view returns (uint256);
}

contract Vault {
    using SafeERC20 for IERC20;

    struct messageFromAvalancheToHedera {
        string message; 
        uint256 balance;
        uint256 index;
        address pool;
    }

    address public owner;
    IERC20 public immutable token; // aAvaUSDC
    uint256 public rawBalance;

    OApp public oapp;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    /// Hardcoded aToken
    address public constant ATOKEN = 0xb1c85310a1b809C70fA6806d27Da425C1261F801;

    constructor(address _oapp) {
        owner = msg.sender;
        token = IERC20(ATOKEN);
        oapp = OApp(_oapp);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function deposit(uint256 amount, address _pool) external payable {
        require(amount > 0, "Deposit amount must be greater than zero");

        messageFromAvalancheToHedera memory message = messageFromAvalancheToHedera({
            message: "deposit",
            balance: amount,
            index: IAavePool(IaToken(ATOKEN).POOL()).getReserveNormalizedIncome(ATOKEN),
            pool: _pool
        });

        MessagingFee memory fee = oapp.quote(40285, message, false);
        require(msg.value >= fee.nativeFee, "Insufficient msg.value for fee");

        token.safeTransferFrom(msg.sender, address(this), amount);
        rawBalance += amount;

        oapp.send{value: msg.value}(40285, message);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount, address to) external {
        require(msg.sender == address(oapp), "Only router can call");

        IAavePool(IaToken(ATOKEN).POOL()).withdraw(ATOKEN, amount, to);
        rawBalance -= amount;

        emit Withdraw(to, amount);
    }

    function scaledBalance() external view returns (uint256) {
        return IaToken(ATOKEN).scaledBalanceOf(address(this));
    }
}
