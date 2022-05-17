// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TemplateContract {
    address public immutable dataControlContract;

    struct StorkDataType {
        string varType;
        string varName;
        string varValue;
    }

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

    function encodeTypes(StorkDataType[] calldata _data)
        public
        pure
        returns (bytes memory)
    {
        return (abi.encode(_data));
    }

    function decodeTypes(bytes calldata _data)
        public
        pure
        returns (StorkDataType[] memory)
    {
        return (abi.decode(_data, (StorkDataType[])));
    }

    function intStorkStore(uint256 _type, bytes memory _data) internal {
        emit StorkStoreTemplateContract(msg.sender, dataTypes[_type], _data);
    }

    function bytesStorkStore(bytes[] memory _type, bytes memory _data)
        internal
    {
        emit StorkStoreTemplateContract(msg.sender, _type, _data);
    }

    event StorkStoreTemplateContract(
        address indexed _from,
        bytes[] indexed _type,
        bytes _data
    );

    //--------------------------------------------------------------------------------

    struct Student {
        string name;
        uint256 age;
        bool isMale;
    }

    mapping(uint256 => bytes[]) public dataTypes;

    function storeStudentData(
        string calldata _name,
        uint256 _age,
        bool _isMale
    ) public {
        intStorkStore(
            0,
            abi.encode(Student({name: _name, age: _age, isMale: _isMale}))
        );
    }

    function increaseAgeByOne(bytes calldata _data) public {
        Student memory student = abi.decode(_data, (Student));
        student.age++;

        bytesStorkStore(dataTypes[0], abi.encode(student));
    }

    function decode(bytes calldata _data) public pure returns (Student memory) {
        return (abi.decode(_data, (Student)));
    }
}
