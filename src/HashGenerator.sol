// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HashGenerator {
    bytes32 public txHashed;
    bytes32 public batchHash;
    bytes32[] public txHashes;

    function submitTransaction(
        uint256 _batchIndex,
        bytes32[] calldata _txHash,
        string calldata _cid
    ) public {
        txHashed = keccak256(abi.encodePacked(_txHash));
        batchHash = keccak256(
            abi.encodePacked(_batchIndex, msg.sender, txHashed, _cid)
        );
    }

    function txExecuteBatching(
        address[] calldata _contracts,
        address[] calldata _validators,
        uint8[] calldata _contractTxCounts,
        uint8[] calldata _validatorTxCounts
    ) external {
        for (uint8 i = 0; i < _contracts.length; i++) {
            txHashes.push(
                keccak256(
                    abi.encodePacked(
                        _contracts[i],
                        _validators[i],
                        _contractTxCounts[i],
                        _validatorTxCounts[i]
                    )
                )
            );
        }
    }
}
