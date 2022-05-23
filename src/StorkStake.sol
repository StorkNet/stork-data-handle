// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorkBatcher {
    function setStorkValidator(address _storkValidator) external {}
}

contract StorkStake {
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
        require(msg.sender == storkBatcherAddr, "Not multi sig wallet");
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

    /// @notice The minimum stake required to be a StorkValidator or StorkClient
    /// @dev The stake is used to validate Validators and also to compensate/pay Validators for transactions they handle
    uint256 public minStake;

    /// @notice Stake duration
    uint256 public constant stakeTime = 4 weeks;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    StorkBatcher public immutable storkBatcher;
    address public immutable storkBatcherAddr;

    /// @notice Has the data of all StorkValidators
    /// @dev Maps an address to a StorkValidator struct containing the data about the address
    mapping(address => StorkValidator) public storkValidators;

    /// @notice Initializes the client
    /// @dev Sets up the client with minimum stake, cost per tx, and the address of the multi sig verifier
    /// @param _minStake The minumum stake required to be a StorkValidator or StorkClient
    /// @param _storkBatcherAddr The address of the multi sig verifier
    constructor(uint256 _minStake, address _storkBatcherAddr) {
        minStake = _minStake * 1 gwei;
        storkBatcherAddr = _storkBatcherAddr;
        storkBatcher = StorkBatcher(_storkBatcherAddr);
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
            txCount: 1,
            isActive: true
        });

        storkBatcher.setStorkValidator(msg.sender);

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

    /// @notice Changes the minimum stake for a StorkClient or StorkValidator
    /// @dev Sets the new minimum stake
    /// @param _newMinStake The new minimum stake
    function changeMinStake(uint256 _newMinStake) external onlyMultiSigWallet {
        minStake = _newMinStake;
        emit NewMinStake(_newMinStake);
    }

    /// @notice Returns the minimum stake
    /// @dev Sets the new minimum stake
    /// @return minStake
    function getMinStakeValue() external view returns (uint256) {
        return (minStake);
    }

    function isValidator(address _address) external view returns (bool) {
        return storkValidators[_address].isActive;
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

    /// @notice The updated minimum stake
    /// @dev When the minimum stake is updated emit this event
    /// @param newMinStake The new minimum stake
    event NewMinStake(uint256 indexed newMinStake);

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
}
