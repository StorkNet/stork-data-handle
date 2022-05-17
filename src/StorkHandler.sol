// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Split this into a separate contract

/// @title Demo Contract
/// @author Shankar "theblushirtdude" Subramanian
/// @notice Honestly idk what this is for
/// @dev Explain to a developer any extra details
contract StorkHandler {
    address public dataControlContract;

    struct StorkDataType {
        string varType;
        string varName;
        string varIndex;
    }
    // uint256 numTypes;
    bytes[] public dataTypes;

    function setDataControlConractAddr(address _addr) internal {
        require(
            dataControlContract == address(0),
            "DataControlContract addr already set"
        );
        dataControlContract = _addr;
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

    function createNewType(bytes memory _data) external {
        dataTypes.push(_data);
    }

    function indexStorkStore(uint256 _type, bytes memory _data) internal {
        emit StorkStore(msg.sender, dataTypes[_type], _data);
    }

    function bytesStorkStore(bytes memory _type, bytes memory _data) internal {
        emit StorkStore(msg.sender, _type, _data);
    }

    event StorkStore(address indexed _from, bytes indexed _type, bytes _data);
}
