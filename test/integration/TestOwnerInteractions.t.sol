// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// import {Test, console} from "forge-std/Test.sol";
// import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import {RandomizedNFT} from "../../src/RandomizedNFT.sol";
// import {ERC20Token} from "../../src/ERC20Token.sol";

// import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
// import {DeployRandomizedNFT} from "../../script/deployment/DeployRandomizedNFT.s.sol";
// import {SetNewTokenFee, SetNewEthFee, SetNewFeeAddress, SetNewMaxPerWallet, SetNewBatchLimit, WithdrawTokensFromContract} from "../../script/interactions/OwnerInteractions.s.sol";

// contract OwnerInteractionsTest is Test {
//     RandomizedNFT nftContract;
//     ERC20Token token;
//     HelperConfig helperConfig;

//     address USER = makeAddr("user");
//     address NEW_FEE_ADDRESS = makeAddr("fee");
//     address TOKEN_RECEIVER = makeAddr("token-receiver");
//     address OWNER;
//     address TOKEN_OWNER;
//     uint256 constant TOKEN_BALANCE = 100_000 * 10 ** 18;

//     uint256 constant INITIAL_FEE = 10_000 * 10 ** 18;
//     uint256 constant NEW_FEE = 100 * 10 ** 18;
//     uint256 constant NEW_BATCH_LIMIT = 5;
//     uint256 constant NEW_MAX_PER_WALLET = 10;

//     function setUp() external {
//         DeployRandomizedNFT deployment = new DeployRandomizedNFT();
//         (nftContract, helperConfig) = deployment.run();
//         token = ERC20Token(nftContract.getPaymentToken());
//         TOKEN_OWNER = token.owner();
//         OWNER = nftContract.owner();
//         vm.prank(OWNER);
//         nftContract.transferOwnership(msg.sender);
//     }

//     function test__Integration__OwnerCanSetTokenFee() public {
//         SetNewTokenFee setNewTokenFee = new SetNewTokenFee();
//         setNewTokenFee.setNewTokenFee(address(nftContract));

//         assertEq(nftContract.getTokenFee(), NEW_FEE);
//     }

//     function test__Integration__OwnerCanSetEthFee() public {
//         SetNewEthFee setNewEthFee = new SetNewEthFee();
//         setNewEthFee.setNewEthFee(address(nftContract));

//         assertEq(nftContract.getEthFee(), NEW_FEE);
//     }

//     function test__Integration__OwnerCanSetFeeAddress() public {
//         SetNewFeeAddress setNewFeeAddress = new SetNewFeeAddress();
//         setNewFeeAddress.setNewFeeAddress(address(nftContract));

//         assertEq(nftContract.getFeeAddress(), NEW_FEE_ADDRESS);
//     }

//     function test__Integration__OwnerCanSetMaxPerWallet() public {
//         SetNewMaxPerWallet setNewMaxPerWallet = new SetNewMaxPerWallet();
//         setNewMaxPerWallet.setNewMaxPerWallet(address(nftContract));

//         assertEq(nftContract.getMaxPerWallet(), NEW_MAX_PER_WALLET);
//     }

//     function test__Integration__OwnerCanSetBatchLimit() public {
//         SetNewBatchLimit setNewBatchLimit = new SetNewBatchLimit();
//         setNewBatchLimit.setNewBatchLimit(address(nftContract));

//         assertEq(nftContract.getBatchLimit(), NEW_BATCH_LIMIT);
//     }

//     function test__Integration__OwnerCanWithdrawTokens() public {
//         vm.prank(TOKEN_OWNER);
//         token.transfer(address(nftContract), TOKEN_BALANCE);
//         assertEq(token.balanceOf(address(nftContract)), TOKEN_BALANCE);

//         uint256 startingBalance = token.balanceOf(msg.sender);
//         WithdrawTokensFromContract withdrawTokensFromContract = new WithdrawTokensFromContract();
//         withdrawTokensFromContract.withrawTokensFromContract(
//             address(nftContract)
//         );

//         assertEq(token.balanceOf(address(nftContract)), 0);
//         assertEq(token.balanceOf(msg.sender) - startingBalance, TOKEN_BALANCE);
//     }
// }
