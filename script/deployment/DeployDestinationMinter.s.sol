// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DestinationMinter} from "./../../src/DestinationMinter.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";

contract DeployDestinationMinter is Script {
    HelperConfig public helperConfig;

    function run() external returns (DestinationMinter, HelperConfig) {
        helperConfig = new HelperConfig();
        (
            address router,
            ,
            RandomizedNFT.ConstructorArguments memory args
        ) = helperConfig.activeNetworkConfig();

        console.log("router: ", router);
        console.log("fee address: ", args.feeAddress);
        console.log("token address: ", args.tokenAddress);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        DestinationMinter minter = new DestinationMinter(router, args);
        vm.stopBroadcast();
        return (minter, helperConfig);
    }
}
