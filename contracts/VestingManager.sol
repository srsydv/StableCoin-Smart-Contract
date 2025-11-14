// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract VestingManager is Ownable {
    struct Pool {
        uint40 tgeTimestamp;
        uint40 cliffSeconds;
        uint40 vestingSeconds;
        uint16 tgePercentBps;
        uint40 monthlySliceSeconds;
        bytes32 merkleRoot;
        uint256 totalAllocation;
        uint256 totalClaimed;
        bool finalized;
        uint40 vestingEndTimestamp;
        bool burnPerformed;
    }

    IERC20 public immutable token;
    mapping(uint256 => Pool) public pools;
    mapping(uint256 => mapping(address => uint256)) public claimed;

    uint256 public constant BPS_DENOM = 10_000;
    uint256 public constant DAYS_365 = 365 days;

    event PoolConfigured(uint256 indexed poolId, bytes32 merkleRoot, uint256 totalAllocation);
    event PoolFinalized(uint256 indexed poolId);
    event Deposited(uint256 indexed poolId, uint256 amount);
    event Claimed(uint256 indexed poolId, address indexed account, uint256 amount);
    event UnclaimedBurned(uint256 indexed poolId, uint256 amount);

    constructor(address tokenAddress) Ownable(msg.sender) {
        require(tokenAddress != address(0), "token=0");
        token = IERC20(tokenAddress);
    }

    function configurePool(
        uint256 poolId,
        uint40 tgeTimestamp,
        uint40 cliffSeconds,
        uint40 vestingSeconds,
        uint16 tgePercentBps,
        uint40 monthlySliceSeconds,
        bytes32 merkleRoot,
        uint256 totalAllocation
    ) external onlyOwner {
        Pool storage p = pools[poolId];
        require(!p.finalized, "pool finalized");
        p.tgeTimestamp = tgeTimestamp;
        p.cliffSeconds = cliffSeconds;
        p.vestingSeconds = vestingSeconds;
        p.tgePercentBps = tgePercentBps;
        p.monthlySliceSeconds = monthlySliceSeconds;
        p.merkleRoot = merkleRoot;
        p.totalAllocation = totalAllocation;
        p.vestingEndTimestamp = tgeTimestamp + vestingSeconds;
        emit PoolConfigured(poolId, merkleRoot, totalAllocation);
    }

     function depositForPool(uint256 poolId, uint256 amount) external onlyOwner {
        require(token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        emit Deposited(poolId, amount);
    }

    function finalizePool(uint256 poolId) external onlyOwner {
        Pool storage p = pools[poolId];
        require(p.merkleRoot != bytes32(0), "not set");
        p.finalized = true;
        emit PoolFinalized(poolId);
    }

   


}