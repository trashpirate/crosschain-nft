// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {RandomizedNFT} from "../../src/RandomizedNFT.sol";
import {ERC20Token} from "../../src/ERC20Token.sol";

import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {DeployRandomizedNFT} from "../../script/deployment/DeployRandomizedNFT.s.sol";
import {MintNfts, TransferNft, ApproveNft} from "../../script/interactions/UserInteractions.s.sol";

contract UserInteractionsTest is Test {
    RandomizedNFT nftContract;
    HelperConfig helperConfig;
    ERC20Token token;

    // helper variables
    address USER = makeAddr("user");
    address OWNER;
    address TOKEN_OWNER;
    uint256 constant STARTING_BALANCE = 10_000_000 ether;

    modifier fundedAndApproved() {
        // fund user with eth
        deal(USER, 10 ether);

        // fund user with tokens
        vm.prank(TOKEN_OWNER);
        token.transfer(msg.sender, STARTING_BALANCE);
        vm.prank(msg.sender);
        token.approve(address(nftContract), STARTING_BALANCE);
        _;
    }

    modifier mintOpen() {
        vm.startPrank(OWNER);
        nftContract.setBatchLimit(nftContract.getMaxPerWallet());
        vm.stopPrank();
        _;
    }

    function setUp() external {
        DeployRandomizedNFT deployment = new DeployRandomizedNFT();
        (nftContract, helperConfig) = deployment.run();

        token = ERC20Token(nftContract.getPaymentToken());
        TOKEN_OWNER = token.owner();
        OWNER = nftContract.owner();
    }

    function test__integration__UserCanMintSingleNft()
        public
        fundedAndApproved
        mintOpen
    {
        MintNfts mintNfts = new MintNfts();
        mintNfts.mintSingleNft(address(nftContract));

        assert(nftContract.balanceOf(msg.sender) == 1);
    }

    function test__integration__UserCanMintMultipleNfts()
        public
        fundedAndApproved
        mintOpen
    {
        MintNfts mintNfts = new MintNfts();
        mintNfts.mintMultipleNfts(address(nftContract));

        assert(nftContract.balanceOf(msg.sender) == 3);
    }

    function test__integration__UserCanTransferNft()
        public
        fundedAndApproved
        mintOpen
    {
        MintNfts mintNfts = new MintNfts();
        mintNfts.mintSingleNft(address(nftContract));
        assert(nftContract.balanceOf(msg.sender) == 1);

        TransferNft transferNft = new TransferNft();
        transferNft.transferNft(address(nftContract));
        assert(nftContract.balanceOf(msg.sender) == 0);
    }

    function test__integration__UserCanApproveNft()
        public
        fundedAndApproved
        mintOpen
    {
        uint256 fee = nftContract.getEthFee();
        vm.prank(msg.sender);
        nftContract.mint{value: fee}(1);
        ApproveNft approveNft = new ApproveNft();
        approveNft.approveNft(address(nftContract));

        assert(nftContract.getApproved(0) == makeAddr("sender"));
    }
}
