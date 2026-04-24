// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

enum BountyState { Active, Closed, Resolved, Settled, Cancelled, Invalidated }
enum PredictionType { Categorical, Numerical }

struct BountyPrize {
    address token;
    uint256 totalDeposited;
    uint256 distributed;
    uint256 refunded;
}

struct Bounty {
    uint256 bountyId;
    address creator;
    string metadataURI;
    PredictionType predictionType;
    uint8 optionsCount;
    uint64 startTimestamp;
    uint64 closeTimestamp;
    uint64 resolutionDeadline;
    BountyState state;
    uint256 resolvedValue;
    uint8 resolvedDecimals;
    uint256 totalPredictors;
    uint256 winnersCount;
    BountyPrize[] prizes;
}

struct Prediction {
    address predictor;
    uint256 bountyId;
    uint256 selectedOption;          // Categorical
    uint256 predictedValue;
    uint8 predictedDecimals;  // Numerical
    uint256 vePSYHDelegated;
    uint256 stakeAmount;
    bool slashed;
    bool refunded;
    uint256 bountyPayout;
}
// confidenceBpsArray stored in separate mapping for gas efficiency

struct VeLock {
    uint256 psyhAmount;
    uint256 vePSYHMinted;
    uint64 lockStart;
    uint64 lockEnd;
    uint256 delegatedTotal;
}

struct SettlementState {
    bool resolved;
    uint256 resolvedValue;
    uint8 resolvedDecimals;
    uint256 medianError;
    uint256 winnersCount;
    uint256 slashedCount;
    uint256 settledUpTo;
    bool fullySettled;
    bool isTotalWipeout;
    bool sponsorRefundClaimed;
    bool isInvalidated;
}
