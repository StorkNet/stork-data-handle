#!/usr/bin/env bash

# Read the contract name
echo Which contract do you want to deploy \(eg Greeter\)?
read contract

# Read the constructor arguments
echo Enter constructor arguments separated by spaces \(eg 1 2 3\):
read -ra args

forge create ./src/${contract}.sol:${contract} -i --rpc-url "http://localhost:8545" --constructor-args ${args}
