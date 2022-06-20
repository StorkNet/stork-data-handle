// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkTypes.sol";

/// @title Stork Handler Contract
/// @author Shankar "theblushirtdude" Subramanian
/// @notice Used to connect a StorkContract to StorkNet
/// @dev
contract StorkQuery is StorkTypes {
    modifier isStorkClient() {
        // (bool succ, bytes memory val) = storkFundAddr.staticcall(
        //     abi.encodeWithSignature("isStorkClient(address)", msg.sender)
        // );

        // require(abi.decode(val, (bool)), "SQ- Not a validator");
        _;
    }

    address public immutable storkFundAddr;
    uint256 internal reqId;

    constructor(address _storkFundAddr) {
        storkFundAddr = _storkFundAddr;
    }

    /// @notice Stores new data in the StorkNet
    /// @dev Increments the phalanx's storkLastId, makes a stork with the new id and data, then emits a event
    /// @param _phalanxName The StorkDataType
    /// @param _abiEncodeData The value of the data being stored
    function createStork(
        string memory _phalanxName,
        uint8 _storkId,
        bytes memory _abiEncodeData
    ) external isStorkClient {
        emit EventStorkCreate(
            msg.sender,
            _phalanxName,
            _storkId,
            abi.encode(
                Stork({
                    _id: _storkId,
                    _typeId: phalanxInfo[_phalanxName].phalanxTypeId,
                    _data: _abiEncodeData
                })
            )
        );
    }

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkId The data type name keccak256-ed because that's how events work
    /// @param _stork The data being stored
    event EventStorkCreate(
        address indexed _clientAddress,
        string _phalanxName,
        uint8 _storkId,
        bytes _stork
    );

    //-------------------------------------------------------------------------------------

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkId The value of the data being stored
    /// @param _abiEncodeData The value of the data being stored
    function updateStorkById(
        string memory _phalanxName,
        uint32 _storkId,
        bytes memory _abiEncodeData
    ) external isStorkClient {
        emit EventStorkUpdateById(
            msg.sender,
            _phalanxName,
            _storkId,
            abi.encode(
                Stork({
                    _id: phalanxInfo[_phalanxName].phalanxTypeId,
                    _typeId: phalanxInfo[_phalanxName].phalanxTypeId,
                    _data: _abiEncodeData
                })
            )
        );
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkParam The parameters of the data being stored
    /// @param _abiEncodeData The value of the data being stored
    function updateStorkByParam(
        string memory _phalanxName,
        StorkParameter[] memory _storkParam,
        bytes memory _abiEncodeData
    ) external isStorkClient {
        emit EventStorkUpdateByParams(
            msg.sender,
            _phalanxName,
            _storkParam,
            abi.encode(
                Stork({
                    _id: phalanxInfo[_phalanxName].phalanxTypeId,
                    _typeId: phalanxInfo[_phalanxName].phalanxTypeId,
                    _data: _abiEncodeData
                })
            )
        );
    }

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkId The data type name keccak256-ed because that's how events work
    /// @param _stork The data being stored
    event EventStorkUpdateById(
        address indexed _clientAddress,
        string _phalanxName,
        uint32 _storkId,
        bytes _stork
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkParam The parameters being searched for in the update
    /// @param _stork The data being stored
    event EventStorkUpdateByParams(
        address indexed _clientAddress,
        string _phalanxName,
        StorkParameter[] _storkParam,
        bytes _stork
    );

    //-------------------------------------------------------------------------------------

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkId The index to delete
    function deleteStorkById(
        string memory _phalanxName,
        uint32[] memory _storkId
    ) external isStorkClient {
        emit EventStorkDeleteById(msg.sender, _phalanxName, _storkId);
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkParam The index to delete
    function deleteStorkByParam(
        string memory _phalanxName,
        StorkParameter[] memory _storkParam
    ) external isStorkClient {
        emit EventStorkDeleteByParams(
            msg.sender,
            _phalanxName,
            abi.encode(_storkParam)
        );
    }

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _storkName The data type name keccak256-ed because that's how events work
    /// @param _storkId The index to delete
    event EventStorkDeleteById(
        address indexed _clientAddress,
        string _storkName,
        uint32[] _storkId
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _storkName The data type name keccak256-ed because that's how events work
    /// @param _storkParam The index to delete
    event EventStorkDeleteByParams(
        address indexed _clientAddress,
        string _storkName,
        bytes _storkParam
    );

    //-------------------------------------------------------------------------------------

    /// @notice Stores the StorkDataType in the StorkNet
    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _arrayOfIds The value of the data being stored
    /// @param _fallbackFunction The value of the data being stored
    function requestStorkById(
        string memory _phalanxName,
        uint32[] memory _arrayOfIds,
        string memory _fallbackFunction
    ) external isStorkClient {
        emit EventStorkRequestId(
            msg.sender,
            _phalanxName,
            _arrayOfIds,
            _fallbackFunction,
            reqId++
        );
    }

    /// @notice Stores the StorkDataType in the StorkNet
    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkRequestParameters The value of the data being stored
    /// @param _fallbackFunction The value of the data being stored
    function requestStorkByParams(
        string memory _phalanxName,
        StorkParameter[] memory _storkRequestParameters,
        string memory _fallbackFunction
    ) external isStorkClient {
        emit EventStorkRequestByParams(
            msg.sender,
            _phalanxName,
            abi.encode(_storkRequestParameters),
            _fallbackFunction
        );
    }

    /// @dev The event emitted tells StorkNet about the data being stored, it's type, and the contract associated
    /// @param _phalanxName The StorkDataType
    /// @param _storkIdRange The value of the data being stored
    /// @param _fallbackFunction The value of the data being stored
    function requestStorkByRange(
        string memory _phalanxName,
        uint32[] memory _storkIdRange,
        string memory _fallbackFunction
    ) external isStorkClient {
        emit EventStorkRequestByRange(
            msg.sender,
            _phalanxName,
            _storkIdRange,
            _fallbackFunction
        );
    }

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _arrayOfIds The data type name keccak256-ed because that's how events work
    /// @param _fallbackFunction The data being stored
    event EventStorkRequestId(
        address indexed _clientAddress,
        string _phalanxName,
        uint32[] _arrayOfIds,
        string _fallbackFunction,
        uint256 _reqId
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkRequestParameters The data type name keccak256-ed because that's how events work
    /// @param _fallbackFunction The data being stored
    event EventStorkRequestByParams(
        address indexed _clientAddress,
        string _phalanxName,
        bytes _storkRequestParameters,
        string _fallbackFunction
    );

    /// @notice Lets StorkNet know that this contract has a new Store request
    /// @param _phalanxName The address of the contract that created the new StorkDataType
    /// @param _storkIdRange The data type name keccak256-ed because that's how events work
    /// @param _fallbackFunction The data being stored
    event EventStorkRequestByRange(
        address indexed _clientAddress,
        string _phalanxName,
        uint32[] _storkIdRange,
        string _fallbackFunction
    );
}
