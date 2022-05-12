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
        uint256 txCount;
        bool isActive;
    }

    struct StorkContract {
        uint256 maxTxCount;
        uint256 txCount;
    }

    /// @notice Minimum Stake amount used to activate a validator
    /// @dev

    uint256 private minStake;
    uint256 private costPerTx;

    address public immutable multiSigWallet;

    uint256 public constant stakeHours = 86400;
    uint256 public constant stakeDays = 30;

    mapping(address => StorkNode) public storkNodes;
    mapping(address => StorkContract) public storkContracts;

    constructor(
        uint256 _minStake,
        uint256 _costPerTx,
        address _multiSigWallet
    ) {
        minStake = _minStake;
        costPerTx = _costPerTx;
        multiSigWallet = _multiSigWallet;
    }

    function addStorkNode() public payable {
        require(msg.value > minStake, "Deposit must be greater than 0");

        storkNodes[msg.sender] = StorkNode(
            msg.value,
            block.timestamp + (stakeHours * stakeDays),
            0,
            true
        );
    }

    function fundStorkNodeStake() public payable {
        require(msg.value > minStake, "Stake must be greater than 0");

        storkNodes[msg.sender].stakeValue += msg.value;
        storkNodes[msg.sender].stakeEndTime +=
            block.timestamp +
            (stakeHours * stakeDays);
    }

    function storkNodeTxController(address[] calldata txStorkAddrs)
        public
        onlyMultiSigWallet
    {
        for (uint256 i = 0; i < txStorkAddrs.length; ++i) {
            storkNodes[txStorkAddrs[i]].txCount++;
        }
    }

    // -----------------------------------------------------------------------------------------------------------------

    function addStorkContract() public payable {
        require(msg.value > minStake, "Funds must be greater than 0");

        storkContracts[msg.sender] = StorkContract(msg.value / costPerTx, 0);
    }

    function fundStorkContractStake(address _storkContractAddr) public payable {
        require(msg.value > minStake, "Funds must be greater than 0");

        storkContracts[_storkContractAddr].maxTxCount += msg.value / costPerTx;
    }

    function contractTxController(address[] calldata txContractAddrs)
        public
        onlyMultiSigWallet
    {
        for (uint256 i = 0; i < txContractAddrs.length; ++i) {
            storkContracts[txContractAddrs[i]].txCount++;
        }
    }
}
