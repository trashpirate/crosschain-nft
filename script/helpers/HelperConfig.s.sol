// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";
import {MockCCIPRouter} from "@ccip/contracts/src/v0.8/ccip/test/mocks/MockRouter.sol";

contract HelperConfig is Script {
    /** NFT CONFIG - UDPATE BEFORE DEPLOYMENT !!! */
    uint256 public constant TOKEN_FEE = 1_000_000 ether;
    uint256 public constant ETH_FEE = 0.2 ether;
    uint256 public constant MAX_SUPPLY = 52;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public constant BATCH_LIMIT = 0;

    string public constant BASE_URI =
        "ipfs://bafybeia46ygme5csjbmqa73eacqcxmkfmmsajzkgvcxcr7a6tv2bl26nla/";

    /** MAINNET - UDPATE BEFORE DEPLOYMENT !!! */
    string public constant NAME = "Queens";
    string public constant SYMBOL = "QUEEN";
    address public constant FEE_ADDRESS_MAIN =
        0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF;
    address public constant TOKEN_ADDRESS_MAIN =
        0x45e26B10Ae6f95d9d5133720937693E17171F7F9;

    /** TESTNET */
    address public constant FEE_ADDRESS_TEST =
        0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF;
    address public constant TOKEN_ADDRESS_TEST =
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

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
        address router;
        uint64 chainSelector;
        RandomizedNFT.ConstructorArguments args;
        // string name;
        // string symbol;
        // string baseUri;
        // address tokenAddress;
        // address feeAddress;
        // uint256 tokenFee;
        // uint256 ethFee;
        // uint256 maxPerWallet;
        // uint256 batchLimit;
        // uint256 maxSupply;
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
                router: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
                chainSelector: 10344971235874465080,
                args: RandomizedNFT.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    baseURI: BASE_URI,
                    tokenAddress: TOKEN_ADDRESS_TEST,
                    feeAddress: FEE_ADDRESS_TEST,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    maxPerWallet: MAX_PER_WALLET,
                    batchLimit: BATCH_LIMIT,
                    maxSupply: MAX_SUPPLY
                })
            });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                router: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
                chainSelector: 15971525489660198786,
                args: RandomizedNFT.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    baseURI: BASE_URI,
                    tokenAddress: TOKEN_ADDRESS_MAIN,
                    feeAddress: FEE_ADDRESS_MAIN,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    maxPerWallet: MAX_PER_WALLET,
                    batchLimit: BATCH_LIMIT,
                    maxSupply: MAX_SUPPLY
                })
            });
    }

    function getLocalForkConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                router: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
                chainSelector: 15971525489660198786,
                args: RandomizedNFT.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    baseURI: BASE_URI,
                    tokenAddress: TOKEN_ADDRESS_MAIN,
                    feeAddress: FEE_ADDRESS_LOCAL,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    maxPerWallet: MAX_PER_WALLET,
                    batchLimit: BATCH_LIMIT,
                    maxSupply: MAX_SUPPLY
                })
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // Deploy mock contracts
        vm.startBroadcast();
        ERC20Token token = new ERC20Token(TOKENOWNER);
        MockCCIPRouter router = new MockCCIPRouter();
        vm.stopBroadcast();

        return
            NetworkConfig({
                router: address(router),
                chainSelector: 15971525489660198786,
                args: RandomizedNFT.ConstructorArguments({
                    name: NAME,
                    symbol: SYMBOL,
                    baseURI: BASE_URI,
                    tokenAddress: address(token),
                    feeAddress: FEE_ADDRESS_LOCAL,
                    tokenFee: TOKEN_FEE,
                    ethFee: ETH_FEE,
                    maxPerWallet: MAX_PER_WALLET,
                    batchLimit: BATCH_LIMIT,
                    maxSupply: MAX_SUPPLY
                })
            });
    }
}
