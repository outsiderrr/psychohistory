// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {BrierMath} from "../src/libraries/BrierMath.sol";
import {WAD, MIN_BRIER, MAX_BOOST_DELTA, MAX_BOOST_WAD, MAX_BRIER_SCORE} from "../src/libraries/Constants.sol";

contract BrierMathTest is Test {
    using BrierMath for *;

    function setUp() public {}

    function test_CategoricalBrier_2Option_Correct() public {
        uint256[] memory probs = new uint256[](2);
        probs[0] = WAD;
        probs[1] = 0;

        uint256 bs = BrierMath.computeCategoricalBrierScore(probs, 0);
        assertEq(bs, 0, "BS should be 0 when 100% correct");
    }

    function test_CategoricalBrier_2Option_Wrong() public {
        uint256[] memory probs = new uint256[](2);
        probs[0] = 0;
        probs[1] = WAD;

        uint256 bs = BrierMath.computeCategoricalBrierScore(probs, 0);
        assertEq(bs, 2 * WAD, "BS should be 2*WAD when 100% wrong");
    }

    function test_CategoricalBrier_2Option_Partial() public {
        uint256[] memory probs = new uint256[](2);
        probs[0] = 0.7 * 1e18; // 7000 BPS
        probs[1] = 0.3 * 1e18; // 3000 BPS

        uint256 bs = BrierMath.computeCategoricalBrierScore(probs, 0);
        // (0.7 - 1)^2 + (0.3 - 0)^2 = 0.09 + 0.09 = 0.18 WAD
        assertEq(bs, 0.18 * 1e18, "BS should be 0.18 WAD");
    }

    function test_CategoricalBrier_3Option_Partial() public {
        uint256[] memory probs = new uint256[](3);
        probs[0] = 0.5 * 1e18;
        probs[1] = 0.3 * 1e18;
        probs[2] = 0.2 * 1e18;

        uint256 bs = BrierMath.computeCategoricalBrierScore(probs, 1);
        // resolved is 1
        // (0.5 - 0)^2 + (0.3 - 1)^2 + (0.2 - 0)^2
        // 0.25 + 0.49 + 0.04 = 0.78 WAD
        assertEq(bs, 0.78 * 1e18, "BS should be 0.78 WAD");
    }

    function test_CategoricalBrier_3Option_Uniform() public {
        uint256[] memory probs = new uint256[](3);
        probs[0] = 3333 * 1e14; // 0.3333
        probs[1] = 3333 * 1e14; // 0.3333
        probs[2] = 3334 * 1e14; // 0.3334

        uint256 bs = BrierMath.computeCategoricalBrierScore(probs, 0);
        // (0.3333 - 1)^2 + (0.3333 - 0)^2 + (0.3334 - 0)^2
        // 0.6667^2 + 0.3333^2 + 0.3334^2
        // 0.44448889 + 0.11108889 + 0.11115556 = 0.66673334 WAD
        assertEq(bs, 0.66673334 * 1e18, "BS should be approx 0.6667 WAD");
    }

    function test_CategoricalBrier_5Option_AllWrong() public {
        uint256[] memory probs = new uint256[](5);
        probs[0] = 0;
        probs[1] = WAD;
        probs[2] = 0;
        probs[3] = 0;
        probs[4] = 0;

        uint256 bs = BrierMath.computeCategoricalBrierScore(probs, 0);
        assertEq(bs, 2 * WAD, "BS should be 2*WAD");
    }

    function test_CategoricalBrier_5Option_AllCorrect() public {
        uint256[] memory probs = new uint256[](5);
        probs[0] = WAD;
        probs[1] = 0;
        probs[2] = 0;
        probs[3] = 0;
        probs[4] = 0;

        uint256 bs = BrierMath.computeCategoricalBrierScore(probs, 0);
        assertEq(bs, 0, "BS should be 0");
    }

    function test_InverseWeight_Clamped() public {
        uint256 weight = BrierMath.computeInverseWeight(0);
        assertEq(weight, (WAD * WAD) / MIN_BRIER, "Weight should be clamped to max possible");

        uint256 weight2 = BrierMath.computeInverseWeight(MIN_BRIER - 1);
        assertEq(weight2, (WAD * WAD) / MIN_BRIER, "Weight should be clamped to max possible");
    }

    function test_InverseWeight_Normal() public {
        uint256 weight = BrierMath.computeInverseWeight(WAD);
        assertEq(weight, WAD, "Weight should be WAD when BS is WAD");
    }

    function test_AbsoluteError_Symmetry() public {
        uint256 err1 = BrierMath.computeAbsoluteError(100, 50);
        uint256 err2 = BrierMath.computeAbsoluteError(50, 100);
        assertEq(err1, err2, "Error should be symmetric");
        assertEq(err1, 50, "Error should be 50");
    }

    function test_Payout_NoOverflow() public {
        uint256 payout = BrierMath.computePayout(WAD, 2 * WAD, 1000 * WAD);
        assertEq(payout, 500 * WAD, "Payout should be proportional");
    }

    function test_Boost_ZeroDelegation() public {
        uint256 boost = BrierMath.computeBoost(0, 1000);
        assertEq(boost, WAD, "Boost should be 1x when no delegation");
    }

    function test_Boost_MaxDelegation() public {
        uint256 boost = BrierMath.computeBoost(2000, 1000);
        assertEq(boost, MAX_BOOST_WAD, "Boost should be capped at 3x");
    }

    function test_Boost_ZeroDenominator() public {
        uint256 boost = BrierMath.computeBoost(1000, 0);
        assertEq(boost, WAD, "Boost should be 1x when denominator is 0");
    }

    function testFuzz_categoricalBrierBounded(uint256[5] memory randomProbs, uint8 resolvedIndex) public {
        vm.assume(resolvedIndex < 5);

        // Normalize probabilities to sum to WAD
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            // Bound randomProbs to prevent overflow during sum
            randomProbs[i] = randomProbs[i] % WAD;
            sum += randomProbs[i];
        }
        vm.assume(sum > 0);

        uint256[] memory probs = new uint256[](5);
        uint256 adjustedSum = 0;
        for (uint256 i = 0; i < 4; i++) {
            probs[i] = (randomProbs[i] * WAD) / sum;
            adjustedSum += probs[i];
        }
        probs[4] = WAD - adjustedSum;

        uint256 bs = BrierMath.computeCategoricalBrierScore(probs, resolvedIndex);

        assertTrue(bs <= 2 * WAD + 1, "BS should be <= 2*WAD (plus rounding diff)");
    }

    function testFuzz_payoutNoOverflow(uint256 weight, uint256 totalWeight, uint256 bounty) public {
        vm.assume(totalWeight > 0);
        vm.assume(weight <= totalWeight);

        // Should not revert
        uint256 payout = BrierMath.computePayout(weight, totalWeight, bounty);
        assertTrue(payout <= bounty, "Payout should not exceed bounty");
    }
}
