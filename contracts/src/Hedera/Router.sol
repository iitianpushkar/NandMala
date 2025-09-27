// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import { OAppReceiver, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppReceiver.sol";
import {OAppSender, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import { OAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";


contract OApp is OAppSender, OAppReceiver {
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

    event MessageSent(uint32 dstEid);

    /// The _options variable is typically provided as an argument to both the _quote and _lzSend functions.
    /// In this example, we demonstrate how to generate the bytes value for _options and pass it manually.
    /// The OptionsBuilder is used to create new options and add an executor option for LzReceive with specified parameters.
    /// An off-chain equivalent can be found under 'Message Execution Options' in the LayerZero V2 Documentation.
    bytes _options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(500000, 0);


    event MessageReceived(uint32 senderEid, bytes32 sender, uint64 nonce);

    /**
     * @notice Initializes the OApp with the source chain's endpoint address.
     * @param _endpoint The endpoint address.
     */
    /// Hardcoded LayerZero endpoint for Hedera
    address public constant ENDPOINT = 0xbD672D1562Dd32C23B563C989d8140122483631d;

    constructor() 
        OAppCore(ENDPOINT, msg.sender) 
        Ownable(msg.sender) 
    {}
    
    /**
     * @dev Called when the Executor executes EndpointV2.lzReceive. It overrides the equivalent function in the parent OApp contract.
     * Protocol messages are defined as packets, comprised of the following parameters.
     * @param _origin A struct containing information about where the packet came from.
     * _guid A global unique identifier for tracking the packet.
     * @param message Encoded message.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata message,
        address /*executor*/,  // Executor address as specified by the OApp.
        bytes calldata /*_extraData*/  // Any extra data or options to trigger on receipt.
    ) internal override {
        // Decode the payload to get the message
        messageFromAvalancheToHedera memory data = abi.decode(message, (messageFromAvalancheToHedera));
        // Emit the event with the decoded message and sender's EID
        emit MessageReceived(_origin.srcEid, _origin.sender, _origin.nonce);
    }

    function send(
        uint32 _dstEid,
        messageFromHederaToAvalanche memory _message
    ) external payable {
        // Encodes the message before invoking _lzSend.
        bytes memory _encodedMessage = abi.encode(_message);
        _lzSend(
            _dstEid,
            _encodedMessage,
            _options,
            // Fee in native gas and ZRO token.
            MessagingFee(msg.value, 0),
            // Refund address in case of failed source message.
            payable(msg.sender) 
        );

        emit MessageSent(_dstEid);
    }

    function quote(
        uint32 _dstEid,
        messageFromHederaToAvalanche memory _message,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(_message);
        fee = _quote(_dstEid, payload, _options, _payInLzToken);
    }

    // Explicitly override the oAppVersion function from both parents
function oAppVersion() public view override(OAppReceiver, OAppSender) returns (uint64 senderVersion, uint64 receiverVersion) {
    // You can return the versions you want, e.g. same as parents
    (uint64 parentSenderVersion,) = OAppSender.oAppVersion();
    (,uint64 parentReceiverVersion2) = OAppReceiver.oAppVersion(); // ignore sender version
    senderVersion = parentSenderVersion;
    receiverVersion = parentReceiverVersion2; // or parentReceiverVersion
}
}