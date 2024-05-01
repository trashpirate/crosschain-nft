-include .env

.PHONY: all test clean deploy

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# install dependencies
install :; forge install foundry-rs/forge-std --no-commit && forge install Cyfrin/foundry-devops --no-commit && forge install https://github.com/chiru-labs/ERC721A.git --no-commit && forge install OpenZeppelin/openzeppelin-contracts --no-commit && forge install https://github.com/smartcontractkit/ccip@ccip-develop --no-commit

# update dependencies
update:; forge update

# compile
build:; forge build

# test
test :; forge test 

# test coverage
coverage:; @forge coverage --contracts src
coverage-report:; @forge coverage --contracts src --report debug > coverage.txt

# take snapshot
snapshot :; forge snapshot

# format
format :; forge fmt

# spin up local test network
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# spin up fork
fork-bsc :; @anvil --fork-url ${RPC_BSC_MAIN} --fork-block-number 38005080 --fork-chain-id 56 --chain-id 123
fork-base :; @anvil --fork-url ${RPC_BASE_MAIN} --fork-block-number 13383370 --fork-chain-id 8453 --chain-id 123

# deployment
deploy-local: 
	@forge script script/deployment/DeployCrossChainNFT.s.sol:DeployCrossChainNFT --rpc-url localhost --private-key ${DEFAULT_ANVIL_KEY} --broadcast 
deploy-destination-local: 
	@forge script script/deployment/DeployDestinationMinter.s.sol:DeployDestinationMinter --rpc-url localhost --private-key ${DEFAULT_ANVIL_KEY} --broadcast

deploy-token-testnet: 
	@forge script script/deployment/DeployERC20Token.s.sol:DeployERC20Token --rpc-url $(RPC_BSC_TEST) --account Test-Deployer --sender 0x11f392ba82c7d63bfdb313ca63372f6de21ab448 --broadcast --verify --etherscan-api-key $(BSCSCAN_KEY)
deploy-source-testnet: 
	@forge script script/deployment/DeploySourceMinter.s.sol:DeploySourceMinter --rpc-url $(RPC_BSC_TEST) --account Test-Deployer --sender 0x11f392ba82c7d63bfdb313ca63372f6de21ab448 --broadcast --verify --etherscan-api-key $(BSCSCAN_KEY)
deploy-destination-testnet: 
	@forge script script/deployment/DeployDestinationMinter.s.sol:DeployDestinationMinter --rpc-url $(RPC_BASE_SEPOLIA) --account Test-Deployer --sender 0x11f392ba82c7d63bfdb313ca63372f6de21ab448 --broadcast --verify --etherscan-api-key $(BASESCAN_SEPOLIA_KEY) -vvvv

deploy-source-mainnet: 
	@forge script script/deployment/DeploySourceMinter.s.sol:DeploySourceMinter --rpc-url $(RPC_BSC_MAIN) --account Queens-Deployer --sender 0xe4a930c9E0B409572AC1728a6dCa3f4af775b5e0 --broadcast --verify --etherscan-api-key $(BSCSCAN_KEY)
deploy-destination-mainnet: 
	@forge script script/deployment/DeployDestinationMinter.s.sol:DeployDestinationMinter --rpc-url $(RPC_BASE_MAIN) --account Queens-Deployer --sender 0xe4a930c9E0B409572AC1728a6dCa3f4af775b5e0 --broadcast --verify --etherscan-api-key $(BASESCAN_KEY) -vvvv

mint-testnet:
	@forge script script/interactions/Interactions.s.sol:MintNft --rpc-url $(RPC_BSC_TEST) --account Test-Deployer --sender 0x11f392ba82c7d63bfdb313ca63372f6de21ab448 --broadcast


# security
slither :; slither ./src 


-include ${FCT_PLUGIN_PATH}/makefile-external