// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract StorkData {
    struct DataStruct {
        address x;
        uint256 y;
        bool z;
    }

    // gas 23493
    uint256 public max;

    event UploadComplete(address indexed _from, DataStruct _value);
    event UploadCompleteEncode(address indexed _from, bytes _data);

    // gas for encoding 26392
    // gas for encoding 26380
    // gas for encoding 26380
    function encode(DataStruct calldata data) public { 
        emit UploadCompleteEncode(msg.sender, abi.encode(data));
    }

    // gas for decoding 24183
    // gas for decoding 24183
    // gas for decoding 24183
    function decode(bytes calldata data) public pure returns (DataStruct memory structData)
    { 
        structData = abi.decode(data, (DataStruct));
    }

    //FIND GAS 
    function findMaxDecoded(DataStruct[] calldata data) public {
        for(uint8 i = 1; i<data.length; ++i){
            if(data[i].y > max){
                max = data[i].y;
            }
        }
    }

    //FIND GAS 
    function findMaxEncoded(bytes[] calldata data) public {
        for(uint8 i = 1; i<data.length; ++i){
            DataStruct memory temp = abi.decode(data[i], (DataStruct));
            if(temp.y > max){
                max = temp.y;
            }
        }
    }


    // gas for resetting value of max 21489 
    function resetMax() external {
        max = 0;
    }
}