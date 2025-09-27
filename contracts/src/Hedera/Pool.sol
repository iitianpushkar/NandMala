// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./PTYT.sol";
import "./Router.sol";

interface ReserveNI {
    function getReserveNI() external view returns (uint256);
}

contract Pool {
    PTYT public pt;
    PTYT public yt;
    bool private initialized;
    OApp public oapp;
    struct messageFromHederaToAvalanche {
        string message;   // claim or withdraw
        uint256 amount;
        address user;
    }

    ReserveNI public reserveNIContract = ReserveNI(0x06d96Fa408Bcd6a4C75C2ffFa3B6cd33666F5926); // put actual getReserveNormalizedIncome address


    struct UserState {
        uint256 scaledBalance;
        uint256 userIndex;
    }

    constructor(address _oapp) {
    oapp = OApp(_oapp);
}

    function _getReserveNI() internal view returns (uint256) {
        return reserveNIContract.getReserveNI();
    }

    function getReserveNI() external view returns (uint256) {
        return _getReserveNI();
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

    function claim() external payable {            // send fee too.
        UserState memory state = userState[msg.sender];
        uint256 yieldAccrued = (state.scaledBalance) * (_getReserveNI() - state.userIndex);
        uint256 amountToClaim = pendingYield[msg.sender] + yieldAccrued;

        require(amountToClaim > 0, "No yield to claim");

        pendingYield[msg.sender] = 0;
        userState[msg.sender].userIndex = _getReserveNI();

        messageFromHederaToAvalanche memory _message = messageFromHederaToAvalanche({
                                        message: "claim",
                                        amount: amountToClaim,
                                        user: msg.sender
                                        });

        MessagingFee memory fee = oapp.quote(40106, _message, false);
        require(msg.value >= fee.nativeFee, "Insufficient msg.value for fee");                                

        oapp.send{value:msg.value}(40106, _message);    
    }

   
}