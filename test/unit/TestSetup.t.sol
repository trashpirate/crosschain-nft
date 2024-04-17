// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {RandomizedNFT} from "../../src/RandomizedNFT.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";
import {DeployRandomizedNFT} from "../../script/deployment/DeployRandomizedNFT.s.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract TestSetup is Test {
    // configuration
    DeployRandomizedNFT deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    RandomizedNFT nfts;
    ERC20Token token;

    function setUp() external virtual {
        deployment = new DeployRandomizedNFT();
        (nfts, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();

        token = ERC20Token(nfts.getPaymentToken());
    }
}
