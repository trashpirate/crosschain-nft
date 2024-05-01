// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title SourceMinter
/// @author Nadina Oates
/// @notice Source minter as part of cross-chain NFT contract using CCIP
contract SourceMinter is Ownable, ReentrancyGuard {
    /** Types */
    struct ConstructorArguments {
        address router;
        uint64 chainSelector;
        address tokenAddress;
        address feeAddress;
        uint256 tokenFee;
        uint256 ethFee;
        uint256 maxSupply;
    }

    /** Storage Variables */
    address immutable i_ccipRouter;
    uint64 immutable i_chainSelector;

    IERC20 immutable i_paymentToken;

    address s_feeAddress;
    uint256 s_tokenFee;
    uint256 s_ethFee;

    bool s_paused;

    /** Events */
    event TokenFeeSet(address indexed sender, uint256 fee);
    event EthFeeSet(address indexed sender, uint256 fee);
    event FeeAddressSet(address indexed sender, address feeAddress);
    event SourceMinter_MessageSent(bytes32 messageId);
    event Paused(address indexed sender, bool isPaused);

    /** Errors */
    error SourceMinter_FailedToWithdrawEth(
        address owner,
        address target,
        uint256 value
    );
    error SourceMinter_InsufficientTokenBalance();
    error SourceMinter_InsufficientEthFee(uint256 value, uint256 fee);
    error SourceMinter_InsufficientContractBalance(
        uint256 fee,
        uint256 balance
    );
    error SourceMinter_FeeAddressIsZeroAddress();
    error SourceMinter_TokenTransferFailed();
    error SourceMinter_EthTransferFailed();
    error SourceMinter_ContractIsPaused();

    /// @notice Constructor
    /// @param args constructor arguments:
    ///                 router: CCIP router address on source chain
    ///                 chainsSelector: CCIP chain selector for target chain
    ///                 feeAddress: address collecting minting fees
    ///                 tokenAddress: contract address of payment token (ERC20)
    ///                 tokenFee: minting fee in tokens
    ///                 ethFee: minting fee in native coin
    ///                 tokenFee: minting fee in tokens
    /// @dev inherits from Ownable (OpenZeppelin)
    constructor(ConstructorArguments memory args) Ownable(msg.sender) {
        i_ccipRouter = args.router;
        i_chainSelector = args.chainSelector;

        if (args.feeAddress == address(0))
            revert SourceMinter_FeeAddressIsZeroAddress();
        i_paymentToken = IERC20(args.tokenAddress);
        s_feeAddress = args.feeAddress;
        s_tokenFee = args.tokenFee;
        s_ethFee = args.ethFee;

        s_paused = true;
    }

    receive() external payable {}

    /// @notice Withdraws ETH from contract
    /// @param beneficiary address receiving funds
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

    /// @notice Withdraws Tokens from contract
    /// @param beneficiary address receiving funds
    /// @param token address of ERC20 to be withdrawn
    function withdrawTokens(
        address beneficiary,
        address token
    ) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        bool sent = IERC20(token).transfer(beneficiary, amount);
        if (!sent) revert SourceMinter_TokenTransferFailed();
    }

    /// @notice Pauses minting
    /// @param _isPaused boolean to set minting to be paused (true) or unpaused (false)
    function pause(bool _isPaused) external onlyOwner {
        s_paused = _isPaused;
        emit Paused(msg.sender, _isPaused);
    }

    /// @notice Mints NFT
    /// @param receiver contract address for minting on target chain
    /// @param quantity how many NFTs to be minted
    function mint(
        address receiver,
        uint256 quantity
    ) external payable nonReentrant {
        if (s_paused) revert SourceMinter_ContractIsPaused();

        uint256 tokenMintFee = s_tokenFee * quantity;

        if (i_paymentToken.balanceOf(msg.sender) < tokenMintFee)
            revert SourceMinter_InsufficientTokenBalance();

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

        // estimate fees
        uint256 ccipFee = IRouterClient(i_ccipRouter).getFee(
            i_chainSelector,
            message
        );

        uint256 ethMintFee = s_ethFee * quantity;
        uint256 totalEthFee = ethMintFee + ccipFee;

        if (msg.value < totalEthFee)
            revert SourceMinter_InsufficientEthFee(msg.value, totalEthFee);

        // pay mint fee in eth
        if (ethMintFee > 0) {
            (bool success, ) = payable(s_feeAddress).call{value: ethMintFee}(
                ""
            );
            if (!success) revert SourceMinter_EthTransferFailed();
        }

        // pay mint fee in token
        if (tokenMintFee > 0) {
            bool success = i_paymentToken.transferFrom(
                msg.sender,
                s_feeAddress,
                tokenMintFee
            );
            if (!success) revert SourceMinter_TokenTransferFailed();
        }

        // send message via ccip
        bytes32 messageId = IRouterClient(i_ccipRouter).ccipSend{
            value: ccipFee
        }(i_chainSelector, message);

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

    /// @notice Gets chainlink router
    function getCCIPFee(
        address receiver,
        uint256 quantity
    ) external view returns (uint256) {
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

        // estimate fees
        uint256 ccipFee = IRouterClient(i_ccipRouter).getFee(
            i_chainSelector,
            message
        );
        return ccipFee;
    }

    /// @notice Gets chainlink router
    function getRouterAddress() external view returns (address) {
        return address(i_ccipRouter);
    }

    /// @notice Gets chainlink chain selector
    function getChainSelector() external view returns (uint64) {
        return uint64(i_chainSelector);
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

    /// @notice Gets whether contract is paused
    function isPaused() external view returns (bool) {
        return s_paused;
    }
}
