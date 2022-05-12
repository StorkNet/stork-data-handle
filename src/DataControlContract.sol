// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title
/// @author Shankar
/// @notice Here we have a contract that will be used to control the payments and data transfer requests to the
///         StorkNet network.
/// @dev Explain to a developer any extra details
contract StorkDataControlContract {
    modifier OnlyStorkNodes() {
        require(storkNodes[msg.sender].isActive == true, "Not a validator");
        _;
    }

    modifier onlyMultiSigWallet() {
        require(msg.sender == multiSigWallet, "Not multi sig wallet");
        _;
    }

    struct StorkNode {
        uint256 stakeValue;
        uint256 stakeEndTime;
        uint32 txCount;
        bool isActive;
    }

    /// @notice Minimum Stake amount used to activate a validator
    /// @dev

    uint256 private minStake;
    address public immutable multiSigWallet;

    uint256 public constant stakeHours = 86400;
    uint256 public constant stakeDays = 30;

    mapping(address => StorkNode) public storkNodes;

    constructor(uint256 _minStake, address _multiSigWallet) {
        minStake = _minStake;
        multiSigWallet = _multiSigWallet;
    }

    function addValidator() public payable {
        require(msg.value > minStake, "Deposit must be greater than 0");

        storkNodes[msg.sender] = StorkNode(
            msg.value,
            block.timestamp + (stakeHours * stakeDays),
            0,
            true
        );
    }

    function increaseStake() public payable {
        require(msg.value > minStake, "Deposit must be greater than 0");

        storkNodes[msg.sender].stakeValue += msg.value;
        storkNodes[msg.sender].stakeEndTime +=
            block.timestamp +
            (stakeHours * stakeDays);
    }

    function increaseTxCount(address[] calldata txAddrs) public onlyMultiSigWallet {
        for(uint i = 0; i < txAddrs.length; ++i) {
            storkNodes[txAddrs[i]].txCount++;
        }
    }
}
