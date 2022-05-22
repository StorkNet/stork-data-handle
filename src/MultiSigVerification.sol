// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract StorkBatcher {}

contract StorkStake {
    function isValidator(address _address) external view returns (bool) {}
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
        require(storkStake.isValidator(msg.sender) == true, "Not a validator");
        _;
    }
    modifier OnlyStorkStake() {
        require(
            msg.sender == storkStakeContract.contractAddress,
            "Not the storkStakeAddr"
        );
        _;
    }
    modifier OnlyStorkFund() {
        require(
            msg.sender == storkFundContract.contractAddress,
            "Not the storkStakeAddr"
        );
        _;
    }
    modifier onlyBatcher() {
        require(
            msg.sender == storkBatcherContract.contractAddress,
            "Not multi sig wallet"
        );
        _;
    }

    modifier validatorNotConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    struct Tx {
        bool hasFallback;
        address txMiner;
        string cid;
    }

    struct BatchTransaction {
        address batchMiner;
        // hash of batchindex, batchMiner, txHash
        bytes32 batchHash;
        // Tx array becomes keccak256(abi.encodePacked()) gets hashed keccak256(abi.encodePacked())
        bytes32 txHash;
        uint8 batchConfirmationsRequired; // 0 not create, 1 validated, >1 not fully confirmed
        bool isBatchExecuted;
    }

    struct Contract {
        address contractAddress;
        bool isSet;
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

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    Contract public storkBatcherContract;
    StorkBatcher public storkBatcher;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    Contract public storkStakeContract;
    StorkStake public storkStake;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    Contract public storkFundContract;
    StorkFund public storkFund;

    constructor() {}

    function setStorkBatcherContract(address payable _storkBatcher) public {
        require(!storkBatcherContract.isSet, "client already set");
        storkBatcherContract.contractAddress = _storkBatcher;
        storkBatcher = StorkBatcher(_storkBatcher);
    }

    function setStorkStakeContract(address payable _storkStake) public {
        require(!storkStakeContract.isSet, "stake contract already set");
        storkStakeContract.contractAddress = _storkStake;
        storkStake = StorkStake(_storkStake);
    }

    function setStorkFundContract(address payable _storkFund) public {
        require(!storkFundContract.isSet, "fund contract already set");
        storkFundContract.contractAddress = _storkFund;
        storkFund = StorkFund(_storkFund);
    }

    function submitTransaction(
        uint256 _batchIndex,
        address _minerAddr,
        bytes32 _batchHash,
        bytes32[] calldata _txHash,
        uint8 _batchConfirmationsRequired
    ) public onlyValidators validatorNotConfirmed(_batchIndex) {
        require(
            batchTransactions[_batchIndex].batchConfirmationsRequired == 0,
            "tx already exists"
        );

        bytes32 txHashed = keccak256(abi.encodePacked(_txHash));

        if (msg.sender == storkBatcherContract.contractAddress) {
            if (batchTransactions[_batchIndex].batchConfirmationsRequired > 0) {
                batchTransactions[_batchIndex].batchMiner = _minerAddr;
                isConfirmed[_batchIndex][msg.sender] = true;
                batchTransactions[_batchIndex].batchConfirmationsRequired--;
            } else {
                createNewTransaction(
                    _batchIndex,
                    msg.sender,
                    _batchHash,
                    txHashed,
                    _batchConfirmationsRequired
                );
            }
        } else {
            if (batchTransactions[_batchIndex].batchConfirmationsRequired > 0) {
                isConfirmed[_batchIndex][msg.sender] = true;
                batchTransactions[_batchIndex].batchConfirmationsRequired--;
            } else {
                createNewTransaction(
                    _batchIndex,
                    address(0),
                    _batchHash,
                    txHashed,
                    _batchConfirmationsRequired
                );
            }
        }

        emit SubmitTransaction(_batchIndex, msg.sender);
    }

    function createNewTransaction(
        uint256 _batchIndex,
        address _minerAddr,
        bytes32 _batchHash,
        bytes32 _txHash,
        uint8 _batchConfirmationsRequired
    ) internal {
        batchTransactions[_batchIndex] = BatchTransaction({
            batchMiner: _minerAddr,
            batchHash: _batchHash,
            txHash: _txHash,
            batchConfirmationsRequired: _batchConfirmationsRequired,
            isBatchExecuted: false
        });
    }

    // function confirmTransaction(uint256 _txIndex)
    //     public
    //     onlyValidator
    //     txConfirmed(_txIndex, false)
    //     txNotExecuted(_txIndex)
    //     txExists(_txIndex)
    //     validatorNotConfirmed(_txIndex)
    // {
    //     BatchTransaction storage transaction = batchTransactions[_txIndex];

    //     // keccack256 converts the input to bytes32 constant size
    //     transaction.batchValidatorCheck ^= keccak256(
    //         abi.encodePacked(msg.sender)
    //     );
    //     transaction.batchNumConfirmationsPending--;
    //     transaction.batchValidators.push(msg.sender);
    //     isConfirmed[_txIndex][msg.sender] = true;

    //     emit ConfirmTransaction(
    //         _txIndex,
    //         msg.sender,
    //         transaction.batchNumConfirmationsPending
    //     );
    // }

    // function executeTransaction(uint8 _txIndex)
    //     public
    //     payable
    //     onlyValidator
    //     txConfirmed(_txIndex, true)
    //     txExists(_txIndex)
    //     txNotExecuted(_txIndex)
    // {
    //     BatchTransaction memory transaction = batchTransactions[_txIndex];

    //     if (transaction.batchValidatorCheck != bytes32(0)) {
    //         emit InvalidValidators(_txIndex);
    //         return;
    //     }

    //     Tx[] memory transactions = transaction.transactions;

    //     storkBatcherContract.txBatching(_txIndex, transactions);

    //     batchTransactions[_txIndex].isExecuted = true;

    //     emit ExecuteTransaction(_txIndex, msg.sender);
    // }

    // function revokeConfirmation(uint256 _txIndex)
    //     public
    //     onlyValidator
    //     txExists(_txIndex)
    //     txNotExecuted(_txIndex)
    // {
    //     BatchTransaction memory transaction = batchTransactions[_txIndex];

    //     require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

    //     transaction.numConfirmations--;
    //     transaction.validatorCheck ^= keccak256(abi.encodePacked(msg.sender));
    //     isConfirmed[_txIndex][msg.sender] = false;

    //     batchTransactions[_txIndex] = transaction;
    //     emit RevokeConfirmation(_txIndex, msg.sender);
    // }

    // function getValidators() public view returns (address[] memory) {
    //     return validators;
    // }

    // function getTransactionCount() public view returns (uint256) {
    //     return txCount;
    // }

    // function getTransaction(uint256 _txIndex)
    //     public
    //     view
    //     returns (BatchTransaction memory)
    // {
    //     return (batchTransactions[_txIndex]);
    // }

    // function getMinerOfTx(uint256 _txIndex) public view returns (address) {
    //     return (batchTransactions[_txIndex].miner);
    // }

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
