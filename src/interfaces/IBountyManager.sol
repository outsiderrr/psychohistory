// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {PredictionType, BountyState, BountyPrize, Bounty} from "../libraries/PsychohistoryTypes.sol";

interface IBountyManager {
    event BountyCreated(
        uint256 indexed bountyId,
        address indexed creator,
        PredictionType predictionType,
        uint8 optionsCount
    );
    event BountyFunded(uint256 indexed bountyId, address indexed token, uint256 amount);
    event BountyStateChanged(uint256 indexed bountyId, BountyState newState);
    event SponsorRefundClaimed(uint256 indexed bountyId, address indexed sponsor, address token, uint256 amount);

    function createBounty(
        PredictionType predictionType,
        uint8 optionsCount,
        string calldata metadataURI,
        uint64 closeTimestamp,
        uint64 resolutionDeadline,
        address prizeToken,
        uint256 prizeAmount
    ) external returns (uint256 bountyId);

    function fundBounty(uint256 bountyId, address token, uint256 amount) external;

    function cancelBounty(uint256 bountyId) external;

    function claimRefund(uint256 bountyId) external;

    function markTotalWipeout(uint256 bountyId) external;

    function updateBountyState(uint256 bountyId, BountyState newState) external;

    function transferPrizesToEngine(uint256 bountyId) external;

    function getBounty(uint256 bountyId) external view returns (Bounty memory);

    function getBountyPrizes(uint256 bountyId) external view returns (BountyPrize[] memory);
}
