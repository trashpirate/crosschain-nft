// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "@erc721a/contracts/extensions/ERC721ABurnable.sol";

/// @title RandomizedNFT
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard using the ERC20 token for minting
contract RandomizedNFT is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {
    /** Types */
    struct ConstructorArguments {
        string name;
        string symbol;
        string baseURI;
        address tokenAddress;
        address feeAddress;
        uint256 tokenFee;
        uint256 ethFee;
        uint256 maxPerWallet;
        uint256 batchLimit;
        uint256 maxSupply;
    }

    /**
     * Storage Variables
     */
    uint256 private immutable i_maxSupply;
    IERC20 private immutable i_paymentToken;

    string private s_baseTokenURI;
    address private s_feeAddress;
    uint256 private s_tokenFee;
    uint256 private s_ethFee;
    uint256 private s_maxPerWallet;
    uint256 private s_batchLimit;

    mapping(uint256 tokenId => uint256) private s_tokenURIs;
    uint256[] private s_ids;

    /**
     * Events
     */
    event TokenFeeSet(address indexed sender, uint256 fee);
    event EthFeeSet(address indexed sender, uint256 fee);
    event FeeAddressSet(address indexed sender, address feeAddress);
    event MaxPerWalletSet(address indexed sender, uint256 maxPerWallet);
    event BatchLimitSet(address indexed sender, uint256 batchLimit);
    event MetadataUpdate(uint256 indexed tokenId);

    /**
     * Errors
     */
    error RandomizedNFT_InsufficientTokenBalance();
    error RandomizedNFT_InsufficientMintQuantity();
    error RandomizedNFT_ExceedsMaxSupply();
    error RandomizedNFT_ExceedsMaxPerWallet();
    error RandomizedNFT_ExceedsBatchLimit();
    error RandomizedNFT_FeeAddressIsZeroAddress();
    error RandomizedNFT_TokenTransferFailed();
    error RandomizedNFT_InsufficientEthFee(uint256 value, uint256 fee);
    error RandomizedNFT_EthTransferFailed();
    error RandomizedNFT_MaxPerWalletExceedsMaxSupply();
    error RandomizedNFT_MaxPerWalletSmallerThanBatchLimit();
    error RandomizedNFT_BatchLimitExceedsMaxPerWallet();
    error RandomizedNFT_BatchLimitTooHigh();
    error RandomizedNFT_NonexistentToken(uint256);
    error RandomizedNFT_TokenUriError();
    error RandomizedNFT_NoBaseURI();

    /// @notice Constructor
    // / @param initialOwner ownerhip is transfered to this address after creation
    // / @param feeAddress address to receive minting fees
    // / @param baseURI base uri for NFT metadata
    /// @dev inherits from ERC721A
    constructor(
        ConstructorArguments memory args
    ) ERC721A(args.name, args.symbol) Ownable(msg.sender) {
        if (args.feeAddress == address(0))
            revert RandomizedNFT_FeeAddressIsZeroAddress();
        if (bytes(args.baseURI).length == 0) revert RandomizedNFT_NoBaseURI();

        i_paymentToken = IERC20(args.tokenAddress);
        i_maxSupply = args.maxSupply;
        s_feeAddress = args.feeAddress;
        s_tokenFee = args.tokenFee;
        s_ethFee = args.ethFee;
        s_maxPerWallet = args.maxPerWallet;
        s_batchLimit = args.batchLimit;
        s_ids = new uint256[](args.maxSupply);

        _setBaseURI(args.baseURI);
    }

    receive() external payable {}

    /// @notice Mints NFT for a eth and a token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity) external payable nonReentrant {
        if (quantity == 0) revert RandomizedNFT_InsufficientMintQuantity();
        if (balanceOf(msg.sender) + quantity > s_maxPerWallet) {
            revert RandomizedNFT_ExceedsMaxPerWallet();
        }
        if (quantity > s_batchLimit) revert RandomizedNFT_ExceedsBatchLimit();
        if (_totalSupply() + quantity > i_maxSupply)
            revert RandomizedNFT_ExceedsMaxSupply();

        if (i_paymentToken.balanceOf(msg.sender) < s_tokenFee * quantity)
            revert RandomizedNFT_InsufficientTokenBalance();
        if (msg.value < s_ethFee * quantity)
            revert RandomizedNFT_InsufficientEthFee(msg.value, s_ethFee);

        uint256 tokenId = _nextTokenId();
        for (uint256 i = 0; i < quantity; i++) {
            unchecked {
                _setTokenURI(tokenId);
                tokenId++;
            }
        }
        _safeMint(msg.sender, quantity);

        (bool success, ) = payable(s_feeAddress).call{value: msg.value}("");
        if (!success) revert RandomizedNFT_EthTransferFailed();

        success = i_paymentToken.transferFrom(
            msg.sender,
            s_feeAddress,
            s_tokenFee * quantity
        );
        if (!success) revert RandomizedNFT_TokenTransferFailed();
    }

    /// @notice Sets minting fee in terms of ERC20 tokens (only owner)
    /// @param fee New fee in ERC20 tokens
    function setTokenFee(uint256 fee) external onlyOwner {
        s_tokenFee = fee;
        emit TokenFeeSet(msg.sender, fee);
    }

    /// @notice Sets minting fee in ETH (only owner)
    /// @param fee New fee in ETH
    function setEthFee(uint256 fee) external onlyOwner {
        s_ethFee = fee;
        emit EthFeeSet(msg.sender, fee);
    }

    /// @notice Sets the receiver address for the token fee (only owner)
    /// @param feeAddress New receiver address for tokens received through minting
    function setFeeAddress(address feeAddress) external onlyOwner {
        if (feeAddress == address(0)) {
            revert RandomizedNFT_FeeAddressIsZeroAddress();
        }
        s_feeAddress = feeAddress;
        emit FeeAddressSet(msg.sender, feeAddress);
    }

    /// @notice Sets the maximum number of nfts per wallet (only owner)
    /// @param maxPerWallet Maximum number of nfts that can be held by one account
    function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        if (maxPerWallet > i_maxSupply) {
            revert RandomizedNFT_MaxPerWalletExceedsMaxSupply();
        }
        if (maxPerWallet < s_batchLimit) {
            revert RandomizedNFT_MaxPerWalletSmallerThanBatchLimit();
        }
        s_maxPerWallet = maxPerWallet;
        emit MaxPerWalletSet(msg.sender, maxPerWallet);
    }

    /// @notice Sets batch limit - maximum number of nfts that can be minted at once (only owner)
    /// @param batchLimit Maximum number of nfts that can be minted at once
    function setBatchLimit(uint256 batchLimit) external onlyOwner {
        if (batchLimit > 100) revert RandomizedNFT_BatchLimitTooHigh();
        if (batchLimit > s_maxPerWallet) {
            revert RandomizedNFT_BatchLimitExceedsMaxPerWallet();
        }
        s_batchLimit = batchLimit;
        emit BatchLimitSet(msg.sender, batchLimit);
    }

    /// @notice Withdraw tokens from contract (only owner)
    /// @param tokenAddress Contract address of token to be withdrawn
    /// @param receiverAddress Tokens are withdrawn to this address
    /// @return success of withdrawal
    function withdrawTokens(
        address tokenAddress,
        address receiverAddress
    ) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        success = tokenContract.transfer(receiverAddress, amount);
    }

    /**
     * Getter Functions
     */

    /// @notice Gets payment token address
    function getPaymentToken() external view returns (address) {
        return address(i_paymentToken);
    }

    /// @notice Gets maximum supply
    function getMaxSupply() external view returns (uint256) {
        return i_maxSupply;
    }

    /// @notice Gets minting token fee in ERC20
    function getTokenFee() external view returns (uint256) {
        return s_tokenFee;
    }

    /// @notice Gets minting fee in ETH
    function getEthFee() external view returns (uint256) {
        return s_ethFee;
    }

    /// @notice Gets address that receives minting fees
    function getFeeAddress() external view returns (address) {
        return s_feeAddress;
    }

    /// @notice Gets number of nfts allowed minted at once
    function getBatchLimit() external view returns (uint256) {
        return s_batchLimit;
    }

    /// @notice Gets maximum number of nfts allowed per address
    function getMaxPerWallet() external view returns (uint256) {
        return s_maxPerWallet;
    }

    /// @notice Gets base uri
    function getBaseUri() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * Public Functions
     */

    /// @notice retrieves tokenURI
    /// @dev adapted from openzeppelin ERC721URIStorage contract
    /// @param tokenId tokenID of NFT
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = Strings.toString(s_tokenURIs[tokenId]);
        string memory base = _baseURI();

        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    /// @notice checks for supported interface
    /// @dev function override required by ERC721
    /// @param interfaceId interfaceId to be checked
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, IERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Internal/Private Functions
     */

    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721
    /// @param tokenId token id of NFT
    function _requireOwned(uint256 tokenId) internal view {
        ownerOf(tokenId);
    }

    /// @notice returns total supply
    function _totalSupply() private view returns (uint256) {
        return _nextTokenId();
    }

    /// @notice Sets base uri
    /// @param baseURI base uri for NFT metadata
    function _setBaseURI(string memory baseURI) private {
        s_baseTokenURI = baseURI;
    }

    /// @notice Retrieves base uri
    function _baseURI() internal view override returns (string memory) {
        return s_baseTokenURI;
    }

    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721URIStorage
    function _setTokenURI(uint256 tokenId) internal virtual {
        s_tokenURIs[tokenId] = _randomTokenURI();
        emit MetadataUpdate(tokenId);
    }

    /// @notice generates a random tokenUR
    function _randomTokenURI() private returns (uint256 randomTokenURI) {
        uint256 numAvailableURIs = s_ids.length;
        uint256 randIdx;

        unchecked {
            randIdx =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.prevrandao,
                            msg.sender,
                            block.timestamp
                        )
                    )
                ) %
                numAvailableURIs;
        }

        // get new and nonexisting random id
        randomTokenURI = (s_ids[randIdx] != 0) ? s_ids[randIdx] : randIdx;

        // update helper array
        s_ids[randIdx] = (s_ids[numAvailableURIs - 1] == 0)
            ? numAvailableURIs - 1
            : s_ids[numAvailableURIs - 1];
        s_ids.pop();
    }
}