// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title StorkNet's Stork Batching Contract
/// @author Shankar "theblushirtdude" Subramanian
/// @notice
/// @dev This client is used to manage the on-chain data of StorkClients.
contract StorkBatcher {
    /// @dev Only validated users can access the function
    modifier OnlyStorkValidators() {
        require(
            storkValidators[msg.sender].isActive == true,
            "Not a validator"
        );
        _;
    }

    /// @dev Only the multi sig wallet can access these functions that update batches so that we lower gas fees
    modifier onlyMultiSigWallet() {
        require(msg.sender == multiSigVerifierClient, "Not multi sig wallet");
        _;
    }

    /// @dev Stores data about the StorkValidators
    /// @custom: amount staked
    /// @custom: the duration till when the StorkValidator is active, after which it can get back it's stake
    /// @custom: the number of transactions handled by the StorkValidator
    /// @custom: whether or not this StorkValidator is active to handle data requests
    struct StorkValidator {
        uint256 stakeValue;
        uint256 stakeEndTime;
        uint8 txCount;
        bool isActive;
    }

    /// @dev Stores data about the StorkClients
    /// @custom: number of transactions handled for the StorkClient
    /// @custom: whether or not this StorkClient is active for data requests
    struct StorkClient {
        uint256 funds;
        uint8 txLeft;
        bool isActive;
    }

    /// @notice The minimum stake required to be a StorkValidator or StorkClient
    /// @dev The stake is used to validate Validators and also to compensate/pay Validators for transactions they handle
    uint256 public minFund;
    uint256 public minStake;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    uint256 public costPerTx;

    /// @notice Stake duration
    uint256 public constant stakeTime = 4 weeks;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public immutable multiSigVerifierClient;

    /// @notice Has the data of all StorkValidators
    /// @dev Maps an address to a StorkValidator struct containing the data about the address
    mapping(address => StorkValidator) public storkValidators;

    /// @notice Has the data of all StorkClients
    /// @dev Maps an address to a StorkClient struct containing the data about the address
    mapping(address => StorkClient) public storkClients;

    /// @notice Initializes the client
    /// @dev Sets up the client with minimum stake, cost per tx, and the address of the multi sig verifier
    /// @param _minFund The minumum stake required to be a StorkValidator or StorkClient
    /// @param _minStake The minumum stake required to be a StorkValidator or StorkClient
    /// @param _costPerTx The cost per transaction to be paid by the StorkClient
    /// @param _multiSigVerifierClient The address of the multi sig verifier

    constructor(
        uint256 _minFund,
        uint256 _minStake,
        uint256 _costPerTx,
        address _multiSigVerifierClient
    ) {
        minFund = _minFund;
        minStake = _minStake;

        costPerTx = _costPerTx;
        multiSigVerifierClient = _multiSigVerifierClient;
    }

    /// @notice Allows an address to add themselves as a Validator if they send a transaction greater than the minStake
    /// @dev If the Tx has enough funds to be a Validator, add them to the storkValidators mapping
    function addStorkValidator() external payable {
        require(
            msg.value > minStake,
            "Deposit must be greater than the minStake"
        );
        require(msg.sender != address(0), "Can't be null address");

        storkValidators[msg.sender] = StorkValidator({
            stakeValue: msg.value,
            stakeEndTime: block.timestamp + stakeTime, //gets the end time of the stake
            txCount: 0,
            isActive: true
        });

        emit ValidatorStaked(
            msg.sender,
            storkValidators[msg.sender].stakeEndTime
        );
    }

    /// @notice Increases the fund of a StorkValidator by the amount sent
    /// @dev Increases the fund of a Validator by the amount sent and also the duration of the stake
    /// @param _days Increases the duration of the stake by the number of days sent
    function fundStorkValidatorStake(uint256 _days) external payable {
        require(msg.value > 0, "Stake must be greater than 0");

        storkValidators[msg.sender].stakeValue += msg.value;

        // Extends duration of the stake by the number of days sent by converting the days to seconds
        storkValidators[msg.sender].stakeEndTime +=
            block.timestamp +
            _days *
            1 days;

        emit ValidatorStakeExtended(
            msg.sender,
            storkValidators[msg.sender].stakeEndTime
        );
    }

    /// @notice Batch update of the StorkValidator data based on the number of transactions they handled
    /// @dev Updates the count of transactions handled by the StorkValidator since the last Batch update
    /// @param _txValidatorAddrs An array of all the addresses of the StorkValidators involved in the batch Tx
    /// @param _txValidatorCounts An array of the count of Txs handled by the StorkValidators involved in the batch Tx
    function storkValidatorTxBatcher(
        address[] calldata _txValidatorAddrs,
        uint8[] calldata _txValidatorCounts
    ) external onlyMultiSigWallet {
        // Makes sure the Address array and the Address Tx count arrays are the same length
        require(
            _txValidatorAddrs.length == _txValidatorCounts.length,
            "Length of arrays must be equal"
        );

        for (uint256 i = 0; i < _txValidatorAddrs.length; ++i) {
            storkValidators[_txValidatorAddrs[i]].txCount += _txValidatorCounts[
                i
            ];
        }
    }

    // -----------------------------------------------------------------------------------------------------------------

    /// @notice Allows a Client to add themselves as a StorkClient if they send a transaction greater than minStake
    /// @dev Using the Funds received compute the max number of transactions that can be trasacted by the Client
    function addStorkClient() external payable {
        require(msg.value > minFund, "Funds must be greater than minStake");

        // Computes the max number of transactions that can be handled by the Client
        storkClients[msg.sender] = StorkClient({
            funds: msg.value,
            txLeft: uint8(msg.value / costPerTx),
            isActive: true
        });

        emit ClientCreated(msg.sender, msg.value / costPerTx);
    }

    /// @notice Any user can further fund a StorkClient
    /// @dev Increase the number of transactions of the StorkClient based on the funding
    /// @param _storkClientAddr Address of the stork client that is being funded
    function fundStorkClient(address _storkClientAddr) external payable {
        require(msg.value > 0, "Funds must be greater than 0");
        require(msg.sender != address(0), "Can't be null address");

        storkClients[_storkClientAddr].txLeft += uint8(msg.value / costPerTx);
        storkClients[_storkClientAddr].funds += msg.value;

        emit ClientFunded(
            _storkClientAddr,
            msg.value / costPerTx,
            storkClients[_storkClientAddr].txLeft
        );
    }

    /// @notice Gets pending transactions for a StorkClient
    /// @param _storkClientAddr Address of the stork client that is being funded
    /// @return The number of transactions left for the Client to consume
    function txLeftStorkClient(address _storkClientAddr)
        external
        view
        returns (uint256)
    {
        return (storkClients[_storkClientAddr].txLeft);
    }

    /// @notice Batch update of the StorkClients based on the number of transactions they were involved with
    /// @dev Updates the number of transactions that a StorkClient can handle after this batch update
    /// @param txId The id of the batch Tx
    /// @param _txClientAddrs An array of the StorkClients involved in the batch Tx
    /// @param _txClientCounts An array of the count of Txs handled for the StorkClients involved in the batch Tx
    function clientTxBatcher(
        uint16 txId,
        address[] calldata _txClientAddrs,
        uint8[] calldata _txClientCounts
    ) external onlyMultiSigWallet {
        // Probably not needed because of processing on the StorkNet

        /// @notice Checks if the batch went smoothly without any clients involved in errors
        /// @dev If a StorkClient has run out of Txs, emit a error event stating the same
        bool txBatchingClean = true;

        for (uint256 i = 0; i < _txClientAddrs.length; ++i) {
            // Checks if the StorkClient has run out of Txs
            if (storkClients[_txClientAddrs[i]].txLeft > _txClientCounts[i]) {
                // If it has, emit an event
                emit ClientOutOfFund(txId, _txClientAddrs[i]);
                txBatchingClean = false;
            }

            // Updates the number of transactions left for the StorkClient
            storkClients[_txClientAddrs[i]].txLeft -= _txClientCounts[i];
        }

        emit BatchUpdate(txId, txBatchingClean);
    }

    // -----------------------------------------------------------------------------------------------------------------

    /// @notice Changes the minimum transaction cost for a StorkClient
    /// @dev Sets the new costPerTx
    /// @param _newCostPerTx The new costPerTx
    function changeTxCost(uint256 _newCostPerTx) external onlyMultiSigWallet {
        costPerTx = _newCostPerTx;
        emit NewCostPerTx(_newCostPerTx);
    }

    /// @notice Changes the minimum stake for a StorkClient or StorkValidator
    /// @dev Sets the new minimum stake
    /// @param _newMinStake The new minimum stake
    function changeMinStake(uint256 _newMinStake) external onlyMultiSigWallet {
        minStake = _newMinStake;
        emit NewMinStake(_newMinStake);
    }

    /// @notice Changes the minimum stake for a StorkClient or StorkValidator
    /// @dev Sets the new minimum stake
    /// @param _newMinFund The new minimum stake
    function changeMinFund(uint256 _newMinFund) external onlyMultiSigWallet {
        minFund = _newMinFund;
        emit NewMinFund(_newMinFund);
    }

    /// @notice Returns the minimum stake
    /// @dev Sets the new minimum stake
    /// @return minStake
    function getMinStakeValue() external view returns (uint256) {
        return (minStake);
    }

    /// @notice Returns the minimum stake
    /// @dev Sets the new minimum stake
    /// @return minStake
    function getMinFundValue() external view returns (uint256) {
        return (minFund);
    }

    /// @notice Returns the minimum stake
    /// @dev Sets the new minimum stake
    /// @return minStake
    function getMultiSigAddr() external view returns (address) {
        return (multiSigVerifierClient);
    }

    /// @notice Fallback function to receive funds
    fallback() external payable {}

    /// @notice Fallback function to receive funds
    /// @dev Emits a deposit event
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

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
