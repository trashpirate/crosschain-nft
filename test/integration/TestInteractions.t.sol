// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SourceMinter} from "./../../src/SourceMinter.sol";
import {DestinationMinter} from "./../../src/DestinationMinter.sol";
import {RandomizedNFT} from "../../src/RandomizedNFT.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";

import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {DeployCrossChainNFT} from "./../../script/deployment/DeployCrossChainNFT.s.sol";
import {MintNft, BatchMint, TransferNft, ApproveNft, BurnNft} from "./../../script/interactions/Interactions.s.sol";

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

    // users
    address tokenOwner;
    address contractOwner;

    // helpers
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 100_000_000 * 10 ** 18;

    // modifiers
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
            _;
        }
    }

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

    modifier noBatchLimit() {
        vm.startPrank(destinationMinter.owner());
        destinationMinter.setBatchLimit(randomizedNFT.getMaxSupply());
        vm.stopPrank();
        _;
    }

    // setup
    function setUp() external {
        deployment = new DeployCrossChainNFT();
        (sourceMinter, destinationMinter, helperConfig) = deployment.run();

        token = ERC20Token(sourceMinter.getPaymentToken());
        randomizedNFT = RandomizedNFT(
            destinationMinter.getNftContractAddress()
        );
        tokenOwner = token.owner();
        contractOwner = sourceMinter.owner();
    }

    /** MINT */
    function test__SingleMint() public fundedAndApproved(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(sourceMinter), address(destinationMinter));
        assertEq(randomizedNFT.balanceOf(msg.sender), 1);
    }

    /** BATCH MINT */
    function test__BatchMint()
        public
        fundedAndApproved(msg.sender)
        unpaused
        noBatchLimit
    {
        BatchMint batchMint = new BatchMint();
        batchMint.batchMint(address(sourceMinter), address(destinationMinter));
        assertEq(randomizedNFT.balanceOf(msg.sender), batchMint.BATCH_SIZE());
    }

    /** TRANSFER */
    function test__TransferNft() public fundedAndApproved(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(sourceMinter), address(destinationMinter));
        assert(randomizedNFT.balanceOf(msg.sender) == 1);

        TransferNft transferNft = new TransferNft();
        transferNft.transferNft(address(randomizedNFT));
        assertEq(randomizedNFT.balanceOf(msg.sender), 0);
    }

    /** APPROVE */
    function test__ApproveNft() public fundedAndApproved(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(sourceMinter), address(destinationMinter));
        assertEq(randomizedNFT.balanceOf(msg.sender), 1);

        ApproveNft approveNft = new ApproveNft();
        approveNft.approveNft(address(randomizedNFT));

        assertEq(randomizedNFT.getApproved(0), approveNft.SENDER());
    }

    /** BURN */
    function test__BurnNft() public fundedAndApproved(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(sourceMinter), address(destinationMinter));
        assertEq(randomizedNFT.balanceOf(msg.sender), 1);

        BurnNft burnNft = new BurnNft();
        burnNft.burnNft(address(randomizedNFT));

        assertEq(randomizedNFT.balanceOf(msg.sender), 0);
    }
}
