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

    /// @notice Storks are the smallest data unit of the StorkNet
    /// @dev It contains the data stored in the request along with a unique id wrt the collection
    /// @custom: Uniquely identifiable id for each data stored
    /// @custom: Variable of the data type (name, age, isMale, etc)
    /// @custom: Variable of the data type (name, age, isMale, etc)
    struct Stork {
        uint32 _id;
        bytes _data;
    }

    /// @notice A collection of Storks
    /// @dev Contains info on a particular group of storks
    /// @custom: The size of the Phalanx (the collection of storks)
    /// @custom: The stork type id for lookups
    /// @custom: Name proposed by Srinidhi
    struct Phalanx {
        uint32 storkLastId;
        uint32 storkTypeId;
    }

    /// @notice Custom StorkNet datatype for storing data
    /// @dev StorkDataType is the custom data type so that StorkNodes can process data off-chain for lookups
    /// @custom: Solidity data type (string, uint256, bool, etc) of the variable
    /// @custom: Variable of the data type (name, age, isMale, etc)
    /// @custom: The index of the variable for arrays or mappings
    struct StorkType {
        string varType;
        string varName;
        string varIndex;
    }

    enum Operations {
        eq,
        gt,
        lt,
        gte,
        lte,
        neq
    }

    // FILL IN LATER

    /// @notice The request parameters for a parameter request
    /// @dev varName is the variable, operation is how compare,varValue is the value
    /// @custom: Variable of the data type (name, age, isMale, etc)
    /// @custom: The index of the variable for arrays or mappings
    /// @custom: The index of the variable for arrays or mappings
    struct StorkRequestParameters {
        uint16 typeVarId;
        uint16 operation;
        bytes varValue;
    }

    /// @notice Associates a id number with your custom storkDataType
    /// @dev Maps the data type name to a StorkDataType object
    mapping(string => Phalanx) public phalanxInfo;

    /// @notice Counts the number of storkDataTypes
    /// @dev Used to keep track of the number of storkDataTypes
    uint32 public storkTypeCount;

    mapping(string => bool) phalanxExists;

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
    function encodeTypes(StorkType[] calldata _data)
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
        returns (StorkType[] memory)
    {
        return (abi.decode(_data, (StorkType[])));
    }

    // FIX COMMENTS

    /// @notice Converts the bytes array to a StorkDataType
    /// @dev Decoding back to extract the data types, variable names, and indexes if any
    /// @param _data Bytes version of the StorkDataType
    /// @return StorkDataType conversion of the bytes array version
    function storkDecode(bytes calldata _data)
        internal
        pure
        returns (uint32, bytes memory)
    {
        return (abi.decode(_data, (uint32, bytes)));
    }

    //-------------------------------------------------------------------------------------

    /// @notice Creates a new StorkDataType based on the parameters given
    /// @dev Links the StorkDataType with unique name and id, then emits an event for off-chain processing
    /// @param _storkName The name of the StorkDataType
    /// @param _storkData The bytes version of the StorkDataType
    function createNewType(
        string calldata _storkName,
        bytes calldata _storkData
    ) external {
        require(phalanxExists[_storkName] == false, "Type already exists");

        phalanxInfo[_storkName].storkTypeId = storkTypeCount;

        emit NewStorkType(msg.sender, storkTypeCount, _storkName, _storkData);
        phalanxExists[_storkName] == true;
        storkTypeCount++;
    }

    // FIX COMMENTS

    /// @notice Stores new data in the StorkNet
    /// @dev Increments the phalanx's storkLastId, makes a stork with the new id and data, then emits a event
    /// @param _phalanxName The StorkDataType
    /// @param _storkData The value of the data being stored
    function createData(string memory _phalanxName, bytes memory _storkData)
        internal
    {
        uint32 id = phalanxInfo[_phalanxName].storkLastId++;

        emit StorkCreate(_phalanxName, id, Stork({_id: id, _data: _storkData}));
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkId The value of the data being stored
    /// @param _storkData The value of the data being stored
    function updateData(
        string memory _phalanxName,
        uint32 _storkId,
        bytes memory _storkData
    ) internal {
        emit StorkUpdate(
            _phalanxName,
            _storkId,
            Stork({_id: _storkId, _data: _storkData})
        );
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkId The value of the data being stored
    function deleteData(string calldata _phalanxName, uint32 _storkId)
        internal
    {
        emit StorkDelete(_phalanxName, _storkId);
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkIdRange The value of the data being stored
    /// @param _fallbackFunction The value of the data being stored
    function requestRangeData(
        string memory _phalanxName,
        uint32[] memory _storkIdRange,
        bytes memory _fallbackFunction
    ) internal {
        emit StorkRequestRange(_phalanxName, _storkIdRange, _fallbackFunction);
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _arrayOfIds The value of the data being stored
    /// @param _fallbackFunction The value of the data being stored
    function requestIdData(
        string memory _phalanxName,
        uint32[] memory _arrayOfIds,
        bytes memory _fallbackFunction
    ) internal {
        emit StorkRequestId(_phalanxName, _arrayOfIds, _fallbackFunction);
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkRequestParameters The value of the data being stored
    /// @param _fallbackFunction The value of the data being stored
    function requestParameterData(
        string memory _phalanxName,
        StorkRequestParameters[] memory _storkRequestParameters,
        bytes memory _fallbackFunction
    ) internal {
        emit StorkRequestRange(
            _phalanxName,
            _storkRequestParameters,
            _fallbackFunction
        );
    }

    //requestRangeData("student", _startId to EndId, "fallback function");
    //requestIdData("student", _arrayOfIds, "fallback function");
    //requestParameterData("student", "{parameter,value}" , "fallback function");

    // FIX COMMENTS

    /// @notice Lets StorkNet know that a new data type has been created for this contract
    /// @dev This is so that we don't need to store the data type in this contract as they take a lot of space hence gas
    /// @param _from The address of the contract that created the new StorkDataType
    /// @param _storkTypeCount The id of the created StorkDataType
    /// @param _storkName The data type name keccak256-ed because that's how events work
    /// @param _storkData The bytes version of the StorkDataType
    event NewStorkType(
        address indexed _from,
        uint256 indexed _storkTypeCount,
        string indexed _storkName,
        bytes _storkData
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkId The data type name keccak256-ed because that's how events work
    /// @param _stork The data being stored
    event StorkCreate(
        string indexed _phalanxName,
        uint32 indexed _storkId,
        Stork _stork
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkId The data type name keccak256-ed because that's how events work
    /// @param _stork The data being stored
    event StorkUpdate(
        string indexed _phalanxName,
        uint32 indexed _storkId,
        Stork _stork
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _storkName The data type name keccak256-ed because that's how events work
    /// @param _storkId The data being stored
    event StorkDelete(string indexed _storkName, uint32 indexed _storkId);

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkIdRange The data type name keccak256-ed because that's how events work
    /// @param _fallbackFunction The data being stored
    event StorkRequestRange(
        string indexed _phalanxName,
        uint32[] indexed _storkIdRange,
        bytes indexed _fallbackFunction
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _arrayOfIds The data type name keccak256-ed because that's how events work
    /// @param _fallbackFunction The data being stored
    event StorkRequestId(
        string indexed _phalanxName,
        uint32[] indexed _arrayOfIds,
        bytes indexed _fallbackFunction
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkRequestParameters The data type name keccak256-ed because that's how events work
    /// @param _fallbackFunction The data being stored
    event StorkRequestRange(
        string indexed _phalanxName,
        StorkRequestParameters[] indexed _storkRequestParameters,
        bytes indexed _fallbackFunction
    );
}
