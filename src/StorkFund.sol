// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract StorkFund {
    
    struct StorkValidator {
        uint256 stakeValue;
        uint256 stakeEndTime;
        uint8 txCount;
        bool isActive;
    }
    
    mapping(address => StorkValidator) public storkValidators;
}