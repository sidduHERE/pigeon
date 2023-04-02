// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "./BytesLib.sol";

contract Messages {
  using BytesLib for bytes;

  struct UpdateMessage {
    // unique identifier for this message type
    uint8 payloadID;
    // arbitrary message string
    string message;
  }

  /**
   * @notice Encodes the UpdateMessage struct into bytes
   * @param parsedMessage UpdateMessage struct with arbitrary message
   * @return encodedMessage UpdateMessage encoded into bytes
   */
  function encodeMessage(
    UpdateMessage memory parsedMessage
  ) public pure returns (bytes memory encodedMessage) {
    // Convert message string to bytes so that we can use the .length attribute.
    // The length of the arbitrary messages needs to be encoded in the message
    // so that the corresponding decode function can decode the message properly.
    bytes memory encodedMessagePayload = abi.encodePacked(
      parsedMessage.message
    );

    // return the encoded message
    encodedMessage = abi.encodePacked(
      parsedMessage.payloadID,
      uint16(encodedMessagePayload.length),
      encodedMessagePayload
    );
  }

  /**
   * @notice Decodes bytes into UpdateMessage struct
   * @dev Verifies the payloadID
   * @param encodedMessage encoded arbitrary HelloWorld message
   * @return parsedMessage UpdateMessage struct with arbitrary HelloWorld message
   */
  function decodeMessage(
    bytes memory encodedMessage
  ) public pure returns (UpdateMessage memory parsedMessage) {
    // starting index for byte parsing
    uint256 index = 0;

    // parse and verify the payloadID
    parsedMessage.payloadID = encodedMessage.toUint8(index);
    require(parsedMessage.payloadID == 1, "invalid payloadID");
    index += 1;

    // parse the message string length
    uint256 messageLength = encodedMessage.toUint16(index);
    index += 2;

    // parse the message string
    bytes memory messageBytes = encodedMessage.slice(index, messageLength);
    parsedMessage.message = string(messageBytes);
    index += messageLength;

    // confirm that the message was the expected length
    require(index == encodedMessage.length, "invalid message length");
  }
}