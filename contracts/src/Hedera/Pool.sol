// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./PTYT.sol";
import "./getReserveNormalizedIncome.sol";

contract Pool {
    PTYT public pt;
    PTYT public yt;
    bool private initialized;
    getReserveNormalizedIncome public reserveNIContract;


    

    struct UserState {
        uint256 scaledBalance;
        uint256 userIndex;
    }

    function getReserveNI() external view returns (uint256) {

        return reserveNIContract.getReserveNI();

    }

    mapping(address => UserState) public userState;
    mapping(address => uint256) public pendingYield;

    uint256 public totalScaledSupply;

    function initialize(address _pt, address _yt) external {
        require(!initialized, "Already initialized");
        initialized = true;

        pt = PTYT(_pt);
        yt = PTYT(_yt);
    }

    function mintTokens(address to, uint256 amount) external {
        pt.mint(to, amount);
        yt.mint(to, amount);
    }

    function claimableYield(address user) external view returns (uint256) {
        UserState memory state = userState[user];
        uint256 yieldAccrued = (state.scaledBalance) * (reserveNormalizedIncome - state.userIndex);
        return pendingYield[user] + yieldAccrued;
    }

    function claim() external {
        UserState memory state = userState[msg.sender];
        uint256 yieldAccrued = (state.scaledBalance) * (reserveNormalizedIncome - state.userIndex);
        uint256 amountToClaim = pendingYield[msg.sender] + yieldAccrued;

        require(amountToClaim > 0, "No yield to claim");

        pendingYield[msg.sender] = 0;
        state.userIndex = reserveNormalizedIncome;

        // Transfer the yield to the user
        
    }

    function sendYT(address to, uint256 amount) external {

        UserState memory state = userState[msg.sender];
        uint256 yieldAccrued = (state.scaledBalance) * (reserveNormalizedIncome - state.userIndex);
        pendingYield[msg.sender] += yieldAccrued;
        state.userIndex = reserveNormalizedIncome;

        userState[to] = UserState({
            scaledBalance: userState[to].scaledBalance + (amount / reserveNormalizedIncome),
            userIndex: reserveNormalizedIncome
        });

        // User sends YT to the anyone
   }

   

   
}