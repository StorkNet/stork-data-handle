// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract DataControlContract {
    function storkNodeTxBatcher(
        address[] calldata _txNodeAddrs,
        uint256[] calldata _txNodeCounts
    ) external {}

    function contractTxBatcher(
        uint256 txId,
        address[] calldata _txContractAddrs,
        uint256[] calldata _txContractCounts
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
        address[] txContractAddrs;
        uint256[] txContractCounts;
        address[] txNodeAddrs;
        uint256[] txNodeCounts;
    }
    
    struct Transaction {
        bytes32 validatorCheck;
        address[] validators;
        Tx data;
        bool created;
        bool executed;
        uint256 numConfirmations;
        uint256 maxNumConfirmations;
    }

    address[] public validators;
    mapping(address => bool) public isValidator;

    uint256 public minNumConfirmationsRequired;

    // mapping from tx index => validator => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    mapping(uint256 => Transaction) public transactions;

    uint256 private txCount;

    DataControlContract public dataControlContract;
    bool public dataControlContractSet;

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

    function setDataControlContract(address payable _dataControlAddr) public {
        require(dataControlContractSet == false, "contract already set");
        dataControlContract = DataControlContract(_dataControlAddr);
    }

    function submitTransaction(
        uint256 _txIndex,
        bytes32 _validatorCheck,
        address[] calldata txContractAddrs,
        uint256[] calldata txContractCounts,
        address[] calldata txNodeAddrs,
        uint256[] calldata txNodeCounts,
        uint256 _maxNumConfirmations
    ) public onlyValidator {
        require(transactions[_txIndex].created == false, "tx already exists");

        txCount++;

        transactions[_txIndex] = Transaction({
            validatorCheck: _validatorCheck,
            validators: new address[](0),
            data: Tx(
                txContractAddrs,
                txContractCounts,
                txNodeAddrs,
                txNodeCounts
            ),
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
        Transaction storage transaction = transactions[_txIndex];

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

    function executeTransaction(uint256 _txIndex)
        public
        payable
        onlyValidator
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= minNumConfirmationsRequired,
            "cannot execute tx"
        );

        if (transaction.validatorCheck != bytes32(0)) {
            emit InvalidValidators(_txIndex);
            return;
        }

        Tx memory transactionData = transaction.data;

        dataControlContract.storkNodeTxBatcher(
            transactionData.txNodeAddrs,
            transactionData.txNodeCounts
        );

        dataControlContract.contractTxBatcher(
            _txIndex,
            transactionData.txContractAddrs,
            transactionData.txContractCounts
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
        Transaction storage transaction = transactions[_txIndex];

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
        returns (Transaction memory)
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
