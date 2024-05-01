// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {ERC20Token} from "./../../src/ERC20Token.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";
import {DestinationMinter} from "./../../src/DestinationMinter.sol";
import {DeployDestinationMinter} from "./../../script/deployment/DeployDestinationMinter.s.sol";
import {RandomizedNFT} from "./../../src/RandomizedNFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestDestinationMinter is Test {
    // configuration
    DeployDestinationMinter deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contracts
    DestinationMinter destinationMinter;
    RandomizedNFT nfts;

    // helpers
    address USER = makeAddr("user");
    uint256 constant NEW_BATCH_LIMIT = 10;
    uint256 constant NEW_MAX_PER_WALLET = 10;

    // events
    event MaxPerWalletSet(address indexed sender, uint256 maxPerWallet);
    event BatchLimitSet(address indexed sender, uint256 batchLimit);
    event BaseURIUpdated(string indexed baseUri);
    event RoyaltyUpdated(
        address indexed feeAddress,
        uint96 indexed royaltyNumerator
    );
    event ContractURIUpdated(string indexed contractUri);

    function setUp() external virtual {
        deployment = new DeployDestinationMinter();
        (destinationMinter, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();

        nfts = RandomizedNFT(destinationMinter.getNftContractAddress());
    }

    /** DEPLOYMENT */

    function test__DestinationContractInitialization() public view {
        RandomizedNFT nftContract = RandomizedNFT(
            destinationMinter.getNftContractAddress()
        );
        assertEq(nftContract.supportsInterface(0x80ac58cd), true);
        assertEq(
            destinationMinter.getRouterAddress(),
            networkConfig.destinationRouter
        );
        uint256 salePrice = 100;
        (address feeAddress, uint256 royaltyAmount) = nftContract.royaltyInfo(
            0,
            salePrice
        );
        assertEq(feeAddress, nfts.owner());
        assertEq(royaltyAmount, 5);
    }

    /** SET BASE  URI */
    function test__SetBaseUri() public {
        address owner = destinationMinter.owner();
        string memory baseURI = "new uri";

        vm.prank(owner);
        destinationMinter.setBaseURI(baseURI);

        assertEq(nfts.getBaseURI(), baseURI);
    }

    function test__EmitEvent__SetBaseUri() public {
        string memory baseURI = "new uri";
        address owner = destinationMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit BaseURIUpdated(baseURI);

        vm.prank(owner);
        destinationMinter.setBaseURI(baseURI);
    }

    function test__RevertWhen__NotOwnerSetsBaseUri() public {
        string memory baseURI = "new uri";
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );

        vm.prank(USER);
        destinationMinter.setBaseURI(baseURI);
    }

    /** SET CONTRACT  URI */
    function test__SetContractUri() public {
        address owner = destinationMinter.owner();
        string memory newContractURI = "new uri";

        vm.prank(owner);
        destinationMinter.setContractURI(newContractURI);

        assertEq(nfts.contractURI(), newContractURI);
    }

    function test__EmitEvent__SetContractUri() public {
        string memory newContractURI = "new uri";
        address owner = destinationMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit ContractURIUpdated(newContractURI);

        vm.prank(owner);
        destinationMinter.setContractURI(newContractURI);
    }

    function test__RevertWhen__NotOwnerSetsContractUri() public {
        string memory newContractURI = "new uri";
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );

        vm.prank(USER);
        destinationMinter.setContractURI(newContractURI);
    }

    /** SET ROYALTY */
    function test__SetRoyalty() public {
        address owner = destinationMinter.owner();
        uint96 newRoyalty = 1000;
        vm.prank(owner);
        destinationMinter.setRoyalty(USER, newRoyalty);
        uint256 salePrice = 100;
        (address feeAddress, uint256 royaltyAmount) = nfts.royaltyInfo(
            0,
            salePrice
        );
        assertEq(feeAddress, USER);
        assertEq(royaltyAmount, 10);
    }

    function test__EmitEvent__SetRoyalty() public {
        uint96 newRoyalty = 1000;
        address owner = destinationMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit RoyaltyUpdated(USER, newRoyalty);

        vm.prank(owner);
        destinationMinter.setRoyalty(USER, newRoyalty);
    }

    function test__RevertWhen__NotOwnerSetsRoyalty() public {
        uint96 newRoyalty = 1000;
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );

        vm.prank(USER);
        destinationMinter.setRoyalty(USER, newRoyalty);
    }

    /** SET MAX PER WALLET */
    function test__SetMaxPerWallet() public {
        address owner = destinationMinter.owner();

        vm.prank(owner);
        destinationMinter.setMaxPerWallet(NEW_MAX_PER_WALLET);

        assertEq(nfts.getMaxPerWallet(), NEW_MAX_PER_WALLET);
    }

    function test__EmitEvent__SetMaxPerWallet() public {
        uint256 maxPerWallet = nfts.getMaxPerWallet();

        address owner = destinationMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit MaxPerWalletSet(address(destinationMinter), maxPerWallet - 1);

        vm.prank(owner);
        destinationMinter.setMaxPerWallet(maxPerWallet - 1);
    }

    function test__RevertWhen__NotOwnerSetsMaxPerWallet() public {
        uint256 maxPerWallet = nfts.getMaxPerWallet();
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );

        vm.prank(USER);
        destinationMinter.setMaxPerWallet(maxPerWallet - 1);
    }

    /** SET BATCH LIMIT */
    function test__SetBatchLimit() public {
        address owner = destinationMinter.owner();

        vm.prank(owner);
        destinationMinter.setBatchLimit(NEW_BATCH_LIMIT);

        assertEq(nfts.getBatchLimit(), NEW_BATCH_LIMIT);
    }

    function test__EmitEvent__SetBatchLimit() public {
        uint256 batchLimit = nfts.getBatchLimit();

        address owner = destinationMinter.owner();

        vm.expectEmit(true, true, true, true);
        emit BatchLimitSet(address(destinationMinter), batchLimit - 1);

        vm.prank(owner);
        destinationMinter.setBatchLimit(batchLimit - 1);
    }

    function test__RevertWhen__NotOwnerSetsBatchLimit() public {
        uint256 batchLimit = nfts.getBatchLimit();
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                USER
            )
        );

        vm.prank(USER);
        destinationMinter.setBatchLimit(batchLimit - 1);
    }
}
