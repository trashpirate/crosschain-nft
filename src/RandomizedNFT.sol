// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "@erc721a/contracts/extensions/ERC721ABurnable.sol";

/// @title RandomizedNFT
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard using the ERC20 and native token for minting
contract RandomizedNFT is ERC721A, ERC721ABurnable, ERC2981, Ownable {
    /** Types */
    struct ConstructorArguments {
        string name;
        string symbol;
        string baseURI;
        string contractURI;
        uint96 royaltyNumerator;
        uint256 maxPerWallet;
        uint256 batchLimit;
        uint256 maxSupply;
    }

    /**
     * Storage Variables
     */
    uint256 private immutable i_maxSupply;

    string private s_contractURI;
    string private s_baseTokenURI;
    uint256 private s_maxPerWallet;
    uint256 private s_batchLimit;

    mapping(uint256 tokenId => uint256) private s_tokenURIs;
    uint256[] private s_ids;

    /**
     * Events
     */

    event MaxPerWalletSet(address indexed sender, uint256 maxPerWallet);
    event BatchLimitSet(address indexed sender, uint256 batchLimit);
    event BaseURIUpdated(string indexed baseUri);
    event ContractURIUpdated(string indexed contractUri);
    event RoyaltyUpdated(
        address indexed feeAddress,
        uint96 indexed royaltyNumerator
    );
    event MetadataUpdated(uint256 indexed tokenId);

    /**
     * Errors
     */
    error RandomizedNFT_InsufficientMintQuantity();
    error RandomizedNFT_ExceedsMaxSupply();
    error RandomizedNFT_ExceedsMaxPerWallet();
    error RandomizedNFT_ExceedsBatchLimit();
    error RandomizedNFT_MaxPerWalletExceedsMaxSupply();
    error RandomizedNFT_MaxPerWalletSmallerThanBatchLimit();
    error RandomizedNFT_BatchLimitExceedsMaxPerWallet();
    error RandomizedNFT_BatchLimitTooHigh();
    error RandomizedNFT_NonexistentToken(uint256);
    error RandomizedNFT_TokenUriError();
    error RandomizedNFT_NoBaseURI();

    /// @notice Constructor
    /// @param args constructor arguments:
    ///                     name: collection name
    ///                     symbol: nft symbol
    ///                     baseUri: base uri of collection
    ///                     maxSupply: maximum nfts mintable
    ///                     maxPerWallet: how many nfts can be minted per wallet
    ///                     batchLimit: how many nfts can be minted at once
    /// @dev inherits from ERC721A
    constructor(
        ConstructorArguments memory args
    ) ERC721A(args.name, args.symbol) Ownable(msg.sender) {
        if (bytes(args.baseURI).length == 0) revert RandomizedNFT_NoBaseURI();

        i_maxSupply = args.maxSupply;
        s_maxPerWallet = args.maxPerWallet;
        s_batchLimit = args.batchLimit;
        s_ids = new uint256[](args.maxSupply);

        _setBaseURI(args.baseURI);
        _setContractURI(args.contractURI);

        _setDefaultRoyalty(msg.sender, args.royaltyNumerator);
    }

    /// @notice Mints NFT for a eth and a token fee
    /// @param to address NFTs are minted to
    /// @param quantity number of NFTs to mint
    function mint(address to, uint256 quantity) external onlyOwner {
        if (quantity == 0) revert RandomizedNFT_InsufficientMintQuantity();
        if (balanceOf(to) + quantity > s_maxPerWallet) {
            revert RandomizedNFT_ExceedsMaxPerWallet();
        }
        if (quantity > s_batchLimit) revert RandomizedNFT_ExceedsBatchLimit();
        if (_totalSupply() + quantity > i_maxSupply)
            revert RandomizedNFT_ExceedsMaxSupply();

        uint256 tokenId = _nextTokenId();
        for (uint256 i = 0; i < quantity; i++) {
            _setTokenURI(tokenId);
            unchecked {
                tokenId++;
            }
        }
        _mint(to, quantity);
    }

    /// @notice Sets base Uri
    /// @param _contractURI contract uri
    function setContractURI(string memory _contractURI) external onlyOwner {
        _setContractURI(_contractURI);
    }

    /// @notice Sets base Uri
    /// @param baseURI base uri
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /// @notice Sets royalty
    /// @param feeAddress address receiving royalties
    /// @param royaltyNumerator numerator to calculate fees (denominator is 10000)
    function setRoyalty(
        address feeAddress,
        uint96 royaltyNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(feeAddress, royaltyNumerator);
        emit RoyaltyUpdated(feeAddress, royaltyNumerator);
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

    /**
     * Getter Functions
     */

    /// @notice Gets maximum supply
    function getMaxSupply() external view returns (uint256) {
        return i_maxSupply;
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
    function getBaseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * Public Functions
     */

    /// @notice retrieves contractURI
    function contractURI() public view returns (string memory) {
        return s_contractURI;
    }

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
    ) public view override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
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

    /// @notice Retrieves base uri
    function _baseURI() internal view override returns (string memory) {
        return s_baseTokenURI;
    }

    /// @notice Sets base uri
    /// @param _contractURI contract uri for contract metadata
    function _setContractURI(string memory _contractURI) private {
        s_contractURI = _contractURI;
        emit ContractURIUpdated(_contractURI);
    }

    /// @notice Sets base uri
    /// @param baseURI base uri for NFT metadata
    function _setBaseURI(string memory baseURI) private {
        s_baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    /// @notice returns total supply
    function _totalSupply() private view returns (uint256) {
        return _nextTokenId();
    }

    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721URIStorage
    function _setTokenURI(uint256 tokenId) private {
        s_tokenURIs[tokenId] = _randomTokenURI();
        emit MetadataUpdated(tokenId);
    }

    /// @notice generates a random tokenURI
    function _randomTokenURI() private returns (uint256 randomTokenURI) {
        uint256 numAvailableURIs = s_ids.length;
        uint256 randIdx = block.prevrandao % numAvailableURIs;

        // get new and nonexisting random id
        randomTokenURI = (s_ids[randIdx] != 0) ? s_ids[randIdx] : randIdx;

        // update helper array
        s_ids[randIdx] = (s_ids[numAvailableURIs - 1] == 0)
            ? numAvailableURIs - 1
            : s_ids[numAvailableURIs - 1];
        s_ids.pop();
    }
}
