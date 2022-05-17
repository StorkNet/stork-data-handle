// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TemplateContract {
    modifier OnlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    struct Student {
        string name;
        uint256 age;
        bool isMale;
    }

    mapping(address => Student) public students;

    address payable public owner;
    address public immutable dataControlContract;

    constructor(address payable _dataControlAddr) payable {
        dataControlContract = _dataControlAddr;
        (bool success, ) = dataControlContract.call{value: msg.value}(
            abi.encodeWithSignature("addStorkContract()")
        );
        require(success, "Failed to add stork contract");
    }

    function contractFunding() external payable {
        (bool success, ) = dataControlContract.call{value: msg.value}(
            abi.encodeWithSignature("fundStorkContract(address)", this)
        );
        require(success, "Failed to fund contract");
    }

    function txsLeft() public view returns (uint256) {
        (bool success, bytes memory data) = dataControlContract.staticcall(
            abi.encodeWithSignature("txLeftStorkContract(address)", this)
        );
        
        require(success, "Failed to get txs left");
        return (abi.decode(data, (uint256)));
    }



    event StorkStore(address indexed _from, bytes _data);
}
