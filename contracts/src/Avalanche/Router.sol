// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { OAppReceiver, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppReceiver.sol";
import { OAppSender, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import { OAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "./Vault.sol";

contract OApp is OAppSender, OAppReceiver, Ownable {
    struct messageFromHederaToAvalanche {
        string message;   // claim or withdraw
        uint256 amount;
        address user;
    }
    struct messageFromAvalancheToHedera {
        string message;   // deposit or createPool
        uint256 balance;
        address index;
        address pool;
    }

    using OptionsBuilder for bytes;

    Vault public vault;

    /// Execution options (500k gas, 0 value)
    bytes public _options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(500000, 0);

    event MessageSent(uint32 dstEid);
    event MessageReceived(uint32 senderEid, bytes32 sender, uint64 nonce);

    /// Hardcoded LayerZero endpoint for Avalanche
    address public constant ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f; // put actual endpoint

    constructor() 
        OAppCore(ENDPOINT, msg.sender) 
        Ownable(msg.sender) 
    {}

    function setVault(address _vault) external onlyOwner {
        vault = Vault(_vault);
    }

    /// Receiver
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata message,
        address /*executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        messageFromHederaToAvalanche memory data = abi.decode(message, (messageFromHederaToAvalanche));
        emit MessageReceived(_origin.srcEid, _origin.sender, _origin.nonce);

        vault.withdraw(data.amount, data.to);
    }

    /// Sender
    function send(
        uint32 _dstEid,
        messageFromAvalancheToHedera memory _message
    ) external payable {
        bytes memory _encodedMessage = abi.encode(_message);
        _lzSend(
            _dstEid,
            _encodedMessage,
            _options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );

        emit MessageSent( _dstEid);
    }

    function quote(
        uint32 _dstEid,
        messageFromAvalancheToHedera memory _message,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(_message);
        fee = _quote(_dstEid, payload, _options, _payInLzToken);
    }

    /// Explicitly override oAppVersion
    function oAppVersion() 
        public 
        view 
        override(OAppReceiver, OAppSender) 
        returns (uint64 senderVersion, uint64 receiverVersion) 
    {
        (uint64 parentSenderVersion,) = OAppSender.oAppVersion();
        (,uint64 parentReceiverVersion) = OAppReceiver.oAppVersion();
        senderVersion = parentSenderVersion;
        receiverVersion = parentReceiverVersion;
    }
}
