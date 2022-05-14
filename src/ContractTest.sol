// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ContractTest {
    
    modifier OnlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    address payable private owner;
    address payable immutable dataControlContract;
    
    bytes constant createContract = abi.encodeWithSignature("addStorkContract()");
    bytes private fundContract = abi.encodeWithSignature("fundStorkContract(address)", address(this));

    constructor(address payable _dataControlAddr) payable {
        dataControlContract = _dataControlAddr;
        (bool sent, ) = dataControlContract.call{value: msg.value}(createContract);
        require(sent, "Failed to send Ether");
    }
    
    function contractFunding() external payable {
        (bool sent, ) = dataControlContract.call{value: msg.value}(fundContract);
        require(sent, "Failed to fund contract");
    }

    function getBalance(address addr) public view returns (uint) {
        return addr.balance;
    }
}