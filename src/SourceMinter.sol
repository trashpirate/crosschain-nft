// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LinkTokenInterface} from "@ccip/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Withdraw} from "./utils/Withdraw.sol";

contract SourceMinter is Ownable {
    enum PayFeesIn {
        Native,
        LINK
    }

    address immutable i_router;
    uint64 immutable i_chainSelector;

    event SourceMinter_MessageSent(bytes32 messageId);
    error SourceMinter_FailedToWithdrawEth(
        address owner,
        address target,
        uint256 value
    );

    constructor(address router, uint64 chainSelector) Ownable(msg.sender) {
        i_router = router;
        i_chainSelector = chainSelector;
    }

    receive() external payable {}

    function mint(address receiver) external {
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

        emit SourceMinter_MessageSent(messageId);
    }

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
