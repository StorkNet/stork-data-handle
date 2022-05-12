// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title StorkNet's OnChain Data Control Contract
/// @author Shankar "theblushirtdude" Subramanian
/// @notice 
/// @dev Explain to a developer any extra details
contract StorkDataControlContract {

    /// @dev Only validated users can access the function
    modifier OnlyStorkNodes() {
        require(storkNodes[msg.sender].isActive == true, "Not a validator");
        _;
    }

    /// @dev Only the multi sig wallet can access these functions that update batches so that we lower gas fees
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

    /// @notice A StorkContract is a contract that uses StorkNet to decouple data from the EVM contract
    /// @dev On the creation of a StorkContract funds must be transferred that are used to compute the 
    ///      total number of transactions that it can handle
    function addStorkContract() public payable {
        require(msg.value > minStake, "Funds must be greater than 0");

        storkContracts[msg.sender] = StorkContract(msg.value / costPerTx, 0);
    }

    /// @notice Any user can further fund a StorkContract
    /// @dev Increase the funding of the StorkContract
    /// @param _storkContractAddr a parameter that is used to pass the address of the stork contract 
    ///         that is being funded
    function fundStorkContractStake(address _storkContractAddr) public payable {
        require(msg.value > minStake, "Funds must be greater than 0");

        storkContracts[_storkContractAddr].maxTxCount += msg.value / costPerTx;
    }

    /// @notice Updates the number of data storing Txs that were involved with this StorkContract
    /// @dev This function is only executable by the StorkMultiSig wallet as we treat batches of Txs as a single
    ///      transaction on the main EVM chain
    /// @param _txContractAddrs contains the list of StorkContract addresses that had any txs involving data change  
    ///        on the StorkNet that were sent to them
    function contractTxController(address[] calldata _txContractAddrs)
        public
        onlyMultiSigWallet
    {
        for (uint256 i = 0; i < _txContractAddrs.length; ++i) {
            storkContracts[_txContractAddrs[i]].txCount++;
        }
    }
}
