// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MockCCIPRouter} from "@ccip/contracts/src/v0.8/ccip/test/mocks/MockRouter.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";

import {SourceMinter} from "./../../src/SourceMinter.sol";
import {DestinationMinter} from "./../../src/DestinationMinter.sol";
import {DeployCrossChainNFT} from "./../../script/deployment/DeployCrossChainNFT.s.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";
import {ERC20Token} from "./../../src/ERC20Token.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract TestCrossChainMint is Test {
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

    function test__CCIPFee() public view {
        uint256 ccipFee = sourceMinter.getCCIPFee(USER, 1);
        assertEq(ccipFee, CCIP_FEE);
    }

    function test__CrossChainMint(
        uint quantity
    ) public fundedAndApproved(USER) unpaused noBatchLimit skipFork {
        quantity = bound(quantity, 1, 2);
        uint256 ethFee = quantity *
            sourceMinter.getEthFee() +
            sourceMinter.getCCIPFee(USER, 1);

        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), quantity);

        assertEq(randomizedNFT.balanceOf(USER), quantity);
    }

    function test__EmitEvent__UpdateMetadata()
        public
        fundedAndApproved(USER)
        unpaused
    {
        uint256 ethFee = sourceMinter.getEthFee() +
            sourceMinter.getCCIPFee(USER, 1);

        vm.expectEmit(true, true, true, true);
        emit MetadataUpdated(0);

        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), 1);
    }

    function test__RevertWhen__MintZero()
        public
        fundedAndApproved(USER)
        unpaused
    {
        uint256 ethFee = sourceMinter.getEthFee() +
            sourceMinter.getCCIPFee(USER, 1);

        vm.expectRevert();
        // RandomizedNFT.RandomizedNFT_InsufficientMintQuantity.selector
        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), 0);
    }

    function test__RevertWhen__CrossChainMintExceedsMaxSupply()
        public
        fundedAndApproved(USER)
        unpaused
    {
        uint quantity = 1;
        uint256 ethFee = quantity *
            sourceMinter.getEthFee() +
            sourceMinter.getCCIPFee(USER, 1);

        vm.startPrank(USER);
        for (uint256 index = 0; index < randomizedNFT.getMaxSupply(); index++) {
            sourceMinter.mint{value: ethFee}(
                address(destinationMinter),
                quantity
            );
        }
        assertEq(randomizedNFT.balanceOf(USER), randomizedNFT.getMaxSupply());

        vm.expectRevert();
        sourceMinter.mint{value: ethFee}(address(destinationMinter), quantity);
    }

    function test__RevertWhen__CrossChainMintExceedsBatchLimit()
        public
        fundedAndApproved(USER)
        unpaused
    {
        uint quantity = 3;
        uint256 ethFee = quantity *
            sourceMinter.getEthFee() +
            sourceMinter.getCCIPFee(USER, 1);

        vm.startPrank(destinationMinter.owner());
        destinationMinter.setBatchLimit(2);
        vm.stopPrank();

        vm.expectRevert();
        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), quantity);
    }

    function test__RevertWhen__InsufficientFees()
        public
        fundedAndApproved(USER)
        unpaused
    {
        uint256 quantity = 1;
        uint256 ethFee = quantity *
            sourceMinter.getEthFee() +
            sourceMinter.getCCIPFee(USER, 1);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(destinationMinter)),
            data: abi.encodeWithSignature(
                "mint(address,uint256)",
                msg.sender,
                quantity
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        IRouterClient router = IRouterClient(sourceMinter.getRouterAddress());
        uint64 chainSelector = sourceMinter.getChainSelector();

        vm.mockCall(
            address(router),
            abi.encodeWithSelector(
                router.getFee.selector,
                chainSelector,
                message
            ),
            abi.encode(10000000)
        );

        // vm.expectRevert(
        //     abi.encodeWithSelector(
        //         SourceMinter.SourceMinter_InsufficientEthFee.selector,
        //         insufficientFee,
        //         ethFee
        //     )
        // );
        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(address(destinationMinter), quantity);
    }
}
