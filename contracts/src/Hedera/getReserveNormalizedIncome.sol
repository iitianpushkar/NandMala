// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract getReserveNormalizedIncome {

    uint256 public reserveNormalizedIncome;

    function updateReserveNI(uint256 _reserveNI) external {

        reserveNormalizedIncome = _reserveNI;
    }

    function getReserveNI() external view returns (uint256) {
        return reserveNormalizedIncome;
    }
   
}