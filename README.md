StorkStake 

Handles the staking of a new validator, it allows for changing the stake amount and for stakers to withdraw or stake more should they want to.

StorkFund 

Is where contracts or clients fund their contract with some tokens so that StorkNet can consume some for each transaction based on the cost of a particular query. 

StorkBlockRollup

Is where the StorkClients deposit the blocks generated by the StorkChain, it validates it and sends it to the multisigverification where they are evaluated and the token balances of the validators involved are increased while the clients are reduced based on the actions they've performed

MultiSigVerification

Validates the block by checking the transaction proofs, the validator proofs, the block proofs, etc. It also allows the validators to revoke a block. 
