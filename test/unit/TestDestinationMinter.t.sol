// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {ERC20Token} from "./../../src/ERC20Token.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {DestinationMinter} from "./../../src/DestinationMinter.sol";
import {DeployDestinationMinter} from "./../../script/deployment/DeployDestinationMinter.s.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestDestinationMinter is Test {
    // configuration
    DeployDestinationMinter deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    DestinationMinter destinationMinter;
    RandomizedNFT nfts;

    // helpers
    address USER = makeAddr("user");
    uint256 constant NEW_BATCH_LIMIT = 10;
    uint256 constant NEW_MAX_PER_WALLET = 10;

    // events
    event MaxPerWalletSet(address indexed sender, uint256 maxPerWallet);
    event BatchLimitSet(address indexed sender, uint256 batchLimit);

    function setUp() external virtual {
        deployment = new DeployDestinationMinter();
        (destinationMinter, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();

        nfts = RandomizedNFT(destinationMinter.getNftContractAddress());
    }

    /** SET MAX PER WALLET */
    function test__SetMaxPerWallet() public {
        address owner = destinationMinter.owner();

        vm.prank(owner);
        destinationMinter.setMaxPerWallet(NEW_MAX_PER_WALLET);

        assertEq(nfts.getMaxPerWallet(), NEW_MAX_PER_WALLET);
    }

    function test__EmitEvent__SetMaxPerWallet() public {
        uint256 maxPerWallet = nfts.getMaxPerWallet();

        address owner = destinationMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit MaxPerWalletSet(address(destinationMinter), maxPerWallet - 1);

        vm.prank(owner);
        destinationMinter.setMaxPerWallet(maxPerWallet - 1);
    }

    function test__RevertWhen__NotOwnerSetsMaxPerWallet() public {
        uint256 maxPerWallet = nfts.getMaxPerWallet();
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );

        vm.prank(USER);
        destinationMinter.setMaxPerWallet(maxPerWallet - 1);
    }

    /** SET BATCH LIMIT */
    function test__SetBatchLimit() public {
        address owner = destinationMinter.owner();

        vm.prank(owner);
        destinationMinter.setBatchLimit(NEW_BATCH_LIMIT);

        assertEq(nfts.getBatchLimit(), NEW_BATCH_LIMIT);
    }

    function test__EmitEvent__SetBatchLimit() public {
        uint256 batchLimit = nfts.getBatchLimit();

        address owner = destinationMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit BatchLimitSet(address(destinationMinter), batchLimit - 1);

        vm.prank(owner);
        destinationMinter.setBatchLimit(batchLimit - 1);
    }

    function test__RevertWhen__NotOwnerSetsBatchLimit() public {
        uint256 batchLimit = nfts.getBatchLimit();
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );

        vm.prank(USER);
        destinationMinter.setBatchLimit(batchLimit - 1);
    }
}
