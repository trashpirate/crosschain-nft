// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {RandomizedNFT} from "./RandomizedNFT.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@ccip/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DestinationMinter is CCIPReceiver, Ownable {
    /** Storage Variables */
    RandomizedNFT nft;

    /** Events */
    event DestinationMinter_MintCallSuccessfull();

    constructor(
        address router,
        RandomizedNFT.ConstructorArguments memory args
    ) CCIPReceiver(router) Ownable(msg.sender) {
        nft = new RandomizedNFT(args);
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

    /// @notice Override of CCIP Receiver to receive messages from CCIP router
    /// @param message from CCIP Router
    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        (bool success, ) = address(nft).call(message.data);
        require(success);
        emit DestinationMinter_MintCallSuccessfull();
    }
}
