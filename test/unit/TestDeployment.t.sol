// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// import {Test, console} from "forge-std/Test.sol";
// import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import {IERC721, ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";

// import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";
// import {ERC20Token} from "../../src/ERC20Token.sol";

// import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
// import {DeployRandomizedNFT} from "./../../script/deployment/DeployRandomizedNFT.s.sol";
// import {TestSetup} from "./TestSetup.t.sol";

// contract TestDeployment is TestSetup {
//     // configuration

//     // function test__Initialization() public view {
//     //     ERC20 paymentToken = ERC20(nfts.getPaymentToken());
//     //     string memory feeTokenSymbol = paymentToken.symbol();
//     //     assertEq(feeTokenSymbol, "TEST");
//     //     assertEq(nfts.supportsInterface(0x80ac58cd), true);
//     // }

//     // function test__ConstructorArguments() public view {
//     //     assertEq(nfts.name(), networkConfig.args.name);
//     //     assertEq(nfts.symbol(), networkConfig.args.symbol);
//     //     assertEq(nfts.getPaymentToken(), networkConfig.args.tokenAddress);
//     //     assertEq(nfts.getFeeAddress(), networkConfig.args.feeAddress);
//     //     assertEq(nfts.getTokenFee(), networkConfig.args.tokenFee);
//     //     assertEq(nfts.getEthFee(), networkConfig.args.ethFee);
//     //     assertEq(nfts.getMaxPerWallet(), networkConfig.args.maxPerWallet);
//     //     assertEq(nfts.getBatchLimit(), networkConfig.args.batchLimit);
//     //     assertEq(nfts.getMaxSupply(), networkConfig.args.maxSupply);
//     //     assertEq(nfts.getBaseUri(), networkConfig.args.baseURI);
//     // }

//     // function test__NoTokenMinted() public {
//     //     vm.expectRevert(IERC721A.OwnerQueryForNonexistentToken.selector);
//     //     nfts.tokenURI(0);
//     // }

//     // function test__NoBaseUriOnDeployment() public {
//     //     vm.expectRevert(RandomizedNFT.RandomizedNFT_NoBaseURI.selector);

//     //     RandomizedNFT.ConstructorArguments memory newArgs = RandomizedNFT
//     //         .ConstructorArguments({
//     //             name: networkConfig.args.name,
//     //             symbol: networkConfig.args.symbol,
//     //             baseURI: "",
//     //             tokenAddress: networkConfig.args.tokenAddress,
//     //             feeAddress: networkConfig.args.feeAddress,
//     //             tokenFee: networkConfig.args.tokenFee,
//     //             ethFee: networkConfig.args.ethFee,
//     //             maxPerWallet: networkConfig.args.maxPerWallet,
//     //             batchLimit: networkConfig.args.batchLimit,
//     //             maxSupply: networkConfig.args.maxSupply
//     //         });
//     //     new RandomizedNFT(newArgs);
//     // }
// }
