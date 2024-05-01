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

contract TestHelper {
    mapping(string => bool) public tokenUris;

    function setTokenUri(string memory tokenUri) public {
        tokenUris[tokenUri] = true;
    }

    function isTokenUriSet(string memory tokenUri) public view returns (bool) {
        return tokenUris[tokenUri];
    }
}

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
    uint256 constant CCIP_FEE = 0.00001 ether;

    // events
    event MetadataUpdated(uint256 indexed tokenId);

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

    /** INITIALIZATION */
    function test__RandomizedNFTInitialization() public view {
        assertEq(randomizedNFT.name(), "Randomized NFT");
        assertEq(randomizedNFT.symbol(), "RANDNFT");
        assertEq(randomizedNFT.getMaxSupply(), networkConfig.nftArgs.maxSupply);
        assertEq(
            randomizedNFT.getBatchLimit(),
            networkConfig.nftArgs.batchLimit
        );
        assertEq(
            randomizedNFT.getMaxPerWallet(),
            networkConfig.nftArgs.maxPerWallet
        );
        assertEq(
            randomizedNFT.contractURI(),
            networkConfig.nftArgs.contractURI
        );
        assertEq(randomizedNFT.getBaseURI(), networkConfig.nftArgs.baseURI);
        assertEq(randomizedNFT.supportsInterface(0x80ac58cd), true); // ERC721
        assertEq(randomizedNFT.supportsInterface(0x2a55205a), true); // ERC2981
    }

    /** TRANSFER */
    function test__TransferNfts(
        address account,
        address receiver
    ) public unpaused noBatchLimit skipFork {
        uint256 quantity = 1; //bound(numOfNfts, 1, 100);
        vm.assume(account != address(0));
        vm.assume(receiver != address(0));

        // fund user with eth
        deal(account, 1000 ether);

        // fund user with token
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();

        vm.prank(account);
        token.approve(address(sourceMinter), STARTING_BALANCE);

        uint256 ethFee = quantity * sourceMinter.getEthFee() + CCIP_FEE;

        vm.prank(account);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), quantity);

        assertEq(randomizedNFT.balanceOf(account), quantity);
        assertEq(randomizedNFT.ownerOf(0), account);

        vm.prank(account);
        randomizedNFT.transferFrom(account, receiver, 0);

        assertEq(randomizedNFT.ownerOf(0), receiver);
        assertEq(randomizedNFT.balanceOf(receiver), quantity);
    }

    /** TOKEN URI */

    function test__RetrieveTokenUri() public fundedAndApproved(USER) unpaused {
        uint256 ethFee = sourceMinter.getEthFee() + CCIP_FEE;

        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), 1);
        assertEq(randomizedNFT.balanceOf(USER), 1);

        console.log(randomizedNFT.tokenURI(0));
    }

    /// forge-config: default.fuzz.runs = 3
    function test__UniqueTokenURI(
        uint roll
    ) public fundedAndApproved(USER) unpaused noBatchLimit skipFork {
        roll = bound(roll, 0, 100000000000);
        TestHelper testHelper = new TestHelper();

        uint256 maxSupply = randomizedNFT.getMaxSupply();

        vm.startPrank(USER);
        for (uint256 index = 0; index < maxSupply; index++) {
            vm.prevrandao(bytes32(uint256(index + roll)));
            uint256 ethFee = sourceMinter.getEthFee() + CCIP_FEE;

            sourceMinter.mint{value: ethFee}(address(destinationMinter), 1);
            assertEq(
                testHelper.isTokenUriSet(randomizedNFT.tokenURI(index)),
                false
            );
            console.log(randomizedNFT.tokenURI(index));
            testHelper.setTokenUri(randomizedNFT.tokenURI(index));
        }
        vm.stopPrank();
    }
}
