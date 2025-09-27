// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./PTYT.sol";

contract Pool {
    PTYT public pt;
    PTYT public yt;
    bool private initialized;

    uint256 public reserveNormalizedIncome;

    struct UserState {
        uint256 scaledBalance;
        uint256 userIndex;
    }

    mapping(address => UserState) public userState;
    mapping(address => uint256) public pendingyield;

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

    function updateReserveNormalizedIncome(uint256 _reserveNormalizedIncome) external returns (uint256) {

        reserveNormalizedIncome = _reserveNormalizedIncome;
        return reserveNormalizedIncome; // update from an oracle server
    }

    function claimableYield(address user) external view returns (uint256) {
        UserState memory state = userState[user];
        uint256 yieldAccrued = (state.scaledBalance) * (reserveNormalizedIncome - state.index);
        return pending[user] + yieldAccrued;
    }

    function claim() external {
        UserState memory state = userState[msg.sender];
        uint256 yieldAccrued = (state.scaledBalance) * (reserveNormalizedIncome - state.userIndex);
        uint256 amountToClaim = pending[msg.sender] + yieldAccrued;

        require(amountToClaim > 0, "No yield to claim");

        pending[msg.sender] = 0;
        state.userIndex = reserveNormalizedIncome;

        // Transfer the yield to the user
        
    }

    function sendYT(address to, uint256 amount) external {

        UserState memory state = userState[msg.sender];
        uint256 yieldAccrued = (state.scaledBalance) * (reserveNormalizedIncome - state.index);
        pending[msg.sender] += yieldAccrued;
        state.index = reserveNormalizedIncome;

        userState[to] = UserState({
            scaledBalance: userState[to].scaledBalance + (amount / reserveNormalizedIncome),
            index: reserveNormalizedIncome
        });

        // User sends YT to the anyone
   }

   

   
}