// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @custom: Data Control Contract is called DCC

/// @title Stork Handler Contract
/// @author Shankar "theblushirtdude" Subramanian
/// @notice Used to connect a StorkContract to StorkNet
/// @dev
contract StorkTypes {
    /// @notice Storks are the smallest data unit of the StorkNet
    /// @dev It contains the data stored in the request along with a unique id wrt the collection
    /// @custom: Unique id for each data stored of Flock _typeId
    /// @custom: Id of the Phalanx type interacted with
    /// @custom: Bytes data of the Stork type _typeId (name, age, isMale, etc)
    struct Stork {
        uint8 _id;
        uint8 _typeId;
        bytes _data;
    }

    /// @notice Custom StorkNet datatype for storing data
    /// @dev StorkDataType is the custom data type so that StorkNodes can process data off-chain for lookups
    /// @custom: Solidity data type (string, uint256, bool, etc) of the variable
    /// @custom: Variable name of the data type (name, age, isMale, etc)
    /// @custom: The index of the variable for arrays or mappings
    struct PhalanxType {
        string varType;
        string varName;
        string varIndex;
    }

    /// @notice A collection of Storks
    /// @dev Contains info on a particular group of storks
    /// @custom: The Phalanx type id for lookups
    /// @custom: The size of the Phalanx (the collection of storks)
    /// @custom: Name proposed by Srinidhi
    struct Phalanx {
        uint8 phalanxTypeId;
        uint8 phalanxLastId;
    }

    /// @notice The different types of operations for data processing
    /// @dev The different operations for delete, update, and create
    enum CONDITION {
        eq, // equals to
        gt, // greater than
        lt, // less than
        gte, // greater than or equal to
        lte, // less than or equal to
        neq // not equal to
    }

    /// @notice The request parameters for a parameter request
    /// @dev varName is the variable, operation is how compare,varValue is the value
    /// @custom: Id of the Phalanx type interacted with
    /// @custom: Operation being performed on the variable
    /// @custom: The value of the variable being replaced after the operation is performed
    struct StorkParameter {
        uint8 typeVarId;
        CONDITION operation;
        string varValue;
    }

    /// @notice Associates a id number with your custom Phalanx type
    /// @dev Maps the data type name to a Phalanx type object
    mapping(string => Phalanx) public phalanxInfo;

    /// @notice Counts the number of Phalanx types
    /// @dev Used to keep track of the number of Phalanx types
    uint8 public storkTypeCount;

    /// @notice Checks if a Phalanx type exists
    /// @dev Used to check if a Phalanx type exists
    mapping(string => bool) public phalanxExists;
}
