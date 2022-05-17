// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./StorkHandler.sol";

/// @title Demo Contract
/// @author Shankar "theblushirtdude" Subramanian
/// @notice Honestly idk what this is for
/// @dev Explain to a developer any extra details
contract Test is StorkHandler {
    struct Student {
        string name;
        uint256 age;
        bool isMale;
    }

    constructor(address payable _dataControlAddr) payable {
        setDataControlConractAddr(_dataControlAddr);
        (bool success, ) = dataControlContract.call{value: msg.value}(
            abi.encodeWithSignature("addStorkContract()")
        );
        require(success, "Failed to add stork contract");
    }

    function storeStudentData(
        string calldata _name,
        uint256 _age,
        bool _isMale
    ) public {
        indexStorkStore(
            0,
            abi.encode(Student({name: _name, age: _age, isMale: _isMale}))
        );
    }

    function increaseAgeByOne(bytes calldata _data) public {
        Student memory student = abi.decode(_data, (Student));
        student.age++;

        bytesStorkStore(dataTypes[0], abi.encode(student));
    }

    function decodeStudent(bytes calldata _data)
        public
        pure
        returns (Student memory)
    {
        return (abi.decode(_data, (Student)));
    }
}
