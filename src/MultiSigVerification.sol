// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorkBlockRollup {
    function txAllowExecuteblocking(
        uint256 _txIndex,
        address[] calldata validators
    ) external {}
}

contract StorkFund {
    function changeTxCost(uint256 _newCostPerTx) external {}
}

/// @title StorkNet's OnChain Data Control Client
/// @author Shankar "theblushirtdude" Subramanian
/// @notice
/// @dev This contract is used to validate the StorkTxs
contract MultiSigVerification {
    modifier onlyValidators() {
        (bool succ, bytes memory val) = storkStakeAddr.staticcall(
            abi.encodeWithSignature("isValidator(address)", msg.sender)
        );

        require(
            abi.decode(val, (bool)) || msg.sender == storkblockerAddr,
            "MSV- Not a validator"
        );
        _;
    }
    modifier OnlyStorkStake() {
        require(msg.sender == storkStakeAddr, "MSV- Not the storkStakeAddr");
        _;
    }
    modifier OnlyStorkFund() {
        require(msg.sender == storkFundAddr, "MSV- Not the storkStakeAddr");
        _;
    }
    modifier onlyblocker() {
        require(msg.sender == storkblockerAddr, "MSV- Not multi sig wallet");
        _;
    }

    modifier validatorNotConfirmed(uint256 _txIndex) {
        require(
            !isConfirmed[_txIndex][msg.sender] ||
                msg.sender == storkblockerAddr,
            "MSV- tx already confirmed"
        );
        _;
    }

    modifier txConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "MSV- tx not confirmed");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(
            blocks[_txIndex].minConfirmations > 0,
            "MSV- tx does not exist"
        );
        _;
    }

    modifier txCanExecute(uint256 _txIndex) {
        require(
            blocks[_txIndex].minConfirmations == 0,
            "MSV- tx already executed"
        );
        _;
    }

    struct Block {
        uint32 blockNumber;
        bytes32 validatorProof;
        address blockMiner;
        bytes32[] txHash;
        address[] contracts;
        address[] validators;
        uint8[] contractsTxCounts;
        uint8[] validatorsTxCounts;
        uint8 minConfirmations;
        uint256 blockLockTime;
        bool isSealed;
    }

    /// @notice List of StorkValidators
    /// @dev All approved StorkValidators are listed here
    address[] public validators;

    /// @notice Default minimum number of confirmations
    /// @dev If transaction confirmations are lower, discard transaction
    uint256 public minNumConfirmationsRequired;

    // mapping from tx index => validator => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    mapping(uint256 => bool) public isExecuted;
    mapping(uint256 => Block) public blocks;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public storkblockerAddr;
    StorkBlockRollup public storkBlockRollup;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public storkStakeAddr;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public storkFundAddr;
    StorkFund public storkFund;

    constructor(
        address _blockContractAddr,
        address _storkStakeAddr,
        address _storkFundAddr
    ) {
        storkBlockRollup = StorkBlockRollup(_blockContractAddr);
        storkblockerAddr = _blockContractAddr;
        storkStakeAddr = _storkStakeAddr;
        storkFund = StorkFund(_storkFundAddr);
        storkFundAddr = _storkFundAddr;
    }

    function submitTransaction(
        uint256 _blockNumber,
        bytes calldata _blockData,
        bytes32 _blockHash
    ) external onlyValidators validatorNotConfirmed(_blockNumber) {
        address _validator;

        Block memory thisBlock = abi.decode(_blockData, (Block));
        require(
            keccak256(abi.encode(thisBlock.blockMiner, _blockData)) ==
                _blockHash,
            "MSV - hash doesn't match block content"
        );

        Block memory storageBlock = blocks[_blockNumber];
        if (msg.sender == storkblockerAddr) {
            if (storageBlock.minConfirmations > 0) {
                storageBlock.blockMiner = thisBlock.blockMiner;
                storageBlock.minConfirmations--;
                _validator = thisBlock.blockMiner;
            } else {
                createNewTransaction(_blockNumber, _blockData);
            }
        } else {
            //check if a hash of blockIndex, blockValidator, txHash is already in the block
            if (storageBlock.minConfirmations > 0) {
                storageBlock.minConfirmations--;
                _validator = msg.sender;
            } else {
                createNewTransaction(_blockNumber, _blockData);
            }
        }
        storageBlock.validatorProof ^= keccak256(abi.encodePacked(_validator));
        blocks[_blockNumber] = storageBlock;
        blocks[_blockNumber].validators.push(_validator);
        isConfirmed[_blockNumber][_validator] = true;
        if (blocks[_blockNumber].minConfirmations == 0) {
            executeTransaction(uint8(_blockNumber));
        }
        emit SubmitTransaction(_blockNumber, _validator);
    }

    function createNewTransaction(
        uint256 _blockNumber,
        bytes calldata _blockData
    ) internal {
        blocks[_blockNumber] = abi.decode(_blockData, (Block));
    }

    function executeTransaction(uint8 _txIndex)
        internal
        txCanExecute(_txIndex)
    {
        if (blocks[_txIndex].validatorProof != bytes32(0)) {
            emit InvalidValidators(_txIndex);
            return;
        }

        storkBlockRollup.txAllowExecuteblocking(
            _txIndex,
            blocks[_txIndex].validators
        );

        isExecuted[_txIndex] = true;

        emit ExecuteTransaction(_txIndex, msg.sender);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyValidators
        txExists(_txIndex)
        txCanExecute(_txIndex)
    {
        Block memory transaction = blocks[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "MSV- tx not confirmed");

        transaction.minConfirmations++;
        transaction.validatorProof ^= keccak256(abi.encodePacked(msg.sender));
        isConfirmed[_txIndex][msg.sender] = false;

        blocks[_txIndex] = transaction;
        emit RevokeConfirmation(_txIndex, msg.sender);
    }

    function supplyRequestData(
        uint256 _reqId,
        address _addr,
        string calldata _fallback,
        bytes calldata _data,
        bytes32 zkProof,
        uint256 _key
    ) external onlyValidators {
        require(
            zkProof == keccak256(abi.encode(_data, _key, msg.sender)),
            "failed zkProof"
        );
        (bool success, ) = _addr.call(
            abi.encodeWithSignature(_fallback, _data)
        );
        emit RequestHandled(_reqId, msg.sender, _addr, success);
    }

    event SubmitTransaction(uint256 indexed txIndex, address indexed validator);
    event ConfirmTransaction(
        uint256 indexed txIndex,
        address indexed validator,
        uint256 indexed validatorCount
    );
    event RevokeConfirmation(
        uint256 indexed txIndex,
        address indexed validator
    );
    event InvalidValidators(uint256 indexed txIndex);
    event ExecuteTransaction(
        uint256 indexed txIndex,
        address indexed validator
    );
    event RequestHandled(
        uint256 indexed reqId,
        address indexed validator,
        address indexed client,
        bool status
    );
}
