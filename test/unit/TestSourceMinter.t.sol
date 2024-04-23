// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {SourceMinter} from "./../../src/SourceMinter.sol";
import {DeploySourceMinter} from "./../../script/deployment/DeploySourceMinter.s.sol";
import {ERC20Token} from "./../../src/ERC20Token.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {MockCCIPRouter} from "../mocks/MockCCIPRouter.sol";

contract TestSourceMinter is Test {
    // configuration
    DeploySourceMinter deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    SourceMinter sourceMinter;
    ERC20Token token;

    // helpers
    address USER = makeAddr("user");
    address NEW_FEE_ADDRESS = makeAddr("fee");
    address RECEIVER = makeAddr("receiver");

    uint256 constant STARTING_BALANCE = 100_000_000 * 10 ** 18;
    uint256 constant NEW_TOKEN_FEE = 20_000 * 10 ** 18;
    uint256 constant NEW_ETH_FEE = 0.001 ether;

    uint256 constant CCIP_FEE = 0.00001 ether;

    // events
    event SourceMinter_MessageSent(bytes32 messageId);
    event TokenFeeSet(address indexed sender, uint256 fee);
    event EthFeeSet(address indexed sender, uint256 fee);
    event FeeAddressSet(address indexed sender, address feeAddress);
    event Paused(address indexed sender, bool isPaused);

    // modifiers
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
            _;
        }
    }

    modifier funded(address account) {
        // fund user with eth
        deal(account, 1000 ether);

        // fund user with token
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();
        _;
    }

    modifier unpaused() {
        vm.startPrank(sourceMinter.owner());
        sourceMinter.pause(false);
        vm.stopPrank();
        _;
    }

    function setUp() external virtual {
        deployment = new DeploySourceMinter();
        (sourceMinter, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();

        token = ERC20Token(sourceMinter.getPaymentToken());
    }

    /** INITIALIZATION */
    function test__SourceMinterInitialization() public view {
        ERC20 paymentToken = ERC20(sourceMinter.getPaymentToken());
        string memory feeTokenSymbol = paymentToken.symbol();
        assertEq(feeTokenSymbol, "TEST");
        assertEq(sourceMinter.isPaused(), true);
        assertEq(
            sourceMinter.getRouterAddress(),
            networkConfig.sourceArgs.router
        );
        assertEq(
            sourceMinter.getChainSelector(),
            networkConfig.sourceArgs.chainSelector
        );
    }

    /** CONSTRUCTOR ARGUMENTS */
    function test__SourceMinterConstructorArguments() public view {
        assertEq(
            sourceMinter.getPaymentToken(),
            networkConfig.sourceArgs.tokenAddress
        );
        assertEq(
            sourceMinter.getFeeAddress(),
            networkConfig.sourceArgs.feeAddress
        );
        assertEq(sourceMinter.getTokenFee(), networkConfig.sourceArgs.tokenFee);
        assertEq(sourceMinter.getEthFee(), networkConfig.sourceArgs.ethFee);
    }

    /** WITHDRAW TOKENS */
    function test__WithdrawTokens() public funded(USER) {
        uint256 amount = STARTING_BALANCE / 2;

        vm.prank(USER);
        token.transfer(address(sourceMinter), amount);
        uint256 contractBalance = token.balanceOf(address(sourceMinter));
        assertGt(contractBalance, 0);

        uint256 initialBalance = token.balanceOf(sourceMinter.owner());

        vm.startPrank(sourceMinter.owner());
        sourceMinter.withdrawTokens(sourceMinter.owner(), address(token));
        vm.stopPrank();

        uint256 newBalance = token.balanceOf(sourceMinter.owner());
        assertEq(token.balanceOf(address(sourceMinter)), 0);
        assertEq(newBalance, initialBalance + amount);
    }

    function test__RevertWhen__NotOwnerWithdrawsTokens() public funded(USER) {
        uint256 amount = STARTING_BALANCE / 2;

        vm.prank(USER);
        token.transfer(address(sourceMinter), amount);
        uint256 contractBalance = token.balanceOf(address(sourceMinter));
        assertEq(contractBalance, amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );
        vm.prank(USER);
        sourceMinter.withdrawTokens(address(token), USER);
    }

    /** WITHDRAW ETH */
    function test__WithdrawETH() public funded(USER) {
        deal(address(sourceMinter), 1 ether);
        uint256 contractBalance = address(sourceMinter).balance;
        assertGt(contractBalance, 0);

        uint256 initialBalance = (sourceMinter.owner()).balance;

        vm.startPrank(sourceMinter.owner());
        sourceMinter.withdrawETH(sourceMinter.owner());
        vm.stopPrank();

        uint256 newBalance = sourceMinter.owner().balance;
        assertEq(address(sourceMinter).balance, 0);
        assertEq(newBalance, initialBalance + contractBalance);
    }

    function test__RevertWhen__NotOwnerWithdrawsETH() public funded(USER) {
        deal(address(sourceMinter), 1 ether);
        address owner = sourceMinter.owner();
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );
        console.log(USER);
        vm.prank(USER);
        sourceMinter.withdrawETH(owner);
    }

    /** SET TOKEN FEE */
    function test__SetTokenFee() public {
        address owner = sourceMinter.owner();
        vm.prank(owner);
        sourceMinter.setTokenFee(NEW_TOKEN_FEE);
        assertEq(sourceMinter.getTokenFee(), NEW_TOKEN_FEE);
    }

    function test__EmitEvent__SetTokenFee() public {
        address owner = sourceMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit TokenFeeSet(owner, NEW_TOKEN_FEE);

        vm.prank(owner);
        sourceMinter.setTokenFee(NEW_TOKEN_FEE);
    }

    function test__RevertWhen__NotOwnerSetsTokenFee() public {
        vm.prank(USER);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );
        sourceMinter.setTokenFee(NEW_TOKEN_FEE);
    }

    /** SET ETH FEE */
    function test__SetEthFee() public {
        address owner = sourceMinter.owner();
        vm.prank(owner);
        sourceMinter.setEthFee(NEW_ETH_FEE);
        assertEq(sourceMinter.getEthFee(), NEW_ETH_FEE);
    }

    function test__EmitEvent__SetEthFee() public {
        address owner = sourceMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit EthFeeSet(owner, NEW_ETH_FEE);

        vm.prank(owner);
        sourceMinter.setEthFee(NEW_ETH_FEE);
    }

    function test__RevertWhen__NotOwnerSetsEthFee() public {
        vm.prank(USER);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );
        sourceMinter.setEthFee(NEW_ETH_FEE);
    }

    /** SET FEE ADDRESS */
    function test__SetFeeAddress() public {
        address owner = sourceMinter.owner();
        vm.prank(owner);
        sourceMinter.setFeeAddress(NEW_FEE_ADDRESS);
        assertEq(sourceMinter.getFeeAddress(), NEW_FEE_ADDRESS);
    }

    function test__EmitEvent__SetFeeAddress() public {
        address owner = sourceMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit FeeAddressSet(owner, NEW_FEE_ADDRESS);

        vm.prank(owner);
        sourceMinter.setFeeAddress(NEW_FEE_ADDRESS);
    }

    function test__RevertWhen__FeeAddressIsZero() public {
        address owner = sourceMinter.owner();
        vm.prank(owner);

        vm.expectRevert(
            SourceMinter.SourceMinter_FeeAddressIsZeroAddress.selector
        );
        sourceMinter.setFeeAddress(address(0));
    }

    function test__RevertWhen__NotOwnerSetsFeeAddress() public {
        vm.prank(USER);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );
        sourceMinter.setFeeAddress(NEW_FEE_ADDRESS);
    }

    /** PAUSE */
    function test__UnPause() public {
        address owner = sourceMinter.owner();

        vm.prank(owner);
        sourceMinter.pause(false);

        assertEq(sourceMinter.isPaused(), false);
    }

    function test__Pause() public {
        address owner = sourceMinter.owner();

        vm.prank(owner);
        sourceMinter.pause(false);

        vm.prank(owner);
        sourceMinter.pause(true);

        assertEq(sourceMinter.isPaused(), true);
    }

    function test__EmitEvent__Pause() public {
        address owner = sourceMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit Paused(owner, false);

        vm.prank(owner);
        sourceMinter.pause(false);
    }

    function test__RevertsWhen__NotOnwerPauses() public {
        address owner = sourceMinter.owner();

        vm.prank(owner);
        sourceMinter.pause(false);

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );
        vm.prank(USER);
        sourceMinter.pause(true);
    }

    /** MINT */
    function test__Mint(
        uint256 quantity
    ) public funded(USER) unpaused skipFork {
        quantity = bound(quantity, 1, networkConfig.nftArgs.maxSupply);
        uint256 tokenBalance = token.balanceOf(USER);
        uint256 ethBalance = USER.balance;

        uint256 tokenFee = quantity * sourceMinter.getTokenFee();
        uint256 ethFee = quantity * sourceMinter.getEthFee() + CCIP_FEE;

        vm.startPrank(USER);
        token.approve(address(sourceMinter), tokenFee);
        sourceMinter.mint{value: ethFee}(RECEIVER, quantity);
        vm.stopPrank();

        assertEq(token.balanceOf(USER), tokenBalance - tokenFee);
        assertEq(USER.balance, ethBalance - ethFee);
        assertEq(token.balanceOf(sourceMinter.getFeeAddress()), tokenFee);
        assertEq(sourceMinter.getFeeAddress().balance, ethFee);
    }

    function test__EmitEvent__Mint() public funded(USER) unpaused {
        uint256 ethFee = sourceMinter.getEthFee() + CCIP_FEE;
        uint256 tokenFee = sourceMinter.getTokenFee();

        vm.prank(USER);
        token.approve(address(sourceMinter), tokenFee);

        vm.expectEmit(false, false, false, false);
        emit SourceMinter_MessageSent("");

        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(RECEIVER, 1);
    }

    function test__RevertWhen__Paused() public funded(USER) {
        uint256 ethFee = sourceMinter.getEthFee() + CCIP_FEE;
        uint256 tokenFee = sourceMinter.getTokenFee();

        vm.prank(USER);
        token.approve(address(sourceMinter), tokenFee);

        vm.expectRevert(SourceMinter.SourceMinter_ContractIsPaused.selector);
        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(RECEIVER, 1);
    }

    function test__RevertWhen__InsufficientTokenBalance(
        uint256 quantity
    ) public unpaused skipFork {
        quantity = bound(quantity, 1, networkConfig.nftArgs.maxSupply);

        // fund user
        deal(USER, 1000 ether);
        vm.startPrank(token.owner());
        token.transfer(USER, 1000 ether);
        vm.stopPrank();

        uint256 tokenFee = quantity * sourceMinter.getTokenFee();
        uint256 ethFee = quantity * sourceMinter.getEthFee() + CCIP_FEE;

        vm.prank(USER);
        token.approve(address(sourceMinter), tokenFee);

        vm.expectRevert(
            SourceMinter.SourceMinter_InsufficientTokenBalance.selector
        );
        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(RECEIVER, quantity);
    }

    function test__RevertWhen__InsufficientEthFee(
        uint256 quantity
    ) public funded(USER) unpaused {
        quantity = bound(quantity, 1, networkConfig.nftArgs.maxSupply);

        uint256 tokenFee = quantity * sourceMinter.getTokenFee();
        uint256 ethFee = quantity * sourceMinter.getEthFee() + CCIP_FEE;
        uint256 insufficientFee = ethFee - 0.01 ether;

        vm.prank(USER);
        token.approve(address(sourceMinter), tokenFee);

        vm.expectRevert(
            abi.encodeWithSelector(
                SourceMinter.SourceMinter_InsufficientEthFee.selector,
                insufficientFee,
                ethFee
            )
        );
        vm.prank(USER);
        sourceMinter.mint{value: insufficientFee}(RECEIVER, quantity);
    }

    function test__RevertsWhen__TokenTransferFails(
        uint256 quantity
    ) public funded(USER) unpaused skipFork {
        quantity = bound(quantity, 1, networkConfig.nftArgs.maxSupply);
        uint256 ethFee = quantity * sourceMinter.getEthFee() + CCIP_FEE;
        uint256 tokenFee = quantity * sourceMinter.getTokenFee();

        vm.prank(USER);
        token.approve(address(sourceMinter), tokenFee);

        address feeAccount = sourceMinter.getFeeAddress();
        vm.mockCall(
            address(token),
            abi.encodeWithSelector(
                token.transferFrom.selector,
                USER,
                feeAccount,
                tokenFee
            ),
            abi.encode(false)
        );

        vm.expectRevert(SourceMinter.SourceMinter_TokenTransferFailed.selector);
        vm.prank(USER);
        sourceMinter.mint{value: ethFee}(RECEIVER, quantity);
    }
}
