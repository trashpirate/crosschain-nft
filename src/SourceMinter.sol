// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LinkTokenInterface} from "@ccip/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Withdraw} from "./utils/Withdraw.sol";

contract SourceMinter is Ownable {
    address immutable i_router;
    uint64 immutable i_chainSelector;

    event TokenFeeSet(address indexed sender, uint256 fee);
    event EthFeeSet(address indexed sender, uint256 fee);
    event FeeAddressSet(address indexed sender, address feeAddress);
    event SourceMinter_MessageSent(bytes32 messageId);
    error SourceMinter_FailedToWithdrawEth(
        address owner,
        address target,
        uint256 value
    );
    error RandomizedNFT_InsufficientTokenBalance();
    error RandomizedNFT_InsufficientEthFee(uint256 value, uint256 fee);
    error RandomizedNFT_FeeAddressIsZeroAddress();
    error RandomizedNFT_TokenTransferFailed();
    constructor(address router, uint64 chainSelector) Ownable(msg.sender) {
        i_router = router;
        i_chainSelector = chainSelector;
        // if (args.feeAddress == address(0))
        //     revert RandomizedNFT_FeeAddressIsZeroAddress();
        // i_paymentToken = IERC20(args.tokenAddress);
        // s_feeAddress = args.feeAddress;
        // s_tokenFee = args.tokenFee;
        // s_ethFee = args.ethFee;
    }

    receive() external payable {}

    function mint(address receiver) external {
        // if (i_paymentToken.balanceOf(msg.sender) < s_tokenFee * quantity)
        //     revert RandomizedNFT_InsufficientTokenBalance();
        // if (msg.value < s_ethFee * quantity)
        //     revert RandomizedNFT_InsufficientEthFee(msg.value, s_ethFee);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeWithSignature("mint(address)", msg.sender),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(i_chainSelector, message);

        bytes32 messageId;

        messageId = IRouterClient(i_router).ccipSend{value: fee}(
            i_chainSelector,
            message
        );

        //  (bool success, ) = payable(s_feeAddress).call{value: msg.value}("");
        // if (!success) revert RandomizedNFT_EthTransferFailed();

        // success = i_paymentToken.transferFrom(
        //     msg.sender,
        //     s_feeAddress,
        //     s_tokenFee * quantity
        // );
        // if (!success) revert RandomizedNFT_TokenTransferFailed();

        emit SourceMinter_MessageSent(messageId);
    }

    // /// @notice Sets minting fee in terms of ERC20 tokens (only owner)
    // /// @param fee New fee in ERC20 tokens
    // function setTokenFee(uint256 fee) external onlyOwner {
    //     s_tokenFee = fee;
    //     emit TokenFeeSet(msg.sender, fee);
    // }

    // /// @notice Sets minting fee in ETH (only owner)
    // /// @param fee New fee in ETH
    // function setEthFee(uint256 fee) external onlyOwner {
    //     s_ethFee = fee;
    //     emit EthFeeSet(msg.sender, fee);
    // }

    // /// @notice Sets the receiver address for the token fee (only owner)
    // /// @param feeAddress New receiver address for tokens received through minting
    // function setFeeAddress(address feeAddress) external onlyOwner {
    //     if (feeAddress == address(0)) {
    //         revert RandomizedNFT_FeeAddressIsZeroAddress();
    //     }
    //     s_feeAddress = feeAddress;
    //     emit FeeAddressSet(msg.sender, feeAddress);
    // }

    // /// @notice Gets payment token address
    // function getPaymentToken() external view returns (address) {
    //     return address(i_paymentToken);
    // }

    // /// @notice Gets minting token fee in ERC20
    // function getTokenFee() external view returns (uint256) {
    //     return s_tokenFee;
    // }

    // /// @notice Gets minting fee in ETH
    // function getEthFee() external view returns (uint256) {
    //     return s_ethFee;
    // }

    // /// @notice Gets address that receives minting fees
    // function getFeeAddress() external view returns (address) {
    //     return s_feeAddress;
    // }

    function withdraw(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        if (!sent)
            revert SourceMinter_FailedToWithdrawEth(
                msg.sender,
                beneficiary,
                amount
            );
    }

    function withdrawToken(
        address beneficiary,
        address token
    ) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }
}
