// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// import {Test, console} from "forge-std/Test.sol";
// import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import {RandomizedNFT} from "../../src/RandomizedNFT.sol";
// import {ERC20Token} from "../../src/ERC20Token.sol";

// import {DeployRandomizedNFT} from "../../script/deployment/DeployRandomizedNFT.s.sol";

// import {TestSetup} from "./TestSetup.t.sol";

// contract TestHelper {
//     mapping(string => bool) public tokenUris;

//     function setTokenUri(string memory tokenUri) public {
//         tokenUris[tokenUri] = true;
//     }

//     function isTokenUriSet(string memory tokenUri) public view returns (bool) {
//         return tokenUris[tokenUri];
//     }
// }

// contract TestUserFunctions is TestSetup {
//     address USER1 = makeAddr("user-1");
//     address USER2 = makeAddr("user-2");
//     address NEW_FEE_ADDRESS = makeAddr("tokenFee");

//     uint256 constant TOKEN_AMOUNT = 500_000_000 ether;
//     uint256 constant NEW_FEE = 20_000 ether;
//     uint256 constant FUZZ_FEE = 100 ether;
//     uint256 constant FUZZ_ETH_FEE = 1e9;

//     event MetadataUpdate(uint256 indexed tokenId);

//     modifier skipFork() {
//         if (block.chainid != 31337) {
//             return;
//             _;
//         }
//     }

//     modifier funded(address account) {
//         // fund user ETH
//         deal(account, 10 ether);

//         // fund user tokens
//         vm.startPrank(token.owner());
//         token.transfer(account, TOKEN_AMOUNT);
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

//     modifier maxMintAllowed() {
//         uint maxSupply = nfts.getMaxSupply();
//         vm.startPrank(nfts.owner());
//         nfts.setMaxPerWallet(maxSupply);

//         if (maxSupply >= 100) {
//             nfts.setBatchLimit(100);
//         } else {
//             nfts.setBatchLimit(maxSupply);
//         }

//         nfts.setTokenFee(FUZZ_FEE);
//         nfts.setEthFee(FUZZ_ETH_FEE);
//         vm.stopPrank();
//         _;
//     }

//     ///////////////////
//     /////// MINT //////
//     ///////////////////

//     /** function */
//     function test__MintNFT(
//         uint256 numNfts
//     ) public funded(USER1) maxMintAllowed skipFork {
//         numNfts = bound(numNfts, 1, 100);
//         uint256 ethFee = numNfts * nfts.getEthFee();
//         uint256 tokenFee = numNfts * nfts.getTokenFee();
//         uint256 initialEthBalance = USER1.balance;
//         uint256 initialTokenBalance = token.balanceOf(USER1);

//         vm.startPrank(USER1);
//         token.approve(address(nfts), tokenFee);
//         nfts.mint{value: ethFee}(numNfts);
//         vm.stopPrank();

//         assertEq(nfts.balanceOf(USER1), numNfts);
//         assertEq(initialEthBalance - ethFee, USER1.balance);
//         assertEq(initialTokenBalance - tokenFee, token.balanceOf(USER1));
//         assertEq(ethFee, nfts.getFeeAddress().balance);
//         assertEq(tokenFee, token.balanceOf(nfts.getFeeAddress()));
//     }

//     /** events */

//     function test__EmitEvent__Mint() public funded(USER1) mintOpen {
//         uint256 ethFee = nfts.getEthFee();
//         uint256 tokenFee = nfts.getTokenFee();

//         vm.prank(USER1);
//         token.approve(address(nfts), tokenFee);

//         vm.expectEmit(true, true, true, true);
//         emit MetadataUpdate(0);

//         vm.prank(USER1);
//         nfts.mint{value: ethFee}(1);
//     }

//     /** reverts */

//     function test__RevertWhen__MintZero() public funded(USER1) mintOpen {
//         uint256 ethFee = nfts.getEthFee();
//         uint256 tokenFee = nfts.getTokenFee();

//         vm.prank(USER1);
//         token.approve(address(nfts), tokenFee);

//         vm.expectRevert(
//             RandomizedNFT.RandomizedNFT_InsufficientMintQuantity.selector
//         );
//         vm.prank(USER1);
//         nfts.mint{value: ethFee}(0);
//     }

//     function test__RevertWhen_MintExceedsBatchLimit()
//         public
//         funded(USER1)
//         mintOpen
//     {
//         uint256 batchLimit = nfts.getBatchLimit();

//         vm.startPrank(nfts.owner());
//         nfts.setMaxPerWallet(batchLimit + 2);
//         vm.stopPrank();

//         uint256 ethFee = (batchLimit + 1) * nfts.getEthFee();
//         uint256 tokenFee = (batchLimit + 1) * nfts.getTokenFee();
//         vm.prank(USER1);
//         token.approve(address(nfts), tokenFee);

//         vm.expectRevert(RandomizedNFT.RandomizedNFT_ExceedsBatchLimit.selector);
//         vm.prank(USER1);
//         nfts.mint{value: ethFee}(batchLimit + 1);
//     }

//     function test__RevertWhen__MintExceedsMaxWalletLimit()
//         public
//         funded(USER1)
//         mintOpen
//     {
//         uint256 maxPerWallet = nfts.getMaxPerWallet();
//         uint256 ethFee = nfts.getEthFee();
//         uint256 tokenFee = (maxPerWallet + 1) * nfts.getTokenFee();

//         vm.startPrank(USER1);
//         token.approve(address(nfts), tokenFee);
//         nfts.mint{value: maxPerWallet * ethFee}(maxPerWallet);
//         vm.stopPrank();

//         vm.expectRevert(
//             RandomizedNFT.RandomizedNFT_ExceedsMaxPerWallet.selector
//         );
//         vm.prank(USER1);
//         nfts.mint{value: ethFee}(1);
//     }

//     function test__RevertWhen__MaxSupplyExceeded()
//         public
//         funded(USER1)
//         funded(USER2)
//         maxMintAllowed
//     {
//         uint256 maxSupply = nfts.getMaxSupply();

//         vm.startPrank(USER1);
//         if (maxSupply <= 100) {
//             uint256 ethFee = maxSupply * nfts.getEthFee();
//             uint256 tokenFee = maxSupply * nfts.getTokenFee();
//             token.approve(address(nfts), tokenFee);
//             nfts.mint{value: ethFee}(maxSupply);
//         } else {
//             while (nfts.totalSupply() < maxSupply) {
//                 uint256 remaining = maxSupply - nfts.totalSupply();
//                 if (remaining >= 100) {
//                     uint256 ethFee = 100 * nfts.getEthFee();
//                     uint256 tokenFee = 100 * nfts.getTokenFee();
//                     token.approve(address(nfts), tokenFee);
//                     nfts.mint{value: ethFee}(100);
//                 } else {
//                     uint256 ethFee = remaining * nfts.getEthFee();
//                     uint256 tokenFee = remaining * nfts.getTokenFee();
//                     token.approve(address(nfts), tokenFee);
//                     nfts.mint{value: ethFee}(remaining);
//                 }
//             }
//         }
//         vm.stopPrank();

//         uint256 ethFee = nfts.getEthFee();
//         uint256 tokenFee = nfts.getTokenFee();
//         vm.startPrank(USER2);
//         token.approve(address(nfts), tokenFee);

//         vm.expectRevert(RandomizedNFT.RandomizedNFT_ExceedsMaxSupply.selector);
//         nfts.mint{value: ethFee}(1);
//         vm.stopPrank();
//     }

//     function test__RevertWhen__InsufficientTokenBalance()
//         public
//         funded(USER1)
//         mintOpen
//     {
//         uint256 insufficientTokenBalance = 5000 ether;
//         uint256 ethFee = nfts.getEthFee();

//         vm.startPrank(USER1);
//         token.transfer(USER2, TOKEN_AMOUNT - insufficientTokenBalance);
//         vm.stopPrank();

//         vm.prank(USER1);
//         token.approve(address(nfts), insufficientTokenBalance);

//         vm.expectRevert(
//             RandomizedNFT.RandomizedNFT_InsufficientTokenBalance.selector
//         );
//         vm.prank(USER1);
//         nfts.mint{value: ethFee}(1);
//     }

//     function test__RevertWhen__InsufficientEthFee()
//         public
//         funded(USER1)
//         mintOpen
//     {
//         uint256 tokenFee = nfts.getTokenFee();
//         uint256 insufficientFee = nfts.getEthFee() / 2;

//         vm.prank(USER1);
//         token.approve(address(nfts), tokenFee);

//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 RandomizedNFT.RandomizedNFT_InsufficientEthFee.selector,
//                 insufficientFee,
//                 nfts.getEthFee()
//             )
//         );
//         vm.prank(USER1);
//         nfts.mint{value: insufficientFee}(1);
//     }

//     function test__RevertsWhen__TokenTransferFails()
//         public
//         funded(USER1)
//         mintOpen
//     {
//         uint256 ethFee = nfts.getEthFee();
//         uint256 tokenFee = nfts.getTokenFee();
//         vm.prank(USER1);
//         token.approve(address(nfts), tokenFee);

//         address feeAccount = nfts.getFeeAddress();
//         vm.mockCall(
//             address(token),
//             abi.encodeWithSelector(
//                 token.transferFrom.selector,
//                 USER1,
//                 feeAccount,
//                 tokenFee
//             ),
//             abi.encode(false)
//         );

//         vm.expectRevert(
//             RandomizedNFT.RandomizedNFT_TokenTransferFailed.selector
//         );
//         vm.prank(USER1);
//         nfts.mint{value: ethFee}(1);
//     }

//     // function test__RevertsWhen__EthTransferFails()
//     //     public
//     //     funded(USER1)
//     //     mintOpen
//     // {
//     //     uint256 ethFee = nfts.getEthFee();
//     //     uint256 tokenFee = nfts.getTokenFee();
//     //     vm.prank(USER1);
//     //     token.approve(address(nfts), tokenFee);

//     //     address feeAccount = nfts.getFeeAddress();
//     //     vm.mockCall(feeAccount, ethFee, "", abi.encode(false, ""));

//     //     vm.expectRevert(RandomizedNFT.RandomizedNFT_EthTransferFailed.selector);
//     //     vm.prank(USER1);
//     //     nfts.mint{value: ethFee}(1);
//     // }

//     ////////////////////////
//     //////   TRANSFER   ////
//     ////////////////////////

//     function test__TransferNfts(
//         address account,
//         address receiver,
//         uint256 numOfNfts
//     ) public funded(account) maxMintAllowed skipFork {
//         numOfNfts = bound(numOfNfts, 1, 100);
//         vm.assume(account != address(0));
//         vm.assume(receiver != address(0));

//         uint256 ethFee = numOfNfts * nfts.getEthFee();

//         vm.startPrank(account);
//         token.approve(address(nfts), numOfNfts * FUZZ_FEE);
//         nfts.mint{value: ethFee}(numOfNfts);
//         vm.stopPrank();

//         assertEq(nfts.balanceOf(account), numOfNfts);
//         for (uint256 index = 0; index < nfts.totalSupply(); index++) {
//             assertEq(nfts.ownerOf(index), account);
//             vm.prank(account);
//             nfts.transferFrom(account, receiver, index);
//             assertEq(nfts.ownerOf(index), receiver);
//         }

//         assertEq(nfts.balanceOf(receiver), numOfNfts);
//     }

//     ////////////////////////
//     ////// TOKEN URI //////
//     ///////////////////////

//     function test__RetrieveTokenUri() public funded(USER1) mintOpen {
//         uint256 ethFee = nfts.getEthFee();
//         uint256 tokenFee = nfts.getTokenFee();
//         vm.prank(USER1);
//         token.approve(address(nfts), tokenFee);

//         vm.prank(USER1);
//         nfts.mint{value: ethFee}(1);
//         assertEq(nfts.balanceOf(USER1), 1);

//         console.log(nfts.tokenURI(0));
//     }

//     /// forge-config: default.fuzz.runs = 3
//     function test__UniqueTokenURI(
//         uint roll
//     ) public funded(USER1) maxMintAllowed {
//         roll = bound(roll, 0, 100000000000);
//         TestHelper testHelper = new TestHelper();

//         uint256 maxSupply = nfts.getMaxSupply();

//         vm.startPrank(USER1);
//         for (uint256 index = 0; index < maxSupply; index++) {
//             vm.prevrandao(bytes32(uint256(index + roll)));
//             uint256 ethFee = nfts.getEthFee();
//             uint256 tokenFee = nfts.getTokenFee();
//             token.approve(address(nfts), tokenFee);
//             nfts.mint{value: ethFee}(1);
//             assertEq(testHelper.isTokenUriSet(nfts.tokenURI(index)), false);
//             console.log(nfts.tokenURI(index));
//             testHelper.setTokenUri(nfts.tokenURI(index));
//         }
//         vm.stopPrank();
//     }
// }
