// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorkBatcher {
    function txAllowExecuteBatching(
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
            abi.decode(val, (bool)) || msg.sender == storkBatcherAddr,
            "Not a validator"
        );
        _;
    }
    modifier OnlyStorkStake() {
        require(msg.sender == storkStakeAddr, "Not the storkStakeAddr");
        _;
    }
    modifier OnlyStorkFund() {
        require(msg.sender == storkFundAddr, "Not the storkStakeAddr");
        _;
    }
    modifier onlyBatcher() {
        require(msg.sender == storkBatcherAddr, "Not multi sig wallet");
        _;
    }

    modifier validatorNotConfirmed(uint256 _txIndex) {
        require(
            !isConfirmed[_txIndex][msg.sender] ||
                msg.sender == storkBatcherAddr,
            "tx already confirmed"
        );
        _;
    }

    modifier txConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(
            batchTransactions[_txIndex].batchConfirmationsRequired > 0,
            "tx does not exist"
        );
        _;
    }

    modifier txCanExecute(uint256 _txIndex) {
        require(
            batchTransactions[_txIndex].batchConfirmationsRequired == 0,
            "tx already executed"
        );
        _;
    }

    struct BatchTransaction {
        address batchMiner;
        bytes32 batchValidatorCheck;
        address[] batchValidator;
        // hash of batchindex, batchMiner, txHash
        bytes32 batchHash;
        // Tx array becomes keccak256(abi.encodePacked()) gets hashed keccak256(abi.encodePacked())
        bytes32 txHash;
        uint8 batchConfirmationsRequired; // 0 not create, 1 validated, >1 not fully confirmed
        bool isBatchExecuted;
        string batchCid;
    }

    /// @notice List of StorkValidators
    /// @dev All approved StorkValidators are listed here
    address[] public validators;

    /// @notice Default minimum number of confirmations
    /// @dev If transaction confirmations are lower, discard transaction
    uint256 public minNumConfirmationsRequired;

    // mapping from tx index => validator => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    mapping(uint256 => BatchTransaction) public batchTransactions;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public storkBatcherAddr;
    StorkBatcher public storkBatcher;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public storkStakeAddr;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public storkFundAddr;
    StorkFund public storkFund;

    constructor(
        address _batchContractAddr,
        address _storkStakeAddr,
        address _storkFundAddr
    ) {
        storkBatcher = StorkBatcher(_batchContractAddr);
        storkBatcherAddr = _batchContractAddr;
        storkStakeAddr = _storkStakeAddr;
        storkFund = StorkFund(_storkFundAddr);
        storkFundAddr = _storkFundAddr;
    }

    function submitTransaction(
        uint256 _batchIndex,
        bytes32 _batchValidatorCheck,
        address _minerAddr,
        bytes32 _batchHash,
        bytes32[] calldata _txHash,
        uint8 _batchConfirmationsRequired,
        string calldata _cid
    ) external onlyValidators validatorNotConfirmed(_batchIndex) {
        bytes32 txHashed = keccak256(abi.encodePacked(_txHash));

        if (msg.sender == storkBatcherAddr) {
            if (batchTransactions[_batchIndex].batchConfirmationsRequired > 0) {
                batchTransactions[_batchIndex].batchMiner = _minerAddr;
                batchTransactions[_batchIndex].batchConfirmationsRequired--;
            } else {
                createNewTransaction(
                    _batchIndex,
                    _batchValidatorCheck,
                    msg.sender,
                    _batchHash,
                    txHashed,
                    _batchConfirmationsRequired,
                    _cid
                );
            }
        } else {
            //check if a hash of cid, batchIndex, batchValidator, txHash is already in the batch
            if (batchTransactions[_batchIndex].batchConfirmationsRequired > 0) {
                batchTransactions[_batchIndex].batchConfirmationsRequired--;
            } else {
                createNewTransaction(
                    _batchIndex,
                    _batchValidatorCheck,
                    address(0),
                    _batchHash,
                    txHashed,
                    _batchConfirmationsRequired,
                    _cid
                );
            }
        }
        batchTransactions[_batchIndex].batchValidator.push(msg.sender);
        batchTransactions[_batchIndex].batchValidatorCheck ^= keccak256(
            abi.encodePacked(msg.sender)
        );
        isConfirmed[_batchIndex][msg.sender] = true;
        if (batchTransactions[_batchIndex].batchConfirmationsRequired == 1) {
            batchTransactions[_batchIndex].batchConfirmationsRequired = 0;
            executeTransaction(uint8(_batchIndex));
        }
        emit SubmitTransaction(_batchIndex, msg.sender);
    }

    function createNewTransaction(
        uint256 _batchIndex,
        bytes32 _batchValidatorCheck,
        address _minerAddr,
        bytes32 _batchHash,
        bytes32 _txHash,
        uint8 _batchConfirmationsRequired,
        string calldata _cid
    ) internal {
        batchTransactions[_batchIndex] = BatchTransaction({
            batchMiner: _minerAddr,
            batchValidatorCheck: _batchValidatorCheck,
            batchValidator: new address[](0),
            batchHash: _batchHash,
            txHash: _txHash,
            batchConfirmationsRequired: _batchConfirmationsRequired,
            batchCid: _cid,
            isBatchExecuted: false
        });
    }

    function executeTransaction(uint8 _txIndex)
        internal
        txCanExecute(_txIndex)
    {
        if (batchTransactions[_txIndex].batchValidatorCheck != bytes32(0)) {
            emit InvalidValidators(_txIndex);
            return;
        }

        storkBatcher.txAllowExecuteBatching(
            _txIndex,
            batchTransactions[_txIndex].batchValidator
        );

        batchTransactions[_txIndex].isBatchExecuted = true;

        emit ExecuteTransaction(_txIndex, msg.sender);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyValidators
        txExists(_txIndex)
        txCanExecute(_txIndex)
    {
        BatchTransaction memory transaction = batchTransactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.batchConfirmationsRequired++;
        transaction.batchValidatorCheck ^= keccak256(
            abi.encodePacked(msg.sender)
        );
        isConfirmed[_txIndex][msg.sender] = false;

        batchTransactions[_txIndex] = transaction;
        emit RevokeConfirmation(_txIndex, msg.sender);
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
}
