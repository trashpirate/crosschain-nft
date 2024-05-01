// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";
import {SourceMinter} from "./../../src/SourceMinter.sol";
import {DestinationMinter} from "./../../src/DestinationMinter.sol";
import {MockCCIPRouter} from "../../test/mocks/MockCCIPRouter.sol";

contract HelperConfig is Script {
    /** NFT CONFIG - UDPATE BEFORE DEPLOYMENT !!! */
    uint256 public constant TOKEN_FEE = 1_000_000 ether;
    uint256 public constant ETH_FEE = 0.2 ether;
    uint256 public constant MAX_SUPPLY = 52;
    uint256 public constant MAX_PER_WALLET = 52;
    uint256 public constant BATCH_LIMIT = 1;

    string public constant BASE_URI =
        "ipfs://bafybeifmubmzo44kp7txputm72okodpyihencmlzstgyweyqpi7rn7eyzu/";

    string public constant CONTRACT_URI =
        "ipfs://bafybeifsfbuyz2fesqc47tq5bxu5pksojaq3zdkeucljwemdbtm56nks6i/contractMetadata";

    uint96 public constant ROYALTY_NUMERATOR = 500;

    /** MAINNET - UDPATE BEFORE DEPLOYMENT !!! */
    string public constant NAME = "Randomized NFT";
    string public constant SYMBOL = "RANDNFT";
    address public constant FEE_ADDRESS_MAIN =
        0xe4a930c9E0B409572AC1728a6dCa3f4af775b5e0;
    address public constant TOKEN_ADDRESS_MAIN =
        0x45e26B10Ae6f95d9d5133720937693E17171F7F9;

    /** TESTNET */
    address public constant FEE_ADDRESS_TEST =
        0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF;
    address public constant TOKEN_ADDRESS_TEST =
        0x563F5a7fa101dD7051853604ec63103Ab6226c7b;

    /** LOCAL */
    address public constant FEE_ADDRESS_LOCAL =
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public constant TOKENOWNER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // chain configurations
    NetworkConfig public activeNetworkConfig;

    function getActiveNetworkConfigStruct()
        public
        view
        returns (NetworkConfig memory)
    {
        return activeNetworkConfig;
    }

    struct NetworkConfig {
        SourceMinter.ConstructorArguments sourceArgs;
        RandomizedNFT.ConstructorArguments nftArgs;
        address destinationRouter;
    }

    constructor() {
        if (
            block.chainid == 1 /** ethereum */ ||
            block.chainid == 56 /** bsc */ ||
            block.chainid == 8453 /** base */
        ) {
            activeNetworkConfig = getMainnetConfig();
        } else if (
            block.chainid == 11155111 /** sepolia */ ||
            block.chainid == 97 /** bsc testnet */ ||
            block.chainid == 84532 /** base sepolia */
        ) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                sourceArgs: SourceMinter.ConstructorArguments({
                    router: 0xE1053aE1857476f36A3C62580FF9b016E8EE8F6f,
                    chainSelector: 10344971235874465080,
                    tokenAddress: TOKEN_ADDRESS_TEST,
                    feeAddress: FEE_ADDRESS_TEST,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    maxSupply: MAX_SUPPLY
                }),
                nftArgs: RandomizedNFT.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    royaltyNumerator: ROYALTY_NUMERATOR,
                    maxPerWallet: MAX_PER_WALLET,
                    batchLimit: BATCH_LIMIT,
                    maxSupply: MAX_SUPPLY
                }),
                destinationRouter: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93
            });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                sourceArgs: SourceMinter.ConstructorArguments({
                    router: 0x34B03Cb9086d7D758AC55af71584F81A598759FE,
                    chainSelector: 15971525489660198786,
                    tokenAddress: TOKEN_ADDRESS_MAIN,
                    feeAddress: FEE_ADDRESS_MAIN,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    maxSupply: MAX_SUPPLY
                }),
                nftArgs: RandomizedNFT.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    royaltyNumerator: ROYALTY_NUMERATOR,
                    maxPerWallet: MAX_PER_WALLET,
                    batchLimit: BATCH_LIMIT,
                    maxSupply: MAX_SUPPLY
                }),
                destinationRouter: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD
            });
    }

    function getLocalForkConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                sourceArgs: SourceMinter.ConstructorArguments({
                    router: 0x34B03Cb9086d7D758AC55af71584F81A598759FE,
                    chainSelector: 15971525489660198786,
                    tokenAddress: TOKEN_ADDRESS_MAIN,
                    feeAddress: FEE_ADDRESS_LOCAL,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    maxSupply: MAX_SUPPLY
                }),
                nftArgs: RandomizedNFT.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    royaltyNumerator: ROYALTY_NUMERATOR,
                    maxPerWallet: MAX_PER_WALLET,
                    batchLimit: BATCH_LIMIT,
                    maxSupply: MAX_SUPPLY
                }),
                destinationRouter: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // Deploy mock contracts
        vm.startBroadcast();
        ERC20Token token = new ERC20Token();
        MockCCIPRouter sourceRouter = new MockCCIPRouter();
        MockCCIPRouter destinationRouter = new MockCCIPRouter();
        vm.stopBroadcast();

        return
            NetworkConfig({
                sourceArgs: SourceMinter.ConstructorArguments({
                    router: address(sourceRouter),
                    chainSelector: 10344971235874465080,
                    tokenAddress: address(token),
                    feeAddress: FEE_ADDRESS_LOCAL,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    maxSupply: MAX_SUPPLY
                }),
                nftArgs: RandomizedNFT.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    baseURI: BASE_URI,
                    contractURI: CONTRACT_URI,
                    royaltyNumerator: ROYALTY_NUMERATOR,
                    maxPerWallet: MAX_PER_WALLET,
                    batchLimit: BATCH_LIMIT,
                    maxSupply: MAX_SUPPLY
                }),
                destinationRouter: address(destinationRouter)
            });
    }
}
