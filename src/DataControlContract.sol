// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract StorkDataControlContract {
    modifier OnlyValidators() {
        require(validators[msg.sender] == true, "Not a validator");
        _;
    }

    mapping (address => bool) public validators;

    function addValidator(address _validator) public OnlyValidators {
        validators[_validator] = true;
    }

}