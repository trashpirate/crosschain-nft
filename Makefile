-include .env

.PHONY: all test clean deploy

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# install dependencies
install :; forge install Cyfrin/foundry-devops --no-commit && forge install https://github.com/chiru-labs/ERC721A.git --no-commit && forge install OpenZeppelin/openzeppelin-contracts --no-commit && forge install https://github.com/smartcontractkit/ccip.git@ccip-develop --no-commit

# update dependencies
update:; forge update

# compile
build:; forge build

# test
test :; forge test 

# take snapshot
snapshot :; forge snapshot

# format
format :; forge fmt

# spin up local test network
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# spin up fork
fork :; @anvil --fork-url ${RPC_BSC} --fork-block-number 35267180 --fork-chain-id 56 --chain-id 123

# deployment
deploy-testnet: 
	@forge script script/deployment/DeployTurboTails.s.sol:DeployTurboTails --rpc-url $(RPC_BSC_TEST) --account Testing --sender 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF --broadcast --verify --etherscan-api-key $(BSCSCAN_KEY)
	
# security
slither :; slither ./src 


-include ${FCT_PLUGIN_PATH}/makefile-external