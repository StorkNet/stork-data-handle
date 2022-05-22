// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract StorkFund {

    /// @dev Only the multi sig wallet can access these functions that update batches so that we lower gas fees
    modifier onlyMultiSigWallet() {
        require(msg.sender == multiSigVerifierClient, "Not multi sig wallet");
        _;
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

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    uint256 public costPerTx;

    /// @notice The cost per transaction to be paid by the StorkClient
    /// @dev Reduces the amount staked by the StorkClient
    address public immutable multiSigVerifierClient;

    /// @notice Has the data of all StorkClients
    /// @dev Maps an address to a StorkClient struct containing the data about the address
    mapping(address => StorkClient) public storkClients;

    /// @notice Initializes the client
    /// @dev Sets up the client with minimum stake, cost per tx, and the address of the multi sig verifier
    /// @param _minFund The minumum stake required to be a StorkValidator or StorkClient
    /// @param _costPerTx The cost per transaction to be paid by the StorkClient
    /// @param _multiSigVerifierClient The address of the multi sig verifier

    constructor(
        uint256 _minFund,
        uint256 _costPerTx,
        address _multiSigVerifierClient
    ) {
        minFund = _minFund;
        costPerTx = _costPerTx;
        multiSigVerifierClient = _multiSigVerifierClient;
    }


    /// @notice Changes the minimum transaction cost for a StorkClient
    /// @dev Sets the new costPerTx
    /// @param _newCostPerTx The new costPerTx
    function changeTxCost(uint256 _newCostPerTx) external onlyMultiSigWallet {
        costPerTx = _newCostPerTx;
        emit NewCostPerTx(_newCostPerTx);
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
    function getMinFundValue() external view returns (uint256) {
        return (minFund);
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

    /// @notice The updated minimum fund
    /// @dev When the minimum stakefund is updated emit this event
    /// @param newMinFund The new minimum fund
    event NewMinFund(uint256 indexed newMinFund);

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
}