// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {RandomizedNFT} from "../../src/RandomizedNFT.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";

contract DeployRandomizedNFT is Script {
    HelperConfig public helperConfig;

    function run() external returns (RandomizedNFT, HelperConfig) {
        helperConfig = new HelperConfig();
        (, RandomizedNFT.ConstructorArguments memory args, ) = helperConfig
            .activeNetworkConfig();

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        RandomizedNFT nfts = new RandomizedNFT(args);
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
