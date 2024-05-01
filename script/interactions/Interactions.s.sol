// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {SourceMinter} from "../../src/SourceMinter.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";

contract MintNft is Script {
    uint256 constant CCIP_FEE = 0.00001 ether;

    function mintNft(
        address recentContractAddress,
        address recentReceiverAddress
    ) public {
        uint256 ethFee = SourceMinter(payable(recentContractAddress))
            .getEthFee() +
            SourceMinter(payable(recentContractAddress)).getCCIPFee(
                recentReceiverAddress,
                1
            );
        vm.startBroadcast();

        uint256 gasLeft = gasleft();
        SourceMinter(payable(recentContractAddress)).mint{value: ethFee}(
            recentReceiverAddress,
            1
        );
        console.log("Minting gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        console.log("Minted 1 NFT with:", msg.sender);
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "SourceMinter",
            block.chainid
        );
        address recentReceiverAddress = DevOpsTools.get_most_recent_deployment(
            "DestinationMinter",
            84532
        );
        mintNft(recentContractAddress, recentReceiverAddress);
    }
}

contract BatchMint is Script {
    uint256 public constant BATCH_SIZE = 2;
    uint256 constant CCIP_FEE = 0.00001 ether;

    function batchMint(
        address recentContractAddress,
        address recentReceiverAddress
    ) public {
        uint256 ethFee = BATCH_SIZE *
            SourceMinter(payable(recentContractAddress)).getEthFee() +
            CCIP_FEE;
        vm.startBroadcast();

        uint256 gasLeft = gasleft();
        SourceMinter(payable(recentContractAddress)).mint{value: ethFee}(
            recentReceiverAddress,
            BATCH_SIZE
        );
        console.log("Minting gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        console.log("Minted 1 NFT with:", msg.sender);
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "SourceMinter",
            block.chainid
        );
        address recentReceiverAddress = DevOpsTools.get_most_recent_deployment(
            "DestinationMinter",
            block.chainid
        );
        batchMint(recentContractAddress, recentReceiverAddress);
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
    address public SENDER = makeAddr("sender");

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

contract BurnNft is Script {
    address public SENDER = makeAddr("sender");

    function burnNft(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).burn(0);
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        burnNft(recentContractAddress);
    }
}
