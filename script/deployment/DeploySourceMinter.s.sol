// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SourceMinter} from "./../../src/SourceMinter.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";

contract DeploySourceMinter is Script {
    HelperConfig public helperConfig;

    function run() external returns (SourceMinter, HelperConfig) {
        helperConfig = new HelperConfig();
        (SourceMinter.ConstructorArguments memory args, , ) = helperConfig
            .activeNetworkConfig();

        console.log("router: ", args.router);
        console.log("chainSelector: ", args.chainSelector);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        SourceMinter minter = new SourceMinter(args);
        vm.stopBroadcast();
        return (minter, helperConfig);
    }
}
