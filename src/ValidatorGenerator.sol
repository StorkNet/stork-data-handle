// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ValidatorGenerator {
    function getBytes(address _addr) public pure returns (bytes32) {
        return(keccak256(abi.encodePacked(_addr)));
    }

    function getBytesXORString(bytes32 _bytes, address _addr) public pure returns (bytes32) {
        return(_bytes ^ keccak256(abi.encodePacked(_addr)));
    }
}
