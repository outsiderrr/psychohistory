// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {WAD, MIN_BRIER, MAX_BOOST_DELTA} from "./Constants.sol";

library BrierMath {
    /// @dev BS = Σ (f_j - o_j)^2 for j in [0, N)
    ///      o_j = WAD if j == resolvedOptionIndex, else 0
    /// @param confidenceWadArray WAD-scaled probabilities, length == N
    /// @param resolvedOptionIndex winning option (0-based)
    /// @return brierScore WAD-scaled, range [0, 2*WAD]
    function computeCategoricalBrierScore(uint256[] memory confidenceWadArray, uint256 resolvedOptionIndex)
        internal
        pure
        returns (uint256 brierScore)
    {
        uint256 n = confidenceWadArray.length;
        for (uint256 j = 0; j < n; j++) {
            uint256 f_j = confidenceWadArray[j];
            uint256 o_j = (j == resolvedOptionIndex) ? WAD : 0;
            uint256 diff = f_j > o_j ? f_j - o_j : o_j - f_j;
            brierScore += (diff * diff) / WAD;
        }
    }

    /// @dev weight = WAD^2 / max(brierScore, MIN_BRIER)
    function computeInverseWeight(uint256 brierScore) internal pure returns (uint256 weight) {
        uint256 clampedScore = brierScore > MIN_BRIER ? brierScore : MIN_BRIER;
        weight = (WAD * WAD) / clampedScore;
    }

    /// @dev |predictedWad - actualWad|
    function computeAbsoluteError(uint256 predictedWad, uint256 actualWad) internal pure returns (uint256 error) {
        error = predictedWad > actualWad ? predictedWad - actualWad : actualWad - predictedWad;
    }

    /// @dev payout = (boostedWeight * bountyAmount) / totalBoostedWeight
    function computePayout(uint256 boostedWeight, uint256 totalBoostedWeight, uint256 bountyAmount)
        internal
        pure
        returns (uint256 payout)
    {
        if (totalBoostedWeight == 0) return 0;
        return Math.mulDiv(boostedWeight, bountyAmount, totalBoostedWeight);
    }

    /// @dev boost = WAD + min((vePSYHDelegated * MAX_BOOST_DELTA) / boostDenominator, MAX_BOOST_DELTA)
    function computeBoost(uint256 vePSYHDelegated, uint256 boostDenominator) internal pure returns (uint256 boost) {
        if (boostDenominator == 0) return WAD;
        uint256 boostDelta = Math.mulDiv(vePSYHDelegated, MAX_BOOST_DELTA, boostDenominator);
        if (boostDelta > MAX_BOOST_DELTA) {
            boostDelta = MAX_BOOST_DELTA;
        }
        boost = WAD + boostDelta;
    }
}
