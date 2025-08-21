// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./veYakainterface/IVotingEscrow.sol";
import "./veYakainterface/IRewardsDistributor.sol";
import "./LiquidYakaToken.sol";

interface IVoter {
    function vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights) external;
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external;
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint256 _tokenId) external;
    function reset(uint256 _tokenId) external;
}

contract LiquidYakaVault is ReentrancyGuard, Ownable {
    IERC20 public immutable yaka;
    IVotingEscrow public immutable votingEscrow;
    IVoter public immutable voter;
    IRewardsDistributor public immutable rewardDistributor;
    LiquidYakaToken public immutable liquidToken;
    
    uint256 public mainNFT;
    
    uint256 public constant LOCK_DURATION = 2 * 365 * 24 * 60 * 60; // 2 years
    uint256 public minimumWithdrawal = 1e18; // Minimum 1 YAKA withdrawal (18 decimals)
    
    uint256 public constant DEPOSIT_FEE = 500; // 5% = 500 basis points
    uint256 public constant WITHDRAWAL_FEE = 500; // 5% = 500 basis points
    uint256 public constant FEE_DENOMINATOR = 10000; // 100% = 10000 basis points
    
    address public feeRecipient;
    
    address[] public lastVotePools;
    uint256[] public lastVoteWeights;
    
    bool public depositsEnabled = true;
    bool public withdrawalsEnabled = true;
    
    event Deposit(address indexed user, uint256 yakaAmount, uint256 liquidTokens);
    event DepositNFT(address indexed user, uint256 indexed tokenId, uint256 liquidTokens);
    event Withdraw(address indexed user, uint256 liquidTokens, uint256 yakaAmount);
    event WithdrawNFT(address indexed user, uint256 liquidTokens, uint256 indexed nftId, uint256 yakaAmount);
    event RewardsClaimed(uint256 nftCount);
    event VoteExecuted(address[] pools, uint256[] weights);
    event VaultMigration(address indexed newVault, uint256[] tokenIds);
    event DepositsToggled(bool enabled);
    event WithdrawalsToggled(bool enabled);
    event NFTReset(uint256 indexed tokenId);
    event RewardTokensWithdrawn(address indexed token, uint256 amount);
    event ManualCompound(uint256 yakaAmount);
    event NFTSplit(uint256 indexed originalNFT, uint256[] newNFTs);
    event MinimumWithdrawalUpdated(uint256 oldMinimum, uint256 newMinimum);
    event DepositFeeCollected(address indexed recipient, uint256 feeAmount);
    event WithdrawalFeeCollected(address indexed recipient, uint256 feeAmount);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    constructor(
        address _yaka,
        address _votingEscrow,
        address _voter,
        address _rewardDistributor,
        address _liquidToken,
        address _feeRecipient
    ) Ownable(msg.sender) {
        yaka = IERC20(_yaka);
        votingEscrow = IVotingEscrow(_votingEscrow);
        voter = IVoter(_voter);
        rewardDistributor = IRewardsDistributor(_rewardDistributor);
        liquidToken = LiquidYakaToken(_liquidToken);
        feeRecipient = _feeRecipient;
        
        yaka.approve(_votingEscrow, type(uint256).max);
    }

    modifier whenDepositsEnabled() {
        require(depositsEnabled, "Deposits disabled");
        _;
    }
    
    modifier whenWithdrawalsEnabled() {
        require(withdrawalsEnabled, "Withdrawals disabled");
        _;
    }

    function deposit(uint256 amount) external nonReentrant whenDepositsEnabled {
        require(amount > 0, "Amount must be > 0");
        
        yaka.transferFrom(msg.sender, address(this), amount);
        
        uint256 liquidTokensToMint;
        uint256 currentSupply = liquidToken.totalSupply();
        
        if (currentSupply == 0) {
            liquidTokensToMint = amount;
        } else {
            uint256 totalLockedValue = getTotalLockedValue();
            require(totalLockedValue > 0, "Invalid vault state");
            liquidTokensToMint = (amount * currentSupply) / totalLockedValue;
        }
        
        if (mainNFT == 0) {
            mainNFT = votingEscrow.create_lock_for(amount, LOCK_DURATION, address(this));
        } else {
            votingEscrow.deposit_for(mainNFT, amount);
            _extendLockIfNeeded(mainNFT);
        }
        
        // Calculate deposit fee in Liquid YAKA tokens
        uint256 depositFee = (liquidTokensToMint * DEPOSIT_FEE) / FEE_DENOMINATOR;
        uint256 netLiquidTokens = liquidTokensToMint - depositFee;
        
        // Mint net amount to user
        liquidToken.mint(msg.sender, netLiquidTokens);
        
        // Send fee to fee recipient
        if (depositFee > 0 && feeRecipient != address(0)) {
            liquidToken.mint(feeRecipient, depositFee);
            emit DepositFeeCollected(feeRecipient, depositFee);
        }
        
        emit Deposit(msg.sender, amount, netLiquidTokens);
    }

    function depositNFT(uint256 tokenId) external nonReentrant whenDepositsEnabled {
        require(votingEscrow.ownerOf(tokenId) == msg.sender, "Not owner of NFT");
        require(votingEscrow.balanceOfNFT(tokenId) > 0, "NFT has no balance");
        
        _resetNFTIfNeeded(tokenId);
        
        IVotingEscrow.LockedBalance memory locked = votingEscrow.locked(tokenId);
        uint256 nftValue = uint256(int256(locked.amount));
        uint256 liquidTokensToMint;
        uint256 currentSupply = liquidToken.totalSupply();
        
        if (currentSupply == 0) {
            liquidTokensToMint = nftValue;
        } else {
            uint256 totalLockedValue = getTotalLockedValue();
            liquidTokensToMint = (nftValue * currentSupply) / totalLockedValue;
        }
        
        if (mainNFT == 0) {
            votingEscrow.transferFrom(msg.sender, address(this), tokenId);
            mainNFT = tokenId;
            _extendLockIfNeeded(mainNFT); // Extend to max voting power
        } else {
            votingEscrow.transferFrom(msg.sender, address(this), tokenId);
            _resetNFTIfNeeded(mainNFT);
            votingEscrow.merge(tokenId, mainNFT);
            _extendLockIfNeeded(mainNFT); // Extend to max voting power after merge
            _reVoteAfterSplit(); // Re-apply voting allocation after merge
        }
        
        // Calculate deposit fee in Liquid YAKA tokens
        uint256 depositFee = (liquidTokensToMint * DEPOSIT_FEE) / FEE_DENOMINATOR;
        uint256 netLiquidTokens = liquidTokensToMint - depositFee;
        
        // Mint net amount to user
        liquidToken.mint(msg.sender, netLiquidTokens);
        
        // Send fee to fee recipient
        if (depositFee > 0 && feeRecipient != address(0)) {
            liquidToken.mint(feeRecipient, depositFee);
            emit DepositFeeCollected(feeRecipient, depositFee);
        }
        
        emit DepositNFT(msg.sender, tokenId, netLiquidTokens);
    }

    function withdraw(uint256 liquidAmount) external nonReentrant whenWithdrawalsEnabled {
        require(liquidAmount > 0, "Amount must be > 0");
        require(liquidToken.balanceOf(msg.sender) >= liquidAmount, "Insufficient balance");
        
        // Calculate withdrawal fee in Liquid YAKA tokens
        uint256 withdrawalFee = (liquidAmount * WITHDRAWAL_FEE) / FEE_DENOMINATOR;
        uint256 netLiquidAmount = liquidAmount - withdrawalFee;
        
        uint256 totalLockedValue = getTotalLockedValue();
        uint256 currentSupply = liquidToken.totalSupply();
        uint256 yakaToWithdraw = (netLiquidAmount * totalLockedValue) / currentSupply;
        
        require(yakaToWithdraw >= minimumWithdrawal, "Below minimum withdrawal");
        
        // Burn user's liquid tokens
        liquidToken.burnFrom(msg.sender, liquidAmount);
        
        // Send fee to fee recipient
        if (withdrawalFee > 0 && feeRecipient != address(0)) {
            liquidToken.mint(feeRecipient, withdrawalFee);
            emit WithdrawalFeeCollected(feeRecipient, withdrawalFee);
        }
        
        uint256 nftToTransfer = _splitForWithdrawal(yakaToWithdraw);
        votingEscrow.transferFrom(address(this), msg.sender, nftToTransfer);
        
        emit WithdrawNFT(msg.sender, liquidAmount, nftToTransfer, yakaToWithdraw);
    }

    function withdrawYAKA(uint256 liquidAmount) external nonReentrant whenWithdrawalsEnabled {
        require(liquidAmount > 0, "Amount must be > 0");
        require(liquidToken.balanceOf(msg.sender) >= liquidAmount, "Insufficient balance");
        require(!votingEscrow.canSplit(), "Use withdraw() when splitting enabled");
        
        // Calculate withdrawal fee in Liquid YAKA tokens
        uint256 withdrawalFee = (liquidAmount * WITHDRAWAL_FEE) / FEE_DENOMINATOR;
        uint256 netLiquidAmount = liquidAmount - withdrawalFee;
        
        uint256 totalLockedValue = getTotalLockedValue();
        uint256 currentSupply = liquidToken.totalSupply();
        uint256 yakaToWithdraw = (netLiquidAmount * totalLockedValue) / currentSupply;
        
        require(yakaToWithdraw >= minimumWithdrawal, "Below minimum withdrawal");
        
        // Burn user's liquid tokens
        liquidToken.burnFrom(msg.sender, liquidAmount);
        
        // Send fee to fee recipient
        if (withdrawalFee > 0 && feeRecipient != address(0)) {
            liquidToken.mint(feeRecipient, withdrawalFee);
            emit WithdrawalFeeCollected(feeRecipient, withdrawalFee);
        }
        
        _withdrawYakaFromNFTs(yakaToWithdraw);
        yaka.transfer(msg.sender, yakaToWithdraw);
        
        emit Withdraw(msg.sender, liquidAmount, yakaToWithdraw);
    }

    function vote(address[] calldata pools, uint256[] calldata weights) external onlyOwner {
        require(pools.length == weights.length, "Length mismatch");
        require(mainNFT != 0, "No main NFT to vote with");
        require(votingEscrow.balanceOfNFT(mainNFT) > 0, "Main NFT has no balance");
        
        _extendLockIfNeeded(mainNFT); // Extend to max voting power before voting
        voter.vote(mainNFT, pools, weights);
        
        _saveLastVote(pools, weights);
        
        emit VoteExecuted(pools, weights);
    }

    function _saveLastVote(address[] calldata pools, uint256[] calldata weights) internal {
        delete lastVotePools;
        delete lastVoteWeights;
        
        for (uint256 i = 0; i < pools.length; i++) {
            lastVotePools.push(pools[i]);
            lastVoteWeights.push(weights[i]);
        }
    }

    function _reVoteAfterSplit() internal {
        if (lastVotePools.length > 0 && mainNFT != 0) {
            voter.vote(mainNFT, lastVotePools, lastVoteWeights);
        }
    }

    function reVote() external onlyOwner {
        require(lastVotePools.length > 0, "No previous vote to restore");
        require(mainNFT != 0, "No main NFT");
        
        _extendLockIfNeeded(mainNFT); // Extend to max voting power before revoting
        voter.vote(mainNFT, lastVotePools, lastVoteWeights);
        emit VoteExecuted(lastVotePools, lastVoteWeights);
    }

    function getLastVote() external view returns (address[] memory pools, uint256[] memory weights) {
        return (lastVotePools, lastVoteWeights);
    }

    function extendMainNFTLock() external onlyOwner {
        require(mainNFT != 0, "No main NFT");
        _extendLockIfNeeded(mainNFT);
    }

    function getMainNFTLockInfo() external view returns (uint256 tokenId, uint256 lockedAmount, uint256 endTime, uint256 timeLeft, uint256 votingPower) {
        if (mainNFT == 0) return (0, 0, 0, 0, 0);
        
        tokenId = mainNFT;
        IVotingEscrow.LockedBalance memory locked = votingEscrow.locked(mainNFT);
        lockedAmount = uint256(int256(locked.amount));
        endTime = locked.end;
        timeLeft = locked.end > block.timestamp ? locked.end - block.timestamp : 0;
        votingPower = votingEscrow.balanceOfNFT(mainNFT);
    }

    function getVaultInfo() external view returns (
        uint256 totalLiquidSupply,
        uint256 totalLockedYaka,
        uint256 totalVotingPower,
        uint256 pricePerToken,
        uint256 mainNftId
    ) {
        totalLiquidSupply = liquidToken.totalSupply();
        totalLockedYaka = getTotalLockedValue();
        totalVotingPower = getTotalVotingPower();
        pricePerToken = totalLiquidSupply > 0 ? (totalLockedYaka * 1e18) / totalLiquidSupply : 1e18;
        mainNftId = mainNFT;
    }

    function claimRewards(
        address[] calldata bribes,
        address[][] calldata bribeTokens,
        address[] calldata fees,
        address[][] calldata feeTokens
    ) external onlyOwner {
        require(mainNFT != 0, "No main NFT to claim from");
        
        if (bribes.length > 0) {
            voter.claimBribes(bribes, bribeTokens, mainNFT);
        }
        
        if (fees.length > 0) {
            voter.claimFees(fees, feeTokens, mainNFT);
        }
        
        emit RewardsClaimed(1);
    }

    function claimRebase() external onlyOwner {
        require(mainNFT != 0, "No main NFT to claim from");
        
        uint256 yakaBalanceBefore = yaka.balanceOf(address(this));
        rewardDistributor.claim(mainNFT);
        uint256 yakaBalanceAfter = yaka.balanceOf(address(this));
        
        uint256 rebaseRewards = yakaBalanceAfter - yakaBalanceBefore;
        emit RewardTokensWithdrawn(address(yaka), rebaseRewards);
    }

    function claimRebaseMany(uint256[] calldata tokenIds) external onlyOwner {
        require(tokenIds.length > 0, "No token IDs provided");
        
        uint256 yakaBalanceBefore = yaka.balanceOf(address(this));
        rewardDistributor.claim_many(tokenIds);
        uint256 yakaBalanceAfter = yaka.balanceOf(address(this));
        
        uint256 rebaseRewards = yakaBalanceAfter - yakaBalanceBefore;
        emit RewardTokensWithdrawn(address(yaka), rebaseRewards);
    }

    function claimRebaseForMainNFT() external onlyOwner {
        require(mainNFT != 0, "No main NFT to claim from");
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = mainNFT;
        
        uint256 yakaBalanceBefore = yaka.balanceOf(address(this));
        rewardDistributor.claim_many(tokenIds);
        uint256 yakaBalanceAfter = yaka.balanceOf(address(this));
        
        uint256 rebaseRewards = yakaBalanceAfter - yakaBalanceBefore;
        emit RewardTokensWithdrawn(address(yaka), rebaseRewards);
    }

    function withdrawRewardTokens(address token, uint256 amount) external onlyOwner {
        require(token != address(yaka), "Cannot withdraw YAKA directly");
        require(token != address(liquidToken), "Cannot withdraw liquid tokens");
        
        IERC20(token).transfer(owner(), amount);
        emit RewardTokensWithdrawn(token, amount);
    }

    function withdrawAllRewardTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(token != address(yaka), "Cannot withdraw YAKA directly");
            require(token != address(liquidToken), "Cannot withdraw liquid tokens");
            
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).transfer(owner(), balance);
                emit RewardTokensWithdrawn(token, balance);
            }
        }
    }

    function manualCompound(uint256 yakaAmount) external onlyOwner {
        require(yakaAmount > 0, "Amount must be > 0");
        
        yaka.transferFrom(msg.sender, address(this), yakaAmount);
        _compoundRewards(yakaAmount);
        
        emit ManualCompound(yakaAmount);
    }

    function migrateToNewVault(address newVault) external onlyOwner {
        require(newVault != address(0), "Invalid vault address");
        
        depositsEnabled = false;
        withdrawalsEnabled = false;
        
        uint256[] memory tokenIds = new uint256[](mainNFT != 0 ? 1 : 0);
        if (mainNFT != 0) {
            tokenIds[0] = mainNFT;
            _resetNFTIfNeeded(mainNFT);
            votingEscrow.transferFrom(address(this), newVault, mainNFT);
            mainNFT = 0;
        }
        
        emit VaultMigration(newVault, tokenIds);
    }

    function receiveFromOldVault(uint256 tokenId) external onlyOwner {
        require(votingEscrow.ownerOf(tokenId) == address(this), "Not owner of NFT");
        require(mainNFT == 0, "Already have main NFT");
        mainNFT = tokenId;
    }

    function toggleDeposits() external onlyOwner {
        depositsEnabled = !depositsEnabled;
        emit DepositsToggled(depositsEnabled);
    }
    
    function toggleWithdrawals() external onlyOwner {
        withdrawalsEnabled = !withdrawalsEnabled;
        emit WithdrawalsToggled(withdrawalsEnabled);
    }

    function setMinimumWithdrawal(uint256 newMinimum) external onlyOwner {
        require(newMinimum > 0, "Minimum must be > 0");
        uint256 oldMinimum = minimumWithdrawal;
        minimumWithdrawal = newMinimum;
        emit MinimumWithdrawalUpdated(oldMinimum, newMinimum);
    }

    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        address oldRecipient = feeRecipient;
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(oldRecipient, newFeeRecipient);
    }

    function getFeeInfo() external view returns (uint256 depositFee, uint256 withdrawalFee, uint256 denominator, address recipient) {
        return (DEPOSIT_FEE, WITHDRAWAL_FEE, FEE_DENOMINATOR, feeRecipient);
    }

    function calculateDepositFee(uint256 liquidAmount) external pure returns (uint256 fee, uint256 netAmount) {
        fee = (liquidAmount * DEPOSIT_FEE) / FEE_DENOMINATOR;
        netAmount = liquidAmount - fee;
    }

    function calculateWithdrawalFee(uint256 liquidAmount) external pure returns (uint256 fee, uint256 netAmount) {
        fee = (liquidAmount * WITHDRAWAL_FEE) / FEE_DENOMINATOR;
        netAmount = liquidAmount - fee;
    }

    function getTotalLockedValue() public view returns (uint256) {
        if (mainNFT == 0) return 0;
        IVotingEscrow.LockedBalance memory locked = votingEscrow.locked(mainNFT);
        return uint256(int256(locked.amount));
    }

    function getPrice() external view returns (uint256) {
        uint256 supply = liquidToken.totalSupply();
        if (supply == 0) return 1e18;
        return (getTotalLockedValue() * 1e18) / supply;
    }



    function getTotalVotingPower() public view returns (uint256) {
        if (mainNFT == 0) return 0;
        return votingEscrow.balanceOfNFT(mainNFT);
    }

    function getTotalLockedAmount() external view returns (uint256) {
        return getTotalLockedValue();
    }


    function _compoundRewards(uint256 amount) internal {
        if (mainNFT != 0) {
            votingEscrow.deposit_for(mainNFT, amount);
            _extendLockIfNeeded(mainNFT);
        } else {
            mainNFT = votingEscrow.create_lock_for(amount, LOCK_DURATION, address(this));
        }
    }

    function _extendLockIfNeeded(uint256 tokenId) internal {
        IVotingEscrow.LockedBalance memory locked = votingEscrow.locked(tokenId);
        uint256 timeLeft = locked.end > block.timestamp ? locked.end - block.timestamp : 0;
        
        // Always extend to maximum 2 years for optimal voting power
        // Only skip if already at or very close to max duration (within 1 day)
        if (timeLeft < LOCK_DURATION - 1 days) {
            uint256 newEndTime = block.timestamp + LOCK_DURATION;
            
            // Make sure we don't exceed the veNFT's maximum lock duration
            // Some veNFT contracts have absolute maximum lock times
            try votingEscrow.increase_unlock_time(tokenId, newEndTime) {
                // Extension successful - now at maximum voting power
            } catch {
                // Extension failed (probably because it would exceed max lock time)
                // This is fine - the NFT will continue with its current lock duration
            }
        }
    }

    function _splitForWithdrawal(uint256 yakaAmount) internal returns (uint256) {
        require(votingEscrow.canSplit(), "Splitting disabled");
        require(yakaAmount > 0, "Amount must be > 0");
        require(mainNFT != 0, "No main NFT found");
        
        IVotingEscrow.LockedBalance memory locked = votingEscrow.locked(mainNFT);
        uint256 mainAmount = uint256(int256(locked.amount));
        require(mainAmount >= yakaAmount, "Insufficient main NFT balance");
        
        if (mainAmount == yakaAmount) {
            uint256 transferNFT = mainNFT;
            mainNFT = 0;
            return transferNFT;
        }
        
        _resetNFTIfNeeded(mainNFT);
        
        uint256 keepAmount = mainAmount - yakaAmount;
        uint256 withdrawAmount = yakaAmount;
        
        // Split function uses: _value = value * amounts[i] / totalWeight
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = keepAmount;    // Weight for keep portion
        amounts[1] = withdrawAmount; // Weight for withdraw portion
        
        uint256 originalNFT = mainNFT;
        
        // Execute the split - this destroys originalNFT and creates 2 new ones
        votingEscrow.split(amounts, mainNFT);
        
        // After split, the original NFT is destroyed and we don't own it anymore
        // We need to find which of the newly created NFTs we now own
        // The split function creates NFTs with sequential IDs, typically the next available IDs
        
        // Strategy: Search in expanding ranges to efficiently find newly created NFTs
        // Start near original NFT, then expand search if needed
        uint256 withdrawNFT = 0;
        uint256 newMainNFT = 0;
        uint256 foundCount = 0;
        
        // Search in expanding ranges: 50, 200, 1000, then full range
        uint256[] memory searchRanges = new uint256[](4);
        searchRanges[0] = 50;
        searchRanges[1] = 200;  
        searchRanges[2] = 1000;
        searchRanges[3] = 10000;
        
        for (uint256 rangeIdx = 0; rangeIdx < searchRanges.length && foundCount < 2; rangeIdx++) {
            uint256 range = searchRanges[rangeIdx];
            
            // Search forward from originalNFT
            for (uint256 i = originalNFT + 1; i <= originalNFT + range && foundCount < 2; i++) {
                try votingEscrow.ownerOf(i) returns (address owner) {
                    if (owner == address(this)) {
                        // This is one of our new NFTs
                        IVotingEscrow.LockedBalance memory nftLocked = votingEscrow.locked(i);
                        uint256 nftAmount = uint256(int256(nftLocked.amount));
                        
                        // Determine if this is the withdrawal NFT or the keep NFT
                        // Use tolerance for rounding differences
                        if (nftAmount >= withdrawAmount * 999 / 1000 && nftAmount <= withdrawAmount * 1001 / 1000) {
                            withdrawNFT = i;
                            foundCount++;
                        } else if (nftAmount >= keepAmount * 999 / 1000 && nftAmount <= keepAmount * 1001 / 1000) {
                            newMainNFT = i;
                            foundCount++;
                        }
                    }
                } catch {
                    // NFT doesn't exist or can't read it, continue
                    continue;
                }
            }
            
            // If found both, break early
            if (foundCount >= 2) break;
        }
        
        require(withdrawNFT != 0, "Could not find withdrawal NFT after split");
        require(newMainNFT != 0, "Could not find keep NFT after split");
        
        // Update our main NFT reference
        mainNFT = newMainNFT;
        _extendLockIfNeeded(mainNFT);
        _reVoteAfterSplit();
        
        // Create array for event
        uint256[] memory resultNFTs = new uint256[](2);
        resultNFTs[0] = newMainNFT;
        resultNFTs[1] = withdrawNFT;
        
        emit NFTSplit(originalNFT, resultNFTs);
        return withdrawNFT;
    }


    function _getOwnedNFTs() internal view returns (uint256[] memory) {
        // Simple approach: we only track mainNFT in this vault design
        // This is much more efficient and reliable than scanning
        if (mainNFT != 0) {
            try votingEscrow.ownerOf(mainNFT) returns (address owner) {
                if (owner == address(this)) {
                    uint256[] memory ownedNFTs = new uint256[](1);
                    ownedNFTs[0] = mainNFT;
                    return ownedNFTs;
                }
            } catch {}
        }
        
        // Return empty array if no main NFT or not owned
        return new uint256[](0);
    }
    

    function _resetNFTIfNeeded(uint256 tokenId) internal {
        if (votingEscrow.voted(tokenId) || votingEscrow.attachments(tokenId) > 0) {
            voter.reset(tokenId);
            emit NFTReset(tokenId);
        }
    }

    function resetMainNFT() external onlyOwner {
        require(mainNFT != 0, "No main NFT");
        _resetNFTIfNeeded(mainNFT);
    }

    function _withdrawYakaFromNFTs(uint256 amountNeeded) internal {
        uint256 currentBalance = yaka.balanceOf(address(this));
        if (currentBalance >= amountNeeded) return;
        
        uint256 stillNeeded = amountNeeded - currentBalance;
        
        if (mainNFT != 0) {
            IVotingEscrow.LockedBalance memory locked = votingEscrow.locked(mainNFT);
            
            if (block.timestamp >= locked.end) {
                uint256 nftBalance = uint256(int256(locked.amount));
                // Need to add withdraw function to IVotingEscrow interface
                // For now, this function will fail - withdrawYAKA should not be used until interface is updated
                revert("withdrawYAKA not supported - use withdraw() instead when splitting enabled");
            }
        }
        
        require(stillNeeded == 0, "Insufficient unlocked YAKA");
    }


    function emergencyUnlock() external onlyOwner {
        require(mainNFT != 0, "No main NFT");
        IVotingEscrow.LockedBalance memory locked = votingEscrow.locked(mainNFT);
        require(block.timestamp >= locked.end, "Still locked");
        
        votingEscrow.transferFrom(address(this), owner(), mainNFT);
        mainNFT = 0;
    }
}