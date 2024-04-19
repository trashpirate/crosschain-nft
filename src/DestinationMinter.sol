// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {RandomizedNFT} from "./RandomizedNFT.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@ccip/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";

contract DestinationMinter is CCIPReceiver {
    /** Storage Variables */
    RandomizedNFT nft;

    /** Events */
    event MintCallSuccessfull();

    constructor(
        address router,
        RandomizedNFT.ConstructorArguments memory args
    ) CCIPReceiver(router) {
        nft = new RandomizedNFT(args);
    }

    function getNftContractAddress() external view returns (address) {
        return address(nft);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        (bool success, ) = address(nft).call(message.data);
        require(success);
        emit MintCallSuccessfull();
    }
}
