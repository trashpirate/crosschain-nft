// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RandomizedNFT} from "../../src/RandomizedNFT.sol";

contract SetNewTokenFee is Script {
    uint256 constant NEW_FEE = 100 * 10 ** 18;

    IERC20 token;

    function setNewTokenFee(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).setTokenFee(NEW_FEE);
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        setNewTokenFee(recentContractAddress);
    }
}

contract SetNewEthFee is Script {
    uint256 constant NEW_FEE = 100 ether;

    IERC20 token;

    function setNewEthFee(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).setEthFee(NEW_FEE);
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        setNewEthFee(recentContractAddress);
    }
}

contract SetNewFeeAddress is Script {
    address NEW_FEE_ADDRESS = makeAddr("fee");

    IERC20 token;

    function setNewFeeAddress(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).setFeeAddress(
            NEW_FEE_ADDRESS
        );
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );

        setNewFeeAddress(recentContractAddress);
    }
}

contract SetNewMaxPerWallet is Script {
    uint256 constant NEW_MAX_PER_WALLET = 10;
    IERC20 token;

    function setNewMaxPerWallet(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).setMaxPerWallet(
            NEW_MAX_PER_WALLET
        );
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        setNewMaxPerWallet(recentContractAddress);
    }
}

contract SetNewBatchLimit is Script {
    uint256 constant NEW_BATCH_LIMIT = 5;
    IERC20 token;

    function setNewBatchLimit(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).setBatchLimit(
            NEW_BATCH_LIMIT
        );
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        setNewBatchLimit(recentContractAddress);
    }
}

contract SetMaxBatchLimit is Script {
    uint256 constant NEW_BATCH_LIMIT = 100;
    IERC20 token;

    function setNewBatchLimit(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).setBatchLimit(
            NEW_BATCH_LIMIT
        );
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        setNewBatchLimit(recentContractAddress);
    }
}

contract WithdrawTokensFromContract is Script {
    address TOKEN_RECEIVER = makeAddr("token-receiver");
    IERC20 token;

    function withrawTokensFromContract(address recentContractAddress) public {
        vm.startBroadcast();
        RandomizedNFT(payable(recentContractAddress)).withdrawTokens(
            RandomizedNFT(payable(recentContractAddress)).getPaymentToken(),
            tx.origin
        );
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment(
            "RandomizedNFT",
            block.chainid
        );
        withrawTokensFromContract(recentContractAddress);
    }
}
