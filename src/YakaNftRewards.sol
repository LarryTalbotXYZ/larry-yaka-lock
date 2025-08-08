// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title YakaNftRewards
 * @notice Pro-rata rewards distributor for a fixed-supply 10,000-share ERC721 collection.
 *         Each NFT represents exactly 1 share out of 10,000. Any ERC20 rewards deposited
 *         are claimable by current NFT holders at any time. Ownership is checked against
 *         the configured NFT contract. The NFT contract address can be set/changed later.
 *
 *         Distribution uses a cumulative index per token (ERC20) with 1e18 precision:
 *         - accRewardPerShare1e18[token] grows when rewards are deposited
 *         - rewardPerSharePaid1e18[token][tokenId] tracks each tokenId's last index
 *         - Claimable = (acc - paid) / 1e18 for 1 share per NFT
 */
contract YakaNftRewards is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // The NFT collection whose token holders are entitled to claim rewards
    IERC721 public nft;

    // Total shares are fixed to 10,000 (1 per NFT)
    uint256 public constant TOTAL_SHARES = 10_000;

    // token => accumulated rewards per share, scaled by 1e18
    mapping(address => uint256) public accRewardPerShare1e18;

    // token => last tracked on-chain balance, used by notify() for push deposits
    mapping(address => uint256) public trackedTokenBalance;

    // token => tokenId => index paid
    mapping(address => mapping(uint256 => uint256)) public rewardPerSharePaid1e18;

    event SetNFT(address indexed oldNft, address indexed newNft);
    event RewardNotified(address indexed token, uint256 amount, address indexed from);
    event Claimed(address indexed token, uint256 indexed tokenId, address indexed to, uint256 amount);

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Set or update the NFT contract whose holders can claim rewards.
     *         Can be changed later if needed (migration/upgrade path).
     */
    function setNFT(address newNft) external onlyOwner {
        require(newNft != address(0), "addr0");
        address old = address(nft);
        nft = IERC721(newNft);
        emit SetNFT(old, newNft);
    }

    /**
     * @notice Pull-based deposit. Transfers `amount` of `token` from the caller
     *         and accounts it for pro-rata distribution to all 10,000 shares.
     *         Caller must approve this contract beforehand.
     */
    function depositRewardToken(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "amount=0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _notify(token, amount);
        trackedTokenBalance[token] += amount;
        emit RewardNotified(token, amount, msg.sender);
    }

    /**
     * @notice Push-based notify. If rewards of `token` are sent directly to this contract
     *         via a plain transfer, anyone can call this to account the delta as new rewards.
     */
    function notify(address token) external nonReentrant {
        uint256 current = IERC20(token).balanceOf(address(this));
        uint256 prev = trackedTokenBalance[token];
        require(current > prev, "no-delta");
        uint256 delta = current - prev;
        _notify(token, delta);
        trackedTokenBalance[token] = current;
        emit RewardNotified(token, delta, msg.sender);
    }

    /**
     * @notice Claim `token` rewards for `tokenId` to the caller (must be current owner).
     */
    function claim(address token, uint256 tokenId) external nonReentrant returns (uint256 amount) {
        require(nft.ownerOf(tokenId) == msg.sender, "!owner");
        amount = _claimTo(token, tokenId, msg.sender);
    }

    /**
     * @notice Claim `token` rewards for multiple `tokenIds` owned by the caller.
     */
    function claimMany(address token, uint256[] calldata tokenIds) external nonReentrant returns (uint256 total) {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "!owner");
            total += _claimTo(token, tokenId, msg.sender);
        }
    }

    /**
     * @notice Anyone can trigger a claim for `tokenId`; rewards are sent to the current owner.
     *         Useful for automation/bots without taking custody.
     */
    function claimFor(address token, uint256 tokenId) external nonReentrant returns (uint256 amount) {
        address owner = nft.ownerOf(tokenId);
        amount = _claimTo(token, tokenId, owner);
    }

    /**
     * @notice Anyone can trigger claims for multiple `tokenIds`; rewards go to each current owner.
     */
    function claimManyFor(address token, uint256[] calldata tokenIds) external nonReentrant returns (uint256 total) {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            address owner = nft.ownerOf(tokenId);
            total += _claimTo(token, tokenId, owner);
        }
    }

    /**
     * @notice View function: claimable `token` amount for `tokenId` at the current state.
     */
    function claimable(address token, uint256 tokenId) external view returns (uint256) {
        uint256 acc = accRewardPerShare1e18[token];
        uint256 paid = rewardPerSharePaid1e18[token][tokenId];
        if (acc <= paid) return 0;
        return (acc - paid) / 1e18;
    }

    /**
     * @notice Internal: update accounting and transfer out reward to `to`.
     */
    function _claimTo(address token, uint256 tokenId, address to) internal returns (uint256 amount) {
        uint256 acc = accRewardPerShare1e18[token];
        uint256 paid = rewardPerSharePaid1e18[token][tokenId];
        if (acc > paid) {
            uint256 delta = acc - paid;
            amount = delta / 1e18;
            rewardPerSharePaid1e18[token][tokenId] = acc;
            if (amount > 0) {
                IERC20(token).safeTransfer(to, amount);
                // Keep tracked balance consistent for push notifier
                uint256 bal = IERC20(token).balanceOf(address(this));
                trackedTokenBalance[token] = bal;
                emit Claimed(token, tokenId, to, amount);
            }
        }
    }

    /**
     * @notice Internal: updates the cumulative index for `token` using an incoming `amount`.
     */
    function _notify(address token, uint256 amount) internal {
        // Distribute equally across the fixed 10,000 shares (1e18 precision)
        uint256 addPerShare = (amount * 1e18) / TOTAL_SHARES;
        accRewardPerShare1e18[token] += addPerShare;
    }
}


