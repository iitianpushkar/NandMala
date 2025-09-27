// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PTYT {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    address public minter;
    bool private initialized;

    function initialize(string memory _name, string memory _symbol) external {
        require(!initialized, "Already initialized");
        initialized = true;
        name = _name;
        symbol = _symbol;
    }

    function setMinter(address _minter) external {
        require(minter == address(0), "Minter already set");
        minter = _minter;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "Not minter");
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == minter, "Not minter");
        require(balanceOf[from] >= amount, "Insufficient balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
}
