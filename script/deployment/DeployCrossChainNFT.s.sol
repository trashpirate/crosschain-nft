// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SourceMinter} from "./../../src/SourceMinter.sol";
import {DestinationMinter} from "./../../src/DestinationMinter.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";

contract DeployCrossChainNFT is Script {
    HelperConfig public helperConfig;

    function run()
        external
        returns (SourceMinter, DestinationMinter, HelperConfig)
    {
        helperConfig = new HelperConfig();
        (
            SourceMinter.ConstructorArguments memory args,
            RandomizedNFT.ConstructorArguments memory nftArgs,
            address destinationRouter
        ) = helperConfig.activeNetworkConfig();

        console.log("source router: ", args.router);
        console.log("chain selector: ", args.chainSelector);
        console.log("destination router: ", destinationRouter);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        SourceMinter sourceMinter = new SourceMinter(args);
        DestinationMinter destinationMinter = new DestinationMinter(
            args.router,
            nftArgs
        );
        vm.stopBroadcast();
        return (sourceMinter, destinationMinter, helperConfig);
    }
}
