// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SourceMinter} from "./../../src/SourceMinter.sol";
import {DestinationMinter} from "./../../src/DestinationMinter.sol";
import {DeployCrossChainNFT} from "./../../script/deployment/DeployCrossChainNFT.s.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";
import {ERC20Token} from "./../../src/ERC20Token.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract TestInteractions is Test {
    // configuration
    DeployCrossChainNFT deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    SourceMinter sourceMinter;
    DestinationMinter destinationMinter;
    RandomizedNFT randomizedNFT;
    ERC20Token token;

    // helpers
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 100_000_000 * 10 ** 18;

    // events
    event MetadataUpdate(uint256 indexed tokenId);

    // modifiers
    modifier fundedAndApproved(address account) {
        // fund user with eth
        deal(account, 1000 ether);

        // fund user with token
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();

        vm.prank(account);
        token.approve(address(sourceMinter), STARTING_BALANCE);
        _;
    }

    modifier unpaused() {
        vm.startPrank(sourceMinter.owner());
        sourceMinter.pause(false);
        vm.stopPrank();
        _;
    }

    // modifier noBatchLimit() {
    //     vm.startPrank(sourceMinter.owner());
    //     sourceMinter.setBatchLimit(sourceMinter.getMaxSupply());
    //     vm.stopPrank();
    //     _;
    // }

    function setUp() external virtual {
        deployment = new DeployCrossChainNFT();
        (sourceMinter, destinationMinter, helperConfig) = deployment.run();
        deal(address(sourceMinter), 1 ether);

        randomizedNFT = RandomizedNFT(
            destinationMinter.getNftContractAddress()
        );

        networkConfig = helperConfig.getActiveNetworkConfigStruct();
        token = ERC20Token(sourceMinter.getPaymentToken());
    }

    function test__CrossChainMint() public fundedAndApproved(USER) unpaused {
        uint quantity = 1;
        uint256 tokenFee = quantity * sourceMinter.getTokenFee();
        uint256 ethFee = quantity * sourceMinter.getEthFee();

        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), quantity);

        assertEq(randomizedNFT.balanceOf(USER), quantity);
    }

    function test__EmitEvent__UpdateMetadata()
        public
        fundedAndApproved(USER)
        unpaused
    {
        uint256 ethFee = sourceMinter.getEthFee();
        uint256 tokenFee = sourceMinter.getTokenFee();

        vm.expectEmit(true, true, true, true);
        emit MetadataUpdate(0);

        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), 1);
    }

    function test__RevertWhen__CrossChainMintExceedsMaxSupply()
        public
        fundedAndApproved(USER)
        unpaused
    {
        uint quantity = 1;
        uint256 tokenFee = quantity * sourceMinter.getTokenFee();
        uint256 ethFee = quantity * sourceMinter.getEthFee();

        vm.startPrank(USER);
        for (uint256 index = 0; index < sourceMinter.getMaxSupply(); index++) {
            sourceMinter.mint{value: ethFee}(
                address(destinationMinter),
                quantity
            );
        }
        assertEq(randomizedNFT.balanceOf(USER), sourceMinter.getMaxSupply());

        vm.expectRevert();
        sourceMinter.mint{value: ethFee}(address(destinationMinter), quantity);
    }

    function test__RevertWhen__MintZero()
        public
        fundedAndApproved(USER)
        unpaused
    {
        uint256 ethFee = sourceMinter.getEthFee();
        uint256 tokenFee = sourceMinter.getTokenFee();

        vm.expectRevert();
        // RandomizedNFT.RandomizedNFT_InsufficientMintQuantity.selector
        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), 0);
    }
}
