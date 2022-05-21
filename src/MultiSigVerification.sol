// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract StorkBatcher {
    function storkValidatorTxBatcher(
        address[] calldata _txValidatorAddrs,
        uint8[] calldata _txValidatorCounts
    ) external {}

    function clientTxBatcher(
        uint16 txId,
        address[] calldata _txClientAddrs,
        uint8[] calldata _txClientCounts
    ) external {}
}

contract MultiSigVerification {
    modifier onlyValidator() {
        require(isValidator[msg.sender], "not validator");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(transactions[_txIndex].created, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    struct Tx {
        address[] txClientAddrs;
        address[] txValidatorAddrs;
        uint8[] txClientCounts;
        uint8[] txValidatorCounts;
    }

    struct StorkTransaction {
        bytes32 validatorCheck;
        address[] validators;
        address miner;
        Tx transaction;
        uint8 numConfirmations;
        uint8 maxNumConfirmations;
        bool created;
        bool executed;
    }

    address[] public validators;
    mapping(address => bool) public isValidator;

    uint256 public minNumConfirmationsRequired;

    // mapping from tx index => validator => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    mapping(uint256 => StorkTransaction) public transactions;

    uint16 private txCount;

    StorkBatcher public storkBatcher;
    bool public storkBatcherSet;

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

    function setDataControlClient(address payable _dataControlAddr) public {
        require(storkBatcherSet == false, "client already set");
        storkBatcher = StorkBatcher(_dataControlAddr);
    }

    function submitTransaction(
        uint256 _txIndex,
        bytes32 _validatorCheck,
        address _miner,
        address[] calldata _txClientAddrs,
        address[] calldata _txValidatorAddrs,
        uint8[] calldata _txClientCounts,
        uint8[] calldata _txValidatorCounts,
        uint8 _maxNumConfirmations
    ) public onlyValidator {
        require(transactions[_txIndex].created == false, "tx already exists");

        txCount++;

        transactions[_txIndex] = StorkTransaction({
            validatorCheck: _validatorCheck,
            validators: new address[](0),
            miner: _miner,
            transaction: Tx({
                txClientAddrs: _txClientAddrs,
                txValidatorAddrs: _txValidatorAddrs,
                txClientCounts: _txClientCounts,
                txValidatorCounts: _txValidatorCounts
            }),
            created: true,
            executed: false,
            numConfirmations: 0,
            maxNumConfirmations: _maxNumConfirmations
        });

        emit SubmitTransaction(_txIndex, msg.sender);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyValidator
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        StorkTransaction storage transaction = transactions[_txIndex];

        transaction.validatorCheck ^= keccak256(abi.encodePacked(msg.sender));
        transaction.numConfirmations++;
        transaction.validators.push(msg.sender);
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(
            _txIndex,
            msg.sender,
            transaction.numConfirmations
        );
    }

    function executeTransaction(uint8 _txIndex)
        public
        payable
        onlyValidator
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        StorkTransaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= minNumConfirmationsRequired,
            "cannot execute tx"
        );

        if (transaction.validatorCheck != bytes32(0)) {
            emit InvalidValidators(_txIndex);
            return;
        }

        Tx memory transactionData = transaction.transaction;

        storkBatcher.storkValidatorTxBatcher(
            transactionData.txValidatorAddrs,
            transactionData.txValidatorCounts
        );

        storkBatcher.clientTxBatcher(
            _txIndex,
            transactionData.txClientAddrs,
            transactionData.txClientCounts
        );

        transaction.executed = true;

        emit ExecuteTransaction(_txIndex, msg.sender);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyValidator
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        StorkTransaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations--;
        transaction.validatorCheck ^= keccak256(abi.encodePacked(msg.sender));
        isConfirmed[_txIndex][msg.sender] = false;

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
        returns (StorkTransaction memory)
    {
        return (transactions[_txIndex]);
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
