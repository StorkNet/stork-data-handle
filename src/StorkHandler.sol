// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @custom: Data Control Contract is called DCC

/// @title Stork Handler Contract
/// @author Shankar "theblushirtdude" Subramanian
/// @notice Used to connect a StorkContract to StorkNet
/// @dev
contract StorkHandler {
    /// @notice Address of the DCC
    address public dataControlContract;

    /// @notice Custom StorkNet datatype for storing data
    /// @dev StorkDataType is the custom data type so that StorkNodes can process data off-chain for lookups
    /// @custom: Solidity data type (string, uint256, bool, etc) of the variable
    /// @custom: Variable of the data type (name, age, isMale, etc)
    /// @custom: The index of the variable for arrays or mappings
    struct StorkDataType {
        string varType;
        string varName;
        string varIndex;
    }

    /// @notice Associates a id number with your custom storkDataType
    /// @dev Converts the datatype name to the datatype id
    /// @return The id for the datatype
    mapping(string => uint256) public dataType;

    /// @notice Counts the number of storkDataTypes
    /// @dev Used to keep track of the number of storkDataTypes
    uint256 public dataTypeCount;

    /// @notice Sets the address of the DCC
    /// @dev If the address is not set, then set the address of the DCC
    /// @param _addr The address of the DCC
    function setDataControlConractAddr(address _addr) internal {
        require(
            dataControlContract == address(0),
            "DataControlContract addr already set"
        );
        dataControlContract = _addr;
    }

    /// @notice Initializes your StorkContract with some ETH so that it can interact with StorkNet
    /// @dev A call function to the DCC with some ETH to initialize the StorkContract
    function contractFunding() external payable {
        (bool success, ) = dataControlContract.call{value: msg.value}(
            abi.encodeWithSignature("fundStorkContract(address)", this)
        );
        require(success, "Failed to fund contract");
    }

    /// @notice Returns the number of transactions that can be made by this StorkContract
    /// @dev staticcall to the DCC to get the number of txLeft of the StorkContract
    /// @return uint256 for the number of Txns left that can be made
    function txsLeft() public view returns (uint256) {
        (bool success, bytes memory data) = dataControlContract.staticcall(
            abi.encodeWithSignature("txLeftStorkContract(address)", this)
        );

        require(success, "Failed to get txs left");

        // As the data is in bytes, we need to decode it to uint256
        return (abi.decode(data, (uint256)));
    }

    /// @notice Converts a StorkDataType to a bytes array for easier use as a parameter/event value
    /// @dev A bytes version is preferable as it's easier to handle
    /// @param _data a parameter just like in doxygen (must be followed by parameter name)
    function encodeTypes(StorkDataType[] calldata _data)
        public
        pure
        returns (bytes memory)
    {
        return (abi.encode(_data));
    }

    /// @notice Converts the bytes array to a StorkDataType
    /// @dev Decoding back to extract the data types, variable names, and indexes if any
    /// @param _data Bytes version of the StorkDataType
    /// @return StorkDataType conversion of the bytes array version
    function decodeTypes(bytes calldata _data)
        public
        pure
        returns (StorkDataType[] memory)
    {
        return (abi.decode(_data, (StorkDataType[])));
    }

    /// @notice Creates a new StorkDataType based on the parameters given
    /// @dev Links the StorkDataType with unique name and id, then emits an event for off-chain processing
    /// @param _name The name of the StorkDataType
    /// @param _data The bytes version of the StorkDataType
    function createNewType(string calldata _name, bytes calldata _data)
        external
    {
        require(dataType[_name] == 0, "Type already exists");

        dataType[_name] = dataTypeCount;

        emit StorkType(msg.sender, dataTypeCount, _name, _data);
        dataTypeCount++;
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _type The StorkDataType
    /// @param _data The value of the data being stored
    function storeData(string memory _type, bytes memory _data) internal {
        emit StorkStore(msg.sender, _type, _data);
    }

    /// @notice Lets StorkNet know that a new data type has been created for this contract
    /// @dev This is so that we don't need to store the data type in this contract as they take a lot of space hence gas
    /// @param _from The address of the contract that created the new StorkDataType
    /// @param _typeId The id of the created StorkDataType
    /// @param _typeName The data type name keccak256-ed because that's how events work
    /// @param _data The bytes version of the StorkDataType
    event StorkType(
        address indexed _from,
        uint256 indexed _typeId,
        string indexed _typeName,
        bytes _data
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _from The address of the contract that created the new StorkDataType
    /// @param _typeName The data type name keccak256-ed because that's how events work
    /// @param _data The data being stored
    event StorkStore(
        address indexed _from,
        string indexed _typeName,
        bytes _data
    );
}
