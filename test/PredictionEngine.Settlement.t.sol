// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./PredictionEngineBase.t.sol";
import {PredictionType, BountyState} from "../src/libraries/PsychohistoryTypes.sol";
import {STAKE_FEE, BPS} from "../src/libraries/Constants.sol";
import {PredictionEngine} from "../src/core/PredictionEngine.sol";

contract PredictionEngineSettlementTest is PredictionEngineBaseTest {
    function test_SettleCategorical_3Options_6Predictors() public {
        uint256 bountyId = _createCategoricalBounty(3);
        
        address[] memory predictors = new address[](6);
        for (uint256 i = 0; i < 6; i++) {
            predictors[i] = address(uint160(10 + i));
            vm.startPrank(predictors[i]);
            usdc.mint(predictors[i], STAKE_FEE);
            usdc.approve(address(engine), STAKE_FEE);
            
            uint256[] memory conf = new uint256[](3);
            if (i < 2) {
                conf[0] = 6000; conf[1] = 2000; conf[2] = 2000;
                engine.submitPrediction(bountyId, 0, conf, 0, 0);
            } else if (i < 4) {
                conf[0] = 2000; conf[1] = 6000; conf[2] = 2000;
                engine.submitPrediction(bountyId, 1, conf, 0, 0);
            } else {
                conf[0] = 2000; conf[1] = 2000; conf[2] = 6000;
                engine.submitPrediction(bountyId, 2, conf, 0, 0);
            }
            vm.stopPrank();
        }
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        engine.resolve(bountyId, 1, 0, 0);
        vm.stopPrank();
        
        engine.settle(bountyId, 0, 6);
        
        // Outcome = 1. Predictors 2 and 3 should win. 4 slashed.
        (, , , , uint256 winnersCount, uint256 slashedCount, , bool fullySettled, , , ) = engine.settlements(bountyId);
        assertTrue(fullySettled);
        assertEq(winnersCount, 2);
        assertEq(slashedCount, 4);
        
        // Slashed stakes go to Treasury
        assertEq(usdc.balanceOf(address(treasury)), 4 * STAKE_FEE);
        
        // Ensure engine has enough USDC for payouts
        vm.startPrank(admin);
        usdc.mint(address(engine), 100e6);
        vm.stopPrank();
        
        // Check claims
        vm.startPrank(predictors[2]);
        uint256 balBefore = usdc.balanceOf(predictors[2]);
        engine.claim(bountyId);
        uint256 balAfter = usdc.balanceOf(predictors[2]);
        // Refund (10) + half of bounty (50) = 60 USDC
        assertEq(balAfter - balBefore, 60e6);
        vm.stopPrank();
    }
    
    function test_TotalWipeout_Categorical() public {
        uint256 bountyId = _createCategoricalBounty(3);
        
        address[] memory predictors = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            predictors[i] = address(uint160(10 + i));
            vm.startPrank(predictors[i]);
            usdc.mint(predictors[i], STAKE_FEE);
            usdc.approve(address(engine), STAKE_FEE);
            
            uint256[] memory conf = new uint256[](3);
            conf[0] = 8000; conf[1] = 1000; conf[2] = 1000;
            engine.submitPrediction(bountyId, 0, conf, 0, 0);
            vm.stopPrank();
        }
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        engine.resolve(bountyId, 1, 0, 0); // 1 wins, all guessed 0
        vm.stopPrank();
        
        engine.settle(bountyId, 0, 5);
        
        (, , , , uint256 winnersCount, uint256 slashedCount, , , bool isTotalWipeout, , ) = engine.settlements(bountyId);
        assertEq(winnersCount, 0);
        assertEq(slashedCount, 5);
        assertTrue(isTotalWipeout);
        
        // Sponsor claims refund
        vm.startPrank(sponsor);
        uint256 balBefore = usdc.balanceOf(sponsor);
        manager.claimRefund(bountyId);
        uint256 balAfter = usdc.balanceOf(sponsor);
        assertEq(balAfter - balBefore, 100e6);
        vm.stopPrank();
    }
    
    function test_SettleNumerical_10Predictors_Pagination() public {
        uint256 bountyId = _createNumericalBounty();
        
        address[] memory predictors = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            predictors[i] = address(uint160(10 + i));
            vm.startPrank(predictors[i]);
            usdc.mint(predictors[i], STAKE_FEE);
            usdc.approve(address(engine), STAKE_FEE);
            uint256[] memory conf = new uint256[](0);
            engine.submitPrediction(bountyId, 0, conf, (i + 1) * 10, 0); // 10, 20, ... 100
            vm.stopPrank();
        }
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        // Target: 55. median = 55. Errors: 45, 35, 25, 15, 5, 5, 15, 25, 35, 45.
        // Wait, median error is 25.
        // Errors <= 25: 50, 60 (err 5), 40, 70 (err 15), 30, 80 (err 25).
        // 30, 40, 50, 60, 70, 80 all have err <= 25. That's 6 elements.
        // But target winners is ceil(10/2) = 5.
        // Let's resolve with 55 and medianError 25.
        vm.startPrank(oracle);
        engine.resolve(bountyId, 55, 0, 25e18); // wad-scaled error: 25 * 1e18
        vm.stopPrank();
        
        // Pagination
        engine.settle(bountyId, 0, 5);
        engine.settle(bountyId, 5, 10);
        
        (, , , , uint256 winnersCount, uint256 slashedCount, , bool fullySettled, , , ) = engine.settlements(bountyId);
        assertTrue(fullySettled);
        assertEq(winnersCount, 5);
        assertEq(slashedCount, 5);
    }
    
    function test_VePSYHBoost() public {
        uint256 bountyId = _createCategoricalBounty(3);
        
        address[] memory predictors = new address[](2);
        for (uint256 i = 0; i < 2; i++) {
            predictors[i] = address(uint160(10 + i));
            vm.startPrank(predictors[i]);
            usdc.mint(predictors[i], STAKE_FEE);
            usdc.approve(address(engine), STAKE_FEE);
            
            uint256[] memory conf = new uint256[](3);
            conf[0] = 6000; conf[1] = 2000; conf[2] = 2000;
            engine.submitPrediction(bountyId, 0, conf, 0, 0);
            
            if (i == 1) {
                psyh.mint(predictors[i], 1000e18);
                psyh.approve(address(vePSYH), 1000e18);
                vePSYH.lock(1000e18, 52 weeks);
                engine.delegateVePSYH(bountyId, 100e18);
            }
            vm.stopPrank();
        }
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        engine.resolve(bountyId, 0, 0, 0);
        vm.stopPrank();
        
        engine.settle(bountyId, 0, 2);
        
        // Ensure engine has enough USDC for payouts (since BountyManager in this mock doesn't transfer prizes to engine)
        vm.startPrank(admin);
        usdc.mint(address(engine), 100e6);
        vm.stopPrank();
        
        vm.startPrank(predictors[0]);
        uint256 b0 = usdc.balanceOf(predictors[0]);
        engine.claim(bountyId);
        uint256 a0 = usdc.balanceOf(predictors[0]);
        vm.stopPrank();
        
        vm.startPrank(predictors[1]);
        uint256 b1 = usdc.balanceOf(predictors[1]);
        engine.claim(bountyId);
        uint256 a1 = usdc.balanceOf(predictors[1]);
        vm.stopPrank();
        
        // predictor 1 has 3x boost, so payout is 3x of predictor 0
        // Total bounty = 100. P0 gets 25, P1 gets 75.
        assertEq(a0 - b0, 25e6 + 10e6);
        assertEq(a1 - b1, 75e6 + 10e6);
    }

    function test_InvalidatedBounty_AllStakesRefunded() public {
        uint256 bountyId = _createCategoricalBounty(3);
        
        address[] memory predictors = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            predictors[i] = address(uint160(10 + i));
            vm.startPrank(predictors[i]);
            usdc.mint(predictors[i], STAKE_FEE);
            usdc.approve(address(engine), STAKE_FEE);
            
            uint256[] memory conf = new uint256[](3);
            conf[0] = 6000; conf[1] = 2000; conf[2] = 2000;
            engine.submitPrediction(bountyId, 0, conf, 0, 0);
            vm.stopPrank();
        }
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        engine.resolveAsInvalid(bountyId);
        vm.stopPrank();
        
        engine.settle(bountyId, 0, 5);
        
        (, , , , uint256 winnersCount, uint256 slashedCount, , bool fullySettled, , bool sponsorRefundClaimed, bool isInvalidated) = engine.settlements(bountyId);
        assertTrue(fullySettled);
        assertEq(winnersCount, 0);
        assertEq(slashedCount, 0);
        assertTrue(isInvalidated);
        
        // Treasury receives 0
        assertEq(usdc.balanceOf(address(treasury)), 0);
        
        // All 5 call claim() and get 10 USDC back
        for (uint256 i = 0; i < 5; i++) {
            vm.startPrank(predictors[i]);
            uint256 balBefore = usdc.balanceOf(predictors[i]);
            engine.claim(bountyId);
            uint256 balAfter = usdc.balanceOf(predictors[i]);
            assertEq(balAfter - balBefore, STAKE_FEE);
            vm.stopPrank();
        }
        
        // Sponsor calls claimRefund()
        vm.startPrank(sponsor);
        uint256 sponsorBalBefore = usdc.balanceOf(sponsor);
        manager.claimRefund(bountyId);
        uint256 sponsorBalAfter = usdc.balanceOf(sponsor);
        assertEq(sponsorBalAfter - sponsorBalBefore, 100e6);
        vm.stopPrank();
    }

    function test_InvalidatedBounty_vePSYHReleased() public {
        uint256 bountyId = _createCategoricalBounty(3);
        address predictor = address(0x100);
        
        vm.startPrank(predictor);
        usdc.mint(predictor, STAKE_FEE);
        usdc.approve(address(engine), STAKE_FEE);
        
        uint256[] memory conf = new uint256[](3);
        conf[0] = 6000; conf[1] = 2000; conf[2] = 2000;
        engine.submitPrediction(bountyId, 0, conf, 0, 0);
        
        psyh.mint(predictor, 1000e18);
        psyh.approve(address(vePSYH), 1000e18);
        vePSYH.lock(1000e18, 52 weeks);
        engine.delegateVePSYH(bountyId, 100e18);
        vm.stopPrank();
        
        uint256 delegatedBefore = vePSYH.getVeLock(predictor).delegatedTotal;
        assertEq(delegatedBefore, 100e18);
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        engine.resolveAsInvalid(bountyId);
        vm.stopPrank();
        
        engine.settle(bountyId, 0, 1);
        
        uint256 delegatedAfter = vePSYH.getVeLock(predictor).delegatedTotal;
        assertEq(delegatedAfter, 0);
    }

    function test_ResolveAsInvalid_Reverts() public {
        uint256 bountyId = _createCategoricalBounty(3);
        
        // Non-Closed bounty revert
        vm.startPrank(oracle);
        vm.expectRevert(PredictionEngine.BountyNotClosed.selector);
        engine.resolveAsInvalid(bountyId);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        // Non-oracle revert
        vm.startPrank(address(0x999));
        // AccessControlUpgradeable custom error or generic revert message
        vm.expectRevert();
        engine.resolveAsInvalid(bountyId);
        vm.stopPrank();
        
        // Already resolved revert (since state is Invalidated, it reverts with BountyNotClosed)
        vm.startPrank(oracle);
        engine.resolveAsInvalid(bountyId);
        
        vm.expectRevert(PredictionEngine.BountyNotClosed.selector);
        engine.resolve(bountyId, 0, 0, 0);
        vm.stopPrank();
    }
}
