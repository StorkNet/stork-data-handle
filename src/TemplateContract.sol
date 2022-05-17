// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract DataControlContract {
    function addStorkContract() external payable {}

    function fundStorkContract(address _contractAddr) external payable {}
}

contract TemplateContract {
    modifier OnlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    struct Student {
        string name;
        uint age;
        bool isMale;
    }

    mapping(address => Student) public students;

    address payable public owner;
    DataControlContract public immutable dataControlContract;

    constructor(address payable _dataControlAddr) payable {
        dataControlContract = DataControlContract(_dataControlAddr);
        dataControlContract.addStorkContract{value: msg.value}();
    }

    function contractFunding() external payable {
        dataControlContract.fundStorkContract{value: msg.value}(address(this));
    }



    function txsLeft(address addr) public view returns (uint256) {
        return addr.balance;
    }

    event StorkStore(address indexed _from, bytes _data);
}
