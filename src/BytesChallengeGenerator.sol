// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BytesChallengeGenerator {
    function getBytes(address _addr) external pure returns (bytes32) {
        return(keccak256(abi.encodePacked(_addr)));
    }

    function getBytesXORString(bytes32 _bytes, address _addr) external pure returns (bytes32) {
        return(_bytes ^ keccak256(abi.encodePacked(_addr)));
    }
}