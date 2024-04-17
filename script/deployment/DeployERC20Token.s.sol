// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";
import {HelperConfig} from "../helpers/HelperConfig.s.sol";

contract DeployERC20Token is Script {
    function run() external returns (ERC20Token) {
        HelperConfig helperConfig = new HelperConfig();

        vm.startBroadcast();
        ERC20Token token = new ERC20Token(helperConfig.TOKENOWNER());
        vm.stopBroadcast();
        return token;
    }
}
