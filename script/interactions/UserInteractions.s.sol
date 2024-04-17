// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {RandomizedNFT} from "../../src/RandomizedNFT.sol";

contract MintNfts is Script {
    function mintSingleNft(address recentContractAddress) public {
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        RandomizedNFT(payable(recentContractAddress)).mint{
            value: RandomizedNFT(payable(recentContractAddress)).getEthFee()
        }(1);
        console.log("Minting gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        console.log("Minted 1 NFT with:", msg.sender);
    }

    function mintMultipleNfts(address recentContractAddress) public {
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        RandomizedNFT(payable(recentContractAddress)).mint{
            value: 3 * RandomizedNFT(payable(recentContractAddress)).getEthFee()
        }(3);
        console.log("Minting gas: ", gasLeft - gasleft());
        vm.stopBroadcast();

        console.log("Minted 3 NFT with:", msg.sender);
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        mintMultipleNfts(recentContractAddress);
    }
}

contract TransferNft is Script {
    address NEW_USER = makeAddr("new-user");

    function transferNft(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).transferFrom(
            tx.origin,
            NEW_USER,
            0
        );
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        transferNft(recentContractAddress);
    }
}

contract ApproveNft is Script {
    address SENDER = makeAddr("sender");

    function approveNft(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).approve(SENDER, 0);
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        approveNft(recentContractAddress);
    }
}
