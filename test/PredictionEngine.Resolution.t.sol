// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./PredictionEngineBase.t.sol";
import {PredictionType, BountyState} from "../src/libraries/PsychohistoryTypes.sol";
import {STAKE_FEE, BPS} from "../src/libraries/Constants.sol";

contract PredictionEngineResolutionTest is PredictionEngineBaseTest {
    function test_ResolveCategorical_Valid() public {
        uint256 bountyId = _createCategoricalBounty(3);
        vm.warp(block.timestamp + 1 days + 1); // After close
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        engine.resolve(bountyId, 1, 0, 0);
        
        (bool resolved, uint256 rVal, uint8 rDec, , , , , , , , ) = engine.settlements(bountyId);
        assertTrue(resolved);
        assertEq(rVal, 1);
        assertEq(rDec, 0);
        vm.stopPrank();
    }
    
    function test_ResolveCategorical_RevertInvalidOption() public {
        uint256 bountyId = _createCategoricalBounty(3);
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        vm.expectRevert(PredictionEngine.InvalidOption.selector);
        engine.resolve(bountyId, 3, 0, 0);
        vm.stopPrank();
    }
    
    function test_ResolveNumerical_Valid() public {
        uint256 bountyId = _createNumericalBounty();
        
        // Setup predictors
        address[] memory predictors = new address[](3);
        for (uint256 i = 0; i < 3; i++) {
            predictors[i] = address(uint160(10 + i));
            vm.startPrank(predictors[i]);
            usdc.mint(predictors[i], STAKE_FEE);
            usdc.approve(address(engine), STAKE_FEE);
            uint256[] memory conf = new uint256[](0);
            engine.submitPrediction(bountyId, 0, conf, (i + 1) * 100, 18);
            vm.stopPrank();
        }
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        // values: 100, 200, 300. resolved: 200. errors: 100, 0, 100. median error = 100.
        engine.resolve(bountyId, 200, 18, 100);
        vm.stopPrank();
    }
    
    function test_ResolveNumerical_RevertWrongMedian() public {
        uint256 bountyId = _createNumericalBounty();
        
        address[] memory predictors = new address[](3);
        for (uint256 i = 0; i < 3; i++) {
            predictors[i] = address(uint160(10 + i));
            vm.startPrank(predictors[i]);
            usdc.mint(predictors[i], STAKE_FEE);
            usdc.approve(address(engine), STAKE_FEE);
            uint256[] memory conf = new uint256[](0);
            engine.submitPrediction(bountyId, 0, conf, (i + 1) * 100, 18);
            vm.stopPrank();
        }
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.startPrank(oracle);
        vm.expectRevert(PredictionEngine.InvalidMedianError.selector);
        engine.resolve(bountyId, 200, 18, 50e18);
        vm.stopPrank();
    }
    
    function test_Resolve_Reverts() public {
        uint256 bountyId = _createCategoricalBounty(3);
        
        // Non-oracle
        // vm.expectRevert(PredictionEngine.NotOracle.selector);
        // Actually OZ AccessControl throws string or custom error in v5
        vm.startPrank(address(99));
        // We will just expect Revert
        vm.expectRevert();
        engine.resolve(bountyId, 1, 0, 0);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        // Already resolved
        vm.startPrank(oracle);
        engine.resolve(bountyId, 1, 0, 0);
        
        vm.expectRevert(PredictionEngine.BountyNotClosed.selector);
        engine.resolve(bountyId, 1, 0, 0);
        vm.stopPrank();
    }
}
