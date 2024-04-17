// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {OwnerIsCreator} from "@ccip/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Withdraw is Ownable {
    error Withdraw_FailedToWithdrawEth(
        address owner,
        address target,
        uint256 value
    );

    constructor() Ownable(msg.sender) {}

    function withdraw(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        if (!sent)
            revert Withdraw_FailedToWithdrawEth(
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
