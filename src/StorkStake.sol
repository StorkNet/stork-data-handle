// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract StorkFund {
    
    struct StorkClient {
        uint256 funds;
        uint8 txLeft;
        bool isActive;
    }
    
    mapping(address => StorkClient) public storkClients;
}