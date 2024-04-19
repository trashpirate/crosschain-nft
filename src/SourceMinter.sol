// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LinkTokenInterface} from "@ccip/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SourceMinter is Ownable {
    /** types */
    struct ConstructorArguments {
        address router;
        uint64 chainSelector;
        address tokenAddress;
        address feeAddress;
        uint256 tokenFee;
        uint256 ethFee;
        uint256 maxSupply;
    }

    /** storage variables */
    address immutable i_router;
    uint64 immutable i_chainSelector;

    IERC20 immutable i_paymentToken;
    uint256 immutable i_maxSupply;

    address s_feeAddress;
    uint256 s_tokenFee;
    uint256 s_ethFee;

    bool s_paused;

    /** events */
    event TokenFeeSet(address indexed sender, uint256 fee);
    event EthFeeSet(address indexed sender, uint256 fee);
    event FeeAddressSet(address indexed sender, address feeAddress);
    event SourceMinter_MessageSent(bytes32 messageId);
    event Paused(address indexed sender, bool isPaused);

    /** errors */
    error SourceMinter_FailedToWithdrawEth(
        address owner,
        address target,
        uint256 value
    );

    error SourceMinter_InsufficientTokenBalance();
    error SourceMinter_InsufficientEthFee(uint256 value, uint256 fee);
    error SourceMinter_FeeAddressIsZeroAddress();
    error SourceMinter_TokenTransferFailed();
    error SourceMinter_EthTransferFailed();
    error SourceMinter_ContractIsPaused();

    constructor(ConstructorArguments memory args) Ownable(msg.sender) {
        i_router = args.router;
        i_chainSelector = args.chainSelector;

        if (args.feeAddress == address(0))
            revert SourceMinter_FeeAddressIsZeroAddress();
        i_paymentToken = IERC20(args.tokenAddress);
        s_feeAddress = args.feeAddress;
        s_tokenFee = args.tokenFee;
        s_ethFee = args.ethFee;

        i_maxSupply = args.maxSupply;

        s_paused = true;
    }

    receive() external payable {}

    function withdrawETH(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        if (!sent)
            revert SourceMinter_FailedToWithdrawEth(
                msg.sender,
                beneficiary,
                amount
            );
    }

    function withdrawTokens(
        address beneficiary,
        address token
    ) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }

    function pause(bool _isPaused) external onlyOwner {
        s_paused = _isPaused;
        emit Paused(msg.sender, _isPaused);
    }

    function mint(address receiver, uint256 quantity) external payable {
        if (s_paused) revert SourceMinter_ContractIsPaused();
        if (i_paymentToken.balanceOf(msg.sender) < s_tokenFee * quantity)
            revert SourceMinter_InsufficientTokenBalance();
        if (msg.value < s_ethFee * quantity)
            revert SourceMinter_InsufficientEthFee(
                msg.value,
                s_ethFee * quantity
            );

        (bool success, ) = payable(s_feeAddress).call{value: msg.value}("");
        if (!success) revert SourceMinter_EthTransferFailed();

        success = i_paymentToken.transferFrom(
            msg.sender,
            s_feeAddress,
            s_tokenFee * quantity
        );
        if (!success) revert SourceMinter_TokenTransferFailed();

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeWithSignature(
                "mint(address,uint256)",
                msg.sender,
                quantity
            ),
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

        emit SourceMinter_MessageSent(messageId);
    }

    /// @notice Sets minting fee in terms of ERC20 tokens (only owner)
    /// @param fee New fee in ERC20 tokens
    function setTokenFee(uint256 fee) external onlyOwner {
        s_tokenFee = fee;
        emit TokenFeeSet(msg.sender, fee);
    }

    /// @notice Sets minting fee in ETH (only owner)
    /// @param fee New fee in ETH
    function setEthFee(uint256 fee) external onlyOwner {
        s_ethFee = fee;
        emit EthFeeSet(msg.sender, fee);
    }

    /// @notice Sets the receiver address for the token fee (only owner)
    /// @param feeAddress New receiver address for tokens received through minting
    function setFeeAddress(address feeAddress) external onlyOwner {
        if (feeAddress == address(0)) {
            revert SourceMinter_FeeAddressIsZeroAddress();
        }
        s_feeAddress = feeAddress;
        emit FeeAddressSet(msg.sender, feeAddress);
    }

    /// @notice Gets payment token address
    function getPaymentToken() external view returns (address) {
        return address(i_paymentToken);
    }

    /// @notice Gets minting token fee in ERC20
    function getTokenFee() external view returns (uint256) {
        return s_tokenFee;
    }

    /// @notice Gets minting fee in ETH
    function getEthFee() external view returns (uint256) {
        return s_ethFee;
    }

    /// @notice Gets address that receives minting fees
    function getFeeAddress() external view returns (address) {
        return s_feeAddress;
    }

    /// @notice Gets maximum supply
    function getMaxSupply() external view returns (uint256) {
        return i_maxSupply;
    }

    /// @notice Gets whether contract is paused
    function isPaused() external view returns (bool) {
        return s_paused;
    }
}
