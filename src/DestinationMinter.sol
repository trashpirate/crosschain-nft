// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {RandomizedNFT} from "./RandomizedNFT.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@ccip/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title DestinationMinter
/// @author Nadina Oates
/// @notice Destination minter as part of cross-chain NFT contract using CCIP
contract DestinationMinter is CCIPReceiver, Ownable {
    /** Storage Variables */
    RandomizedNFT private immutable nft;

    /** Events */
    event DestinationMinter_MintCallSuccessfull();

    /** Errors */
    error DestinationMinter_MintFailed();

    /// @notice Contructor
    /// @param router address of CCIP router on target chain
    /// @param args struct containing the constructor arguments for the NFT contract
    /// @dev inherits from CCIPReceiver (Chainlink) and Ownable (OpenZeppelin), code was adapted from Chainlink's cross-chain nft example
    constructor(
        address router,
        RandomizedNFT.ConstructorArguments memory args
    ) CCIPReceiver(router) Ownable(msg.sender) {
        // deploy NFT contract
        nft = new RandomizedNFT(args);
    }

    /// @notice Sets new contract uri
    /// @param contractURI base uri for metadata
    function setContractURI(string memory contractURI) external onlyOwner {
        nft.setContractURI(contractURI);
    }

    /// @notice Sets new base uri
    /// @param baseURI base uri for metadata
    function setBaseURI(string memory baseURI) external onlyOwner {
        nft.setBaseURI(baseURI);
    }

    /// @notice Sets royalty
    /// @param feeAddress address receiving royalties
    /// @param numerator numerator to calculate fees (denominator is 10000)
    function setRoyalty(
        address feeAddress,
        uint96 numerator
    ) external onlyOwner {
        nft.setRoyalty(feeAddress, numerator);
    }

    /// @notice Sets the maximum number of nfts per wallet in NFT contract
    /// @param maxPerWallet Maximum number of nfts that can be held by one account
    function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        nft.setMaxPerWallet(maxPerWallet);
    }

    /// @notice Sets batch limit in NFT contract
    /// @param batchLimit Maximum number of nfts that can be minted at once
    function setBatchLimit(uint256 batchLimit) external onlyOwner {
        nft.setBatchLimit(batchLimit);
    }

    /// @notice Gets NFT contract address
    function getNftContractAddress() external view returns (address) {
        return address(nft);
    }

    /// @notice Gets CCIP router address
    function getRouterAddress() external view returns (address) {
        return address(i_ccipRouter);
    }

    /// @notice Override of CCIP Receiver to receive messages from CCIP router
    /// @param message from CCIP Router
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        (bool success, ) = address(nft).call(message.data);
        if (!success) revert DestinationMinter_MintFailed();
        emit DestinationMinter_MintCallSuccessfull();
    }
}
