// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVoter {
    function vote(uint tokenId, address[] calldata poolVote, uint256[] calldata weights) external;
    function reset(uint tokenId) external;
    function poke(uint tokenId) external;
    function distribute(address gauge) external;
    function distributeToBribes(address[] memory gauges) external;
    function distributeToGauges(address[] memory gauges) external;
    
    function claimBribes(address[] memory bribes, address[][] memory tokens, uint tokenId) external;
    function claimFees(address[] memory fees, address[][] memory tokens, uint tokenId) external;
    function claimRewards(address[] memory gauges, address[][] memory tokens) external;
    
    function length() external view returns (uint);
    function pools(uint index) external view returns (address);
    function gauges(address pool) external view returns (address);
    function poolForGauge(address gauge) external view returns (address);
    function external_bribes(address gauge) external view returns (address);
    function internal_bribes(address gauge) external view returns (address);
    function weights(address pool) external view returns (uint);
    function votes(uint tokenId, address pool) external view returns (uint);
    function poolVote(uint tokenId, uint index) external view returns (address);
    function poolVoteLength(uint tokenId) external view returns (uint);
    function totalWeight() external view returns (uint);
    function usedWeights(uint tokenId) external view returns (uint);
    function lastVoted(uint tokenId) external view returns (uint);
}