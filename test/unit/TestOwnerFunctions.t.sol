// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// import {Test, console} from "forge-std/Test.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import {RandomizedNFT} from "../../src/RandomizedNFT.sol";

// import {DeployRandomizedNFT} from "../../script/deployment/DeployRandomizedNFT.s.sol";

// import {TestSetup} from "./TestSetup.t.sol";

// contract TestOwnerFunctions is TestSetup {
//     address USER = makeAddr("user");
//     address NEW_FEE_ADDRESS = makeAddr("fee");

//     uint256 constant STARTING_BALANCE = 500_000 * 10 ** 18;
//     uint256 constant NEW_FEE = 20_000 * 10 ** 18;

//     event TokenFeeSet(address indexed sender, uint256 fee);
//     event EthFeeSet(address indexed sender, uint256 fee);
//     event FeeAddressSet(address indexed sender, address feeAddress);
//     event MaxPerWalletSet(address indexed sender, uint256 maxPerWallet);
//     event BatchLimitSet(address indexed sender, uint256 batchLimit);

//     modifier funded() {
//         // fund user with eth
//         deal(USER, 10 ether);

//         // fund user with token
//         vm.startPrank(token.owner());
//         token.transfer(USER, STARTING_BALANCE);
//         vm.stopPrank();
//         _;
//     }

//     modifier mintOpen() {
//         // fund user
//         vm.startPrank(nfts.owner());
//         nfts.setBatchLimit(nfts.getMaxPerWallet());
//         vm.stopPrank();
//         _;
//     }

//     /** SET TOKEN FEE */

//     function test__SetTokenFee() public {
//         address owner = nfts.owner();
//         vm.prank(owner);
//         nfts.setTokenFee(NEW_FEE);
//         assertEq(nfts.getTokenFee(), NEW_FEE);
//     }

//     function test__EmitEvent__SetTokenFee() public {
//         address owner = nfts.owner();

//         vm.expectEmit(true, true, true, true);
//         emit TokenFeeSet(owner, NEW_FEE);

//         vm.prank(owner);
//         nfts.setTokenFee(NEW_FEE);
//     }

//     function test__RevertWhen__NotOwnerSetsTokenFee() public {
//         vm.prank(USER);

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Ownable.OwnableUnauthorizedAccount.selector,
//                 USER
//             )
//         );
//         nfts.setTokenFee(NEW_FEE);
//     }

//     /** SET ETH FEE */

//     function test__SetEthFee() public {
//         address owner = nfts.owner();
//         vm.prank(owner);
//         nfts.setEthFee(NEW_FEE);
//         assertEq(nfts.getEthFee(), NEW_FEE);
//     }

//     function test__EmitEvent__SetEthFee() public {
//         address owner = nfts.owner();

//         vm.expectEmit(true, true, true, true);
//         emit EthFeeSet(owner, NEW_FEE);

//         vm.prank(owner);
//         nfts.setEthFee(NEW_FEE);
//     }

//     function test__RevertWhen__NotOwnerSetsEthFee() public {
//         vm.prank(USER);

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Ownable.OwnableUnauthorizedAccount.selector,
//                 USER
//             )
//         );
//         nfts.setEthFee(NEW_FEE);
//     }

//     /** SET FEE ADDRESS */

//     function test__SetFeeAddress() public {
//         address owner = nfts.owner();
//         vm.prank(owner);
//         nfts.setFeeAddress(NEW_FEE_ADDRESS);
//         assertEq(nfts.getFeeAddress(), NEW_FEE_ADDRESS);
//     }

//     function test__EmitEvent__SetFeeAddress() public {
//         address owner = nfts.owner();

//         vm.expectEmit(true, true, true, true);
//         emit FeeAddressSet(owner, NEW_FEE_ADDRESS);

//         vm.prank(owner);
//         nfts.setFeeAddress(NEW_FEE_ADDRESS);
//     }

//     function test__RevertWhen__FeeAddressIsZero() public {
//         address owner = nfts.owner();
//         vm.prank(owner);

//         vm.expectRevert(
//             RandomizedNFT.RandomizedNFT_FeeAddressIsZeroAddress.selector
//         );
//         nfts.setFeeAddress(address(0));
//     }

//     function test__RevertWhen__NotOwnerSetsFeeAddress() public {
//         vm.prank(USER);

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Ownable.OwnableUnauthorizedAccount.selector,
//                 USER
//             )
//         );
//         nfts.setFeeAddress(NEW_FEE_ADDRESS);
//     }

//     /** SET BATCH LIMIT */

//     function test__SetBatchLimit() public mintOpen {
//         uint256 batchLimit = nfts.getBatchLimit();

//         address owner = nfts.owner();
//         vm.prank(owner);
//         nfts.setBatchLimit(batchLimit - 1);
//         assertEq(nfts.getBatchLimit(), batchLimit - 1);
//     }

//     function test__EmitEvent__SetBatchLimit() public mintOpen {
//         uint256 batchLimit = nfts.getBatchLimit();

//         address owner = nfts.owner();

//         vm.expectEmit(true, true, true, true);
//         emit BatchLimitSet(owner, batchLimit - 1);

//         vm.prank(owner);
//         nfts.setBatchLimit(batchLimit - 1);
//     }

//     function test__RevertWhen__BatchLimitGreaterThanMaxPerWallet()
//         public
//         mintOpen
//     {
//         uint256 maxPerWallet = nfts.getMaxPerWallet();
//         address owner = nfts.owner();
//         vm.prank(owner);

//         vm.expectRevert(
//             RandomizedNFT.RandomizedNFT_BatchLimitExceedsMaxPerWallet.selector
//         );
//         nfts.setBatchLimit(maxPerWallet + 1);
//     }

//     function test__RevertWhen__BatchLimitTooHigh() public {
//         address owner = nfts.owner();
//         vm.prank(owner);

//         vm.expectRevert(RandomizedNFT.RandomizedNFT_BatchLimitTooHigh.selector);
//         nfts.setBatchLimit(101);
//     }

//     function test__RevertWhen__NotOwnerSetsBatchLimit() public {
//         vm.prank(USER);

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Ownable.OwnableUnauthorizedAccount.selector,
//                 USER
//             )
//         );
//         nfts.setBatchLimit(10);
//     }

//     /** SET MAX PER WALLET */

//     function test__SetMaxPerWallet() public mintOpen {
//         uint256 maxPerWallet = nfts.getMaxPerWallet();

//         address owner = nfts.owner();
//         vm.prank(owner);
//         nfts.setMaxPerWallet(maxPerWallet + 1);
//         assertEq(nfts.getMaxPerWallet(), maxPerWallet + 1);
//     }

//     function test__EmitEvent__SetMaxPerWallet() public {
//         uint256 maxPerWallet = nfts.getMaxPerWallet();

//         address owner = nfts.owner();

//         vm.expectEmit(true, true, true, true);
//         emit MaxPerWalletSet(owner, maxPerWallet + 1);

//         vm.prank(owner);
//         nfts.setMaxPerWallet(maxPerWallet + 1);
//     }

//     function test__RevertWhen__MaxPerWalletGreaterThanSupply() public {
//         uint256 supply = nfts.getMaxSupply();

//         address owner = nfts.owner();
//         vm.prank(owner);

//         vm.expectRevert(
//             RandomizedNFT.RandomizedNFT_MaxPerWalletExceedsMaxSupply.selector
//         );
//         nfts.setMaxPerWallet(supply + 1);
//     }

//     function test__RevertWhen__MaxPerWalletSmallerThanBatchLimit()
//         public
//         mintOpen
//     {
//         uint256 batchLimit = nfts.getBatchLimit();
//         address owner = nfts.owner();
//         vm.prank(owner);

//         vm.expectRevert(
//             RandomizedNFT
//                 .RandomizedNFT_MaxPerWalletSmallerThanBatchLimit
//                 .selector
//         );
//         nfts.setMaxPerWallet(batchLimit - 1);
//     }

//     function test__RevertWhen__NotOwnerSetsMaxPerWallet() public {
//         uint256 maxPerWallet = nfts.getMaxPerWallet();

//         vm.prank(USER);

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Ownable.OwnableUnauthorizedAccount.selector,
//                 USER
//             )
//         );
//         nfts.setMaxPerWallet(maxPerWallet + 1);
//     }

//     /** WITHDRAW TOKENS */

//     function test__WithdrawTokens() public funded {
//         vm.prank(USER);
//         token.transfer(address(nfts), STARTING_BALANCE / 2);
//         uint256 contractBalance = token.balanceOf(address(nfts));
//         assertGt(contractBalance, 0);
//         uint256 initialBalance = token.balanceOf(nfts.owner());

//         vm.startPrank(nfts.owner());
//         nfts.withdrawTokens(address(token), nfts.owner());
//         vm.stopPrank();
//         uint256 newBalance = token.balanceOf(nfts.owner());
//         assertEq(token.balanceOf(address(nfts)), 0);
//         assertGt(newBalance, initialBalance);
//     }

//     function test__RevertWhen__NotOwnerWithdrawsTokens() public funded {
//         vm.prank(USER);
//         token.transfer(address(nfts), STARTING_BALANCE / 2);
//         uint256 contractBalance = token.balanceOf(address(nfts));
//         assertGt(contractBalance, 0);

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Ownable.OwnableUnauthorizedAccount.selector,
//                 USER
//             )
//         );
//         vm.prank(USER);
//         nfts.withdrawTokens(address(token), USER);
//     }
// }
