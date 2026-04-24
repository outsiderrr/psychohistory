// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./PredictionEngineBase.t.sol";
import {Prediction, PredictionType} from "../src/libraries/PsychohistoryTypes.sol";
import {STAKE_FEE, BPS} from "../src/libraries/Constants.sol";

contract PredictionEngineTest is PredictionEngineBaseTest {
    function test_SubmitPrediction_Categorical() public {
        uint256 bountyId = _createCategoricalBounty(3);
        
        uint256[] memory conf = new uint256[](3);
        conf[0] = 5000;
        conf[1] = 3000;
        conf[2] = 2000;
        
        address predictor = address(10);
        vm.startPrank(predictor);
        usdc.mint(predictor, STAKE_FEE);
        usdc.approve(address(engine), STAKE_FEE);
        
        engine.submitPrediction(bountyId, 1, conf, 0, 0);
        
        Prediction memory pred = engine.getPrediction(bountyId, predictor);
        assertEq(pred.predictor, predictor);
        assertEq(pred.selectedOption, 1);
        assertEq(pred.stakeAmount, STAKE_FEE);
        vm.stopPrank();
    }
    
    function test_SubmitPrediction_Numerical() public {
        uint256 bountyId = _createNumericalBounty();
        
        uint256[] memory conf = new uint256[](0);
        
        address predictor = address(10);
        vm.startPrank(predictor);
        usdc.mint(predictor, STAKE_FEE);
        usdc.approve(address(engine), STAKE_FEE);
        
        engine.submitPrediction(bountyId, 0, conf, 100, 18);
        
        Prediction memory pred = engine.getPrediction(bountyId, predictor);
        assertEq(pred.predictedValue, 100);
        assertEq(pred.predictedDecimals, 18);
        vm.stopPrank();
    }
    
    function test_SubmitPrediction_RevertDoublePrediction() public {
        uint256 bountyId = _createCategoricalBounty(3);
        uint256[] memory conf = new uint256[](3);
        conf[0] = 10000; conf[1] = 0; conf[2] = 0;
        
        address predictor = address(10);
        vm.startPrank(predictor);
        usdc.mint(predictor, STAKE_FEE * 2);
        usdc.approve(address(engine), STAKE_FEE * 2);
        
        engine.submitPrediction(bountyId, 0, conf, 0, 0);
        vm.expectRevert(PredictionEngine.AlreadyPredicted.selector);
        engine.submitPrediction(bountyId, 0, conf, 0, 0);
        vm.stopPrank();
    }
    
    function test_SubmitPrediction_RevertAfterClose() public {
        uint256 bountyId = _createNumericalBounty();
        uint256[] memory conf = new uint256[](0);
        
        address predictor = address(10);
        vm.startPrank(predictor);
        usdc.mint(predictor, STAKE_FEE);
        usdc.approve(address(engine), STAKE_FEE);
        
        vm.warp(block.timestamp + 2 days); // after close
        vm.expectRevert(PredictionEngine.BountyClosed.selector);
        engine.submitPrediction(bountyId, 0, conf, 100, 18);
        vm.stopPrank();
    }
    
    function test_SubmitPrediction_CategoricalReverts() public {
        uint256 bountyId = _createCategoricalBounty(3);
        address predictor = address(10);
        usdc.mint(predictor, STAKE_FEE * 10);
        vm.startPrank(predictor);
        usdc.approve(address(engine), STAKE_FEE * 10);
        
        // Invalid selectedOption
        uint256[] memory conf = new uint256[](3);
        conf[0] = 10000; conf[1] = 0; conf[2] = 0;
        vm.expectRevert(PredictionEngine.InvalidOption.selector);
        engine.submitPrediction(bountyId, 3, conf, 0, 0);
        
        // Wrong array length
        uint256[] memory conf2 = new uint256[](2);
        conf2[0] = 5000; conf2[1] = 5000;
        vm.expectRevert(PredictionEngine.InvalidArrayLength.selector);
        engine.submitPrediction(bountyId, 1, conf2, 0, 0);
        
        // Sum != 10000
        uint256[] memory conf3 = new uint256[](3);
        conf3[0] = 5000; conf3[1] = 4000; conf3[2] = 0;
        vm.expectRevert(PredictionEngine.InvalidConfidenceSum.selector);
        engine.submitPrediction(bountyId, 1, conf3, 0, 0);
        vm.stopPrank();
    }
    
    function test_SubmitPrediction_NumericalReverts() public {
        uint256 bountyId = _createNumericalBounty();
        address predictor = address(10);
        usdc.mint(predictor, STAKE_FEE * 10);
        vm.startPrank(predictor);
        usdc.approve(address(engine), STAKE_FEE * 10);
        
        // Non-empty array
        uint256[] memory conf = new uint256[](1);
        conf[0] = 10000;
        vm.expectRevert(PredictionEngine.InvalidArrayLength.selector);
        engine.submitPrediction(bountyId, 0, conf, 100, 18);
        vm.stopPrank();
    }
    
    function test_DelegateVePSYH() public {
        uint256 bountyId = _createNumericalBounty();
        uint256[] memory conf = new uint256[](0);
        
        address predictor = address(10);
        vm.startPrank(predictor);
        usdc.mint(predictor, STAKE_FEE);
        usdc.approve(address(engine), STAKE_FEE);
        engine.submitPrediction(bountyId, 0, conf, 100, 18);
        
        psyh.mint(predictor, 1000e18);
        psyh.approve(address(vePSYH), 1000e18);
        vePSYH.lock(1000e18, 52 weeks);
        
        engine.delegateVePSYH(bountyId, 100e18);
        Prediction memory pred = engine.getPrediction(bountyId, predictor);
        assertEq(pred.vePSYHDelegated, 100e18);
        vm.stopPrank();
    }
}
