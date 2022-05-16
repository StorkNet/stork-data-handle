// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ContractTest {
    modifier OnlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    address payable private owner;
    address payable public immutable dataControlContract;

    string public constant createContract = "addStorkContract()";
    string public constant fundContract = "fundStorkContract(address)";

    constructor(address payable _dataControlAddr) payable {
        dataControlContract = _dataControlAddr;
        (bool sent, ) = _dataControlAddr.call{value: msg.value}(
            abi.encodeWithSignature(createContract)
        );
        require(sent, "Failed to send Ether");
    }

    function contractFunding() external payable {
        (bool sent, ) = dataControlContract.call{value: msg.value}(
            abi.encodeWithSignature(fundContract, "this")
        );
        require(sent, "Failed to fund contract");
    }

    function getBalance(address addr) public view returns (uint256) {
        return addr.balance;
    }
}
