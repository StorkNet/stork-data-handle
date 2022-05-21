// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract StorkBatcher {
    struct Tx {
        bytes32 txValidatorCheck;
        address txClientAddress;
        address txMiner;
        address[] txValidatorAddrs;
        uint8[] txNumValidations;
        uint8 txNumClientTransactions;
        uint8 txNumConfirmationsPending;
    }

    function txBatching(uint16 txId, Tx[] memory transactions) external {}
}

/// @title StorkNet's OnChain Data Control Client
/// @author Shankar "theblushirtdude" Subramanian
/// @notice
/// @dev This contract is used to validate the StorkTxs
contract MultiSigVerification {
    modifier onlyValidator() {
        require(isValidator[msg.sender], "not validator");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(
            batchTransactions[_txIndex].isBatchCreated,
            "tx does not exist"
        );
        _;
    }

    modifier txNotExecuted(uint256 _txIndex) {
        require(
            !batchTransactions[_txIndex].isBatchExecuted,
            "tx already executed"
        );
        _;
    }

    modifier txConfirmed(uint256 _txIndex, bool _isConfirmed) {
        require(
            (batchTransactions[_txIndex].batchNumConfirmationsPending == 0) ==
                _isConfirmed,
            "tx already confirmed"
        );
        _;
    }

    modifier validatorNotConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    struct Tx {
        bytes32 txValidatorCheck;
        address txClientAddress;
        address txMiner;
        address[] txValidatorAddrs;
        uint8[] txNumValidations;
        uint8 txNumClientTransactions;
        uint8 txNumConfirmationsPending;
    }

    // struct Tx {
    //     address txMiner;
    //     string cid;
    //     uint8 txNumConfirmationsPending;
    // }
    
    struct BatchTransaction {
        bytes32 batchValidatorCheck;
        address[] batchValidators;
        address batchMiner;
        Tx[] transactions;
        uint8 batchNumConfirmationsPending;
        bool isBatchCreated;
        bool isBatchExecuted;
    }

    /// @notice List of StorkValidators
    /// @dev All approved StorkValidators are listed here
    address[] public validators;

    /// @return bool if address is validator
    mapping(address => bool) public isValidator;

    /// @notice Default minimum number of confirmations
    /// @dev If transaction confirmations are lower, discard transaction
    uint256 public minNumConfirmationsRequired;

    // mapping from tx index => validator => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    mapping(uint256 => BatchTransaction) public batchTransactions;

    uint16 private txCount;

    StorkBatcher public storkBatcherContract;

    bool public isStorkBatcherContractSet;

    constructor(
        address[] memory _validators,
        uint256 _minNumConfirmationsRequired
    ) {
        require(_validators.length > 0, "validators required");
        require(
            _minNumConfirmationsRequired > 0 &&
                _minNumConfirmationsRequired <= _validators.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < _validators.length; i++) {
            address validator = _validators[i];

            require(validator != address(0), "invalid validator");
            require(!isValidator[validator], "validator not unique");

            isValidator[validator] = true;
            validators.push(validator);
        }

        minNumConfirmationsRequired = _minNumConfirmationsRequired;
    }

    function setStorkBatcherContract(address payable _storkBatcher) public {
        require(!isStorkBatcherContractSet, "client already set");
        storkBatcherContract = StorkBatcher(_storkBatcher);
    }

    function submitTransaction(
        uint256 _txIndex,
        bytes32 _batchValidatorCheck,
        address[] calldata _batchValidators,
        address _batchMiner,
        Tx[] calldata _transactions,
        uint8 _batchNumConfirmationsPending,
        bool _isBatchCreated,
        bool _isBatchExecuted
    ) public onlyValidator {
        require(
            batchTransactions[_txIndex].isBatchCreated == false,
            "tx already exists"
        );

        txCount++;

        batchTransactions[_txIndex] = BatchTransaction({
            batchValidatorCheck: _batchValidatorCheck,
            batchValidators: _batchValidators,
            batchMiner: _batchMiner,
            transactions: _transactions,
            batchNumConfirmationsPending: _batchNumConfirmationsPending,
            isBatchCreated: _isBatchCreated,
            isBatchExecuted: _isBatchExecuted
        });

        emit SubmitTransaction(_txIndex, msg.sender);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyValidator
        txConfirmed(_txIndex, false)
        txNotExecuted(_txIndex)
        txExists(_txIndex)
        validatorNotConfirmed(_txIndex)
    {
        BatchTransaction storage transaction = batchTransactions[_txIndex];

        // keccack256 converts the input to bytes32 constant size
        transaction.batchValidatorCheck ^= keccak256(
            abi.encodePacked(msg.sender)
        );
        transaction.batchNumConfirmationsPending--;
        transaction.batchValidators.push(msg.sender);
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(
            _txIndex,
            msg.sender,
            transaction.batchNumConfirmationsPending
        );
    }

    function executeTransaction(uint8 _txIndex)
        public
        payable
        onlyValidator
        txConfirmed(_txIndex, true)
        txExists(_txIndex)
        txNotExecuted(_txIndex)
    {
        BatchTransaction memory transaction = batchTransactions[_txIndex];

        if (transaction.batchValidatorCheck != bytes32(0)) {
            emit InvalidValidators(_txIndex);
            return;
        }

        Tx[] memory transactions = transaction.transactions;

        storkBatcherContract.txBatching(_txIndex, transactions);

        batchTransactions[_txIndex].hasExecuted = true;

        emit ExecuteTransaction(_txIndex, msg.sender);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyValidator
        txExists(_txIndex)
        txNotExecuted(_txIndex)
    {
        BatchTransaction memory transaction = batchTransactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations--;
        transaction.validatorCheck ^= keccak256(abi.encodePacked(msg.sender));
        isConfirmed[_txIndex][msg.sender] = false;

        batchTransactions[_txIndex] = transaction;
        emit RevokeConfirmation(_txIndex, msg.sender);
    }

    function getValidators() public view returns (address[] memory) {
        return validators;
    }

    function getTransactionCount() public view returns (uint256) {
        return txCount;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (BatchTransaction memory)
    {
        return (batchTransactions[_txIndex]);
    }

    function getMinerOfTx(uint256 _txIndex) public view returns (address) {
        return (batchTransactions[_txIndex].miner);
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
