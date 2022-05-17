// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract DataControlContract {
    function addStorkContract() external payable {}

    function fundStorkContract(address _contractAddr) external payable {}
}

contract ContractTest {
    modifier OnlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    address payable public owner;

    DataControlContract public immutable dataControlContract;

    constructor(address payable _dataControlAddr) payable {
        dataControlContract = DataControlContract(_dataControlAddr);
        dataControlContract.addStorkContract{value: msg.value}();
    }

    function contractFunding() external payable {
        dataControlContract.fundStorkContract{value: msg.value}(address(this));
    }

    function getBalance(address addr) public view returns (uint256) {
        return addr.balance;
    }
}
