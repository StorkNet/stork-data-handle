// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title
/// @author Shankar
/// @notice Here we have a contract that will be used to control the payments and data transfer requests to the
///         StorkNet network.
/// @dev Explain to a developer any extra details
contract StorkDataControlContract {
    modifier OnlyValidators() {
        require(validators[msg.sender].isActive == true, "Not a validator");
        _;
    }

    modifier onlyMultiSigWallet() {
        require(msg.sender == multiSigWallet, "Not multi sig wallet");
        _;
    }

    struct Validator {
        bool isActive;
        uint256 stakeValue;
        uint256 stakeEndTime;
        uint256 transactionCount;
    }

    /// @notice Minimum Stake amount used to activate a validator
    /// @dev

    uint256 private minStake;
    address public immutable multiSigWallet;

    uint256 public constant stakeHours = 86400;
    uint256 public constant stakeDays = 30;

    mapping(address => Validator) public validators;

    constructor(uint256 _minStake, address _multiSigWallet) {
        minStake = _minStake;
        multiSigWallet = _multiSigWallet;
    }

    function addValidator() public payable {
        require(msg.value > minStake, "Deposit must be greater than 0");

        validators[msg.sender] = Validator(
            true,
            msg.value,
            block.timestamp + (stakeHours * stakeDays),
            0
        );
    }

    function increaseStake() public payable {
        uint256 newStakeValue = validators[msg.sender].stakeValue + msg.value;

        uint256 newStakeEnd = validators[msg.sender].stakeEndTime +
            block.timestamp +
            (stakeHours * stakeDays);

        validators[msg.sender].stakeValue = newStakeValue;
        validators[msg.sender].stakeEndTime = newStakeEnd;
    }

    function increaseTransactionCount() public onlyMultiSigWallet {
        validators[msg.sender].transactionCount++;
    }
}
