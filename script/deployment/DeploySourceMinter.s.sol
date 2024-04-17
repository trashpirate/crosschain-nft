// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SourceMinter} from "./../../src/SourceMinter.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";

contract DeploySourceMinter is Script {
    HelperConfig public helperConfig;

    function run() external returns (SourceMinter, HelperConfig) {
        helperConfig = new HelperConfig();
        (address router, uint64 chainSelector, ) = helperConfig
            .activeNetworkConfig();

        console.log("router: ", router);
        console.log("chainSelector: ", chainSelector);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        SourceMinter minter = new SourceMinter(router, chainSelector);
        vm.stopBroadcast();
        return (minter, helperConfig);
    }
}
