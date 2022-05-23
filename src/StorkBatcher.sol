// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title StorkNet's Stork Batching Contract
/// @author Shankar "theblushirtdude" Subramanian
/// @notice
/// @dev This client is used to manage the on-chain data of StorkClients.
contract MultiSigVerification {
    function submitTransaction(
        uint256 _batchIndex,
        bytes32 _validatorCheck,
        address _minerAddr,
        bytes32 _batchHash,
        bytes32[] calldata _txHash,
        uint8 _batchConfirmationsRequired,
        string calldata _cid
    ) external {}
}

contract StorkBatcher {
    /// @dev Only validated users can access the function
    modifier OnlyValidators() {
        require(storkValidators[msg.sender] > 0, "Not a validator");
        _;
    }
    /// @dev Only validated users can access the function
    modifier OnlyStorkStake() {
        require(msg.sender == storkStakeAddr, "Not the storkStakeAddr");
        _;
    } /// @dev Only validated users can access the function
    modifier OnlyStorkFund() {
        require(msg.sender == storkFundAddr, "Not the storkFundAddr");
        _;
    }
    /// @dev Only the multi sig wallet can access these functions that update batches so that we lower gas fees
    modifier onlyMultiSigWallet() {
        require(msg.sender == multiSigVerifierAddr, "Not multi sig wallet");
        _;
    }

    struct BatchTransaction {
        address batchMiner;
        // those that have confirmed
        address[] batchValidators;
        bytes32 validatorCheck;
        // hash of batchindex, batchMiner, txHash
        bytes32 batchHash;
        // Tx array becomes keccak256(abi.encodePacked()) gets hashed keccak256(abi.encodePacked())
        bytes32 txHash;
        uint8 batchConfirmationsRequired; // 0 not create, 1 validated, >1 not fully confirmed
        string batchCid;
        bool isBatchCreated;
        bool isBatchExecuted;
    }

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public multiSigVerifierAddr;
    MultiSigVerification public multiSigVerifier;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public storkStakeAddr;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public storkFundAddr;

    /// @notice Has the data of all StorkValidators
    /// @dev Maps an address to a StorkValidator struct containing the data about the address
    mapping(address => uint256) public storkValidators;

    /// @notice Has the data of all StorkClients
    /// @dev Maps an address to a StorkClient struct containing the data about the address
    mapping(address => uint256) public storkClients;

    /// @notice Has the data of all StorkClients
    /// @dev Maps an address to a StorkClient struct containing the data about the address
    mapping(uint256 => BatchTransaction) public Txs;

    function setMultiSigVerifierContract(address _multiSigVerifierAddr) public {
        require(multiSigVerifierAddr == address(0), "msvc already set");
        multiSigVerifierAddr = _multiSigVerifierAddr;
        multiSigVerifier = MultiSigVerification(_multiSigVerifierAddr);
    }

    function setStorkStakeContract(address _storkStake) public {
        require(storkStakeAddr == address(0), "stake contract already set");
        storkStakeAddr = _storkStake;
    }

    function setStorkFundContract(address _storkFund) public {
        require(storkFundAddr == address(0), "fund contract already set");
        storkFundAddr = _storkFund;
    }

    function submitTransaction(
        uint256 _batchIndex,
        bytes32 _validatorCheck,
        address _batchMiner,
        bytes32 _batchHash,
        bytes32[] calldata _txHash,
        uint8 _batchNumConfirmationsPending,
        string calldata _cid
    ) public OnlyValidators {
        require(Txs[_batchIndex].isBatchCreated == false, "tx already exists");
        bytes32 txHashed = keccak256(abi.encodePacked(_txHash));
        bytes32 batchHash = keccak256(
            abi.encodePacked(_batchIndex, _batchMiner, txHashed, _cid)
        );

        require(
            _batchHash == batchHash,
            "msg.sender is not the approved miner"
        );

        Txs[_batchIndex] = BatchTransaction(
            _batchMiner,
            new address[](0),
            _validatorCheck,
            _batchHash,
            txHashed,
            _batchNumConfirmationsPending,
            _cid,
            true,
            false
        );
        multiSigVerifier.submitTransaction(
            _batchIndex,
            _validatorCheck,
            _batchMiner,
            _batchHash,
            _txHash,
            _batchNumConfirmationsPending,
            _cid
        );
        emit TransactionSubmitted(_batchIndex, msg.sender, batchHash);
    }

    function txAllowExecuteBatching(
        uint256 _txIndex,
        address[] calldata validators
    ) external onlyMultiSigWallet {
        Txs[_txIndex].batchValidators = validators;
        emit ReadyToExecute(_txIndex);
    }

    function txExecuteBatching(
        uint256 _batchIndex,
        address[] calldata _contracts,
        address[] calldata _validators,
        uint8[] calldata _contractTxCounts,
        uint8[] calldata _validatorTxCounts,
        bytes32[] calldata _txHash
    ) external OnlyValidators {
        for (uint8 i = 0; i < _txHash.length; i++) {
            if (
                _txHash[i] ==
                keccak256(
                    abi.encodePacked(
                        _contracts[i],
                        _validators[i],
                        _contractTxCounts[i],
                        _validatorTxCounts[i]
                    )
                )
            ) {
                storkClients[_contracts[i]] -= _contractTxCounts[i];
                storkValidators[_validators[i]] += _validatorTxCounts[i];
            }
        }
        Txs[_batchIndex].isBatchExecuted = true;
    }

    function setStorkValidator(address _storkValidator)
        external
        OnlyStorkStake
    {
        storkValidators[_storkValidator] = 1;
    }

    function setStorkClient(address _storkContract, uint256 txCount)
        external
        OnlyStorkFund
    {
        storkClients[_storkContract] += txCount;
    }

    /// @notice Gets pending transactions for a StorkClient
    /// @param _storkClientAddr Address of the stork client that is being funded
    /// @return The number of transactions left for the Client to consume

    /// @notice Returns the minimum stake
    /// @dev Sets the new minimum stake
    /// @return minStake

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (BatchTransaction memory)
    {
        return (Txs[_txIndex]);
    }

    /// @notice Fallback function to receive funds
    fallback() external payable {}

    /// @notice Fallback function to receive funds
    /// @dev Emits a deposit event
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    event ReadyToExecute(uint256 indexed _txIndex);
    /// @notice Event for when any ETH is deposited in the client
    /// @dev When a deposit occurs emit this event
    /// @param addr The address depositing the ETH
    /// @param value The value of the deposit
    event Deposit(address indexed addr, uint256 value);

    /// @notice The updated cost per Tx
    /// @dev When a the cost per Tx is updated emit this event
    /// @param newCostPerTx The new cost per Tx
    event NewCostPerTx(uint256 indexed newCostPerTx);

    /// @notice The updated minimum stake
    /// @dev When the minimum stake is updated emit this event
    /// @param newMinStake The new minimum stake
    event NewMinStake(uint256 indexed newMinStake);

    /// @notice The updated minimum fund
    /// @dev When the minimum stakefund is updated emit this event
    /// @param newMinFund The new minimum fund
    event NewMinFund(uint256 indexed newMinFund);

    /// @notice The creation of a new StorkValidator
    /// @dev When a StorkValidator is created, emit this event
    /// @param newValidator The address of the new StorkValidator
    /// @param time The stake duration of the created StorkValidator
    event ValidatorStaked(address indexed newValidator, uint256 time);

    /// @notice The updated stake duration of a StorkValidator
    /// @dev When a StorkValidator's stake duration is updated my sending a new value, emit this event
    /// @param newValidator The address of the new StorkValidator
    /// @param newTime The new stake duration of the StorkValidator
    event ValidatorStakeExtended(address indexed newValidator, uint256 newTime);

    /// @notice The creation of a new StorkClient
    /// @dev When a StorkClient is created, emit this event
    /// @param newClient The address of the new StorkClient
    /// @param txLeft The fund value of the new StorkClient in terms of Txs
    event ClientCreated(address indexed newClient, uint256 txLeft);

    /// @notice The updated fund value of a StorkClient in terms of Txs left
    /// @dev When the fund value of a StorkClient is increased, increase the Txs Left and emit this event
    /// @param oldClient a parameter just like in doxygen (must be followed by parameter name)
    /// @param txLeft The increase in fund value of the new StorkClient in terms of Txs
    /// @param newFundTotal The new fund value of the new StorkClient in terms of Txs
    event ClientFunded(
        address indexed oldClient,
        uint256 txLeft,
        uint256 newFundTotal
    );

    event TransactionSubmitted(
        uint256 indexed _txIndex,
        address indexed _submitter,
        bytes32 indexed _txKeccaked
    );

    /// @notice Event to tell the status of the batch update
    /// @dev If the batch update went smoothly or with errors, emit this event
    /// @param txId The transaction ID of the batch update
    /// @param updateStatus Status updates of true if smooth else false
    event BatchUpdate(uint256 indexed txId, bool indexed updateStatus);

    /// @notice Tells if the client has run out of funds
    /// @dev If the client does not have enough funds to handle more Txs in the current batch update, emit this event
    /// @param txId The transaction ID of the batch update
    /// @param clientOnLowFund The address of the StorkClient that ran out of funds
    event ClientOutOfFund(
        uint256 indexed txId,
        address indexed clientOnLowFund
    );
}
