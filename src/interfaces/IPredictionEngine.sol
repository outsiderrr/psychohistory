// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Prediction} from "../libraries/PsychohistoryTypes.sol";

interface IPredictionEngine {
    event PredictionSubmitted(
        uint256 indexed bountyId,
        address indexed predictor,
        uint256 selectedOption,
        uint256 predictedValue
    );
    event PredictionResolved(
        uint256 indexed bountyId,
        uint256 resolvedValue,
        uint8 resolvedDecimals,
        uint256 medianError
    );
    event TotalWipeout(uint256 indexed bountyId);
    event StakeSlashed(uint256 indexed bountyId, address indexed predictor, uint256 amount);
    event StakeRefunded(uint256 indexed bountyId, address indexed predictor, uint256 amount);
    event BountyDistributed(uint256 indexed bountyId, address indexed predictor, uint256 amount);
    event BountyInvalidated(uint256 indexed bountyId);

    function submitPrediction(
        uint256 bountyId,
        uint256 selectedOption,
        uint256[] calldata confidenceBpsArray,
        uint256 predictedValue,
        uint8 predictedDecimals
    ) external;

    function delegateVePSYH(uint256 bountyId, uint256 vePSYHAmount) external;

    function resolve(uint256 bountyId, uint256 resolvedValue, uint8 resolvedDecimals, uint256 medianError) external;

    function resolveAsInvalid(uint256 bountyId) external;

    function settle(uint256 bountyId, uint256 startIndex, uint256 endIndex) external;

    function claim(uint256 bountyId) external;

    function getPrediction(uint256 bountyId, address predictor) external view returns (Prediction memory);

    function getPredictorCount(uint256 bountyId) external view returns (uint256);
}
