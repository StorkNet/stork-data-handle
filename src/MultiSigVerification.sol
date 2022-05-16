// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MultiSigVerification {
    event SubmitTransaction(
        address indexed validator,
        uint256 indexed txIndex,
        address indexed contractAddr
    );
    event ConfirmTransaction(
        address indexed validator,
        uint256 indexed txIndex
    );
    event RevokeConfirmation(
        address indexed validator,
        uint256 indexed txIndex
    );
    event ExecuteTransaction(
        address indexed validator,
        uint256 indexed txIndex
    );

    address[] public validators;
    mapping(address => bool) public isValidator;
    uint256 public minNumConfirmationsRequired;

    struct Transaction {
        address contractAddr;
        address[] validators;
        bool exist;
        bool executed;
        uint256 numConfirmations;
        uint256 maxNumConfirmations;
    }

    // mapping from tx index => validator => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    mapping(uint256 => Transaction) public transactions;

    uint256 private txCount;

    modifier onlyValidator() {
        require(isValidator[msg.sender], "not validator");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(transactions[_txIndex].exist, "tx does not exist");
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

    function submitTransaction(
        uint256 _txIndex,
        address _contractAddr,
        address[] calldata _validators,
        uint256 _maxNumConfirmations
    ) public onlyValidator {
        require(transactions[_txIndex].exist == false, "tx already exists");

        txCount++;

        transactions[_txIndex] = Transaction({
            contractAddr: _contractAddr,
            validators: _validators,
            exist: true,
            executed: false,
            numConfirmations: 0,
            maxNumConfirmations: _maxNumConfirmations
        });

        emit SubmitTransaction(msg.sender, _txIndex, _contractAddr);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyValidator
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyValidator
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= minNumConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyValidator
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
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
        returns (Transaction memory)
    {
        return (transactions[_txIndex]);
    }
}
