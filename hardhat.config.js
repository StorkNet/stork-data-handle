/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            // If you want to do some forking set `enabled` to true
            forking: {
                url: "https://localhost:8545",
                // blockNumber: FORKING_BLOCK_NUMBER,
                enabled: false,
            },
            chainId: 31337,
        },
    },
    solidity: "0.8.11",
}
