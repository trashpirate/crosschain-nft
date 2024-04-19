// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {SourceMinter} from "../../src/SourceMinter.sol";

contract MintNfts is Script {
    function mintNFT(
        address recentContractAddress,
        address recentReceiverAddress
    ) public {
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        SourceMinter(payable(recentContractAddress)).mint{
            value: SourceMinter(payable(recentContractAddress)).getEthFee()
        }(recentReceiverAddress, 1);
        console.log("Minting gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        console.log("Minted 1 NFT with:", msg.sender);
    }

    // function mintMultipleNfts(address recentContractAddress) public {
    //     vm.startBroadcast();
    //     uint256 gasLeft = gasleft();
    //     RandomizedNFT(payable(recentContractAddress)).mint{
    //         value: 3 * RandomizedNFT(payable(recentContractAddress)).getEthFee()
    //     }(3);
    //     console.log("Minting gas: ", gasLeft - gasleft());
    //     vm.stopBroadcast();

    //     console.log("Minted 3 NFT with:", msg.sender);
    // }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "SourceMinter",
            block.chainid
        );
        address recentReceiverAddress = DevOpsTools.get_most_recent_deployment(
            "DestinationMinter",
            block.chainid
        );
        mintNFT(recentContractAddress, recentReceiverAddress);
    }
}
