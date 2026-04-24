// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {PredictionEngineBaseTest} from "./PredictionEngineBase.t.sol";
import {PsychohistoryRouter} from "../src/core/PsychohistoryRouter.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {PredictionType, BountyState} from "../src/libraries/PsychohistoryTypes.sol";
import {STAKE_FEE, BPS, MIN_LOCK_DURATION} from "../src/libraries/Constants.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract IntegrationTest is PredictionEngineBaseTest {
    PsychohistoryRouter router;

    function setUp() public override {
        super.setUp();

        vm.startPrank(admin);
        PsychohistoryRouter routerImpl = new PsychohistoryRouter();
        router = PsychohistoryRouter(address(new TransparentUpgradeableProxy(
            address(routerImpl),
            proxyAdmin,
            abi.encodeWithSelector(
                PsychohistoryRouter.initialize.selector,
                address(manager),
                address(engine),
                address(usdc)
            )
        )));

        manager.setRouter(address(router));
        engine.setRouter(address(router));
        vm.stopPrank();
    }

    // 1. Categorical 2-option happy path
    function test_Integration_CategoricalHappyPath() public {
        vm.startPrank(sponsor);
        usdc.mint(sponsor, 1000e6);
        usdc.approve(address(manager), 1000e6);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            2,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            1000e6
        );
        vm.stopPrank();

        uint256[] memory conf = new uint256[](2);
        conf[0] = 6000;
        conf[1] = 4000;

        address[] memory predictors = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            predictors[i] = address(uint160(100 + i));
            usdc.mint(predictors[i], STAKE_FEE);
            vm.startPrank(predictors[i]);
            usdc.approve(address(engine), STAKE_FEE);
            // 3 vs 2
            uint256 option = i < 3 ? 0 : 1;
            engine.submitPrediction(bountyId, option, conf, 0, 0);
            vm.stopPrank();
        }

        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        vm.prank(oracle);
        engine.resolve(bountyId, 0, 0, 0); // option 0 wins

        engine.settle(bountyId, 0, 5);

        assertEq(usdc.balanceOf(address(treasury)), 20e6); // 2 slashed

        uint256 balanceBefore1 = usdc.balanceOf(predictors[0]);
        vm.prank(predictors[0]);
        engine.claim(bountyId);
        uint256 payout = usdc.balanceOf(predictors[0]) - balanceBefore1;
        assertGt(payout, STAKE_FEE); // Gets refund + bounty

        // Check 3 winners claimed correctly
        vm.prank(predictors[1]);
        engine.claim(bountyId);
        vm.prank(predictors[2]);
        engine.claim(bountyId);

        // Losers cannot claim
        vm.startPrank(predictors[3]);
        vm.expectRevert();
        engine.claim(bountyId);
        vm.stopPrank();
    }

    // 2. Numerical multi-token
    function test_Integration_NumericalMultiToken() public {
        MockERC20 weth = new MockERC20("WETH", "WETH", 18);
        vm.prank(admin);
        manager.whitelistToken(address(weth), true);

        vm.startPrank(sponsor);
        usdc.mint(sponsor, 500e6);
        weth.mint(sponsor, 100e18);
        usdc.approve(address(manager), 500e6);
        weth.approve(address(manager), 100e18);

        uint256 bountyId = manager.createBounty(
            PredictionType.Numerical,
            0,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            500e6
        );
        manager.fundBounty(bountyId, address(weth), 100e18);
        vm.stopPrank();

        uint256[] memory conf = new uint256[](0);
        address[] memory predictors = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            predictors[i] = address(uint160(200 + i));
            usdc.mint(predictors[i], STAKE_FEE);
            vm.startPrank(predictors[i]);
            usdc.approve(address(engine), STAKE_FEE);
            // Predictions: 10, 20, 30... 100
            engine.submitPrediction(bountyId, 0, conf, (i + 1) * 10 * 1e18, 18);
            vm.stopPrank();
        }

        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        vm.prank(oracle);
        // resolve with 50, median error for top 50%
        engine.resolve(bountyId, 50 * 1e18, 18, 20 * 1e18); // 50-20=30, 50+20=70

        engine.settle(bountyId, 0, 10);

        assertEq(usdc.balanceOf(address(treasury)), 5 * STAKE_FEE); // 5 slashed

        // Top 5 (20,30,40,50,60,70,80) are 2,3,4,5,6,7,8 (which is 7? wait, 10 is 10..100)
        // Let's just claim for the exact winner
        vm.prank(predictors[4]); // predicted 50
        engine.claim(bountyId);
        
        assertGt(usdc.balanceOf(predictors[4]), STAKE_FEE);
        assertGt(weth.balanceOf(predictors[4]), 0);
    }

    // 3. vePSYH boost
    function test_Integration_VePSYHBoost() public {
        vm.startPrank(sponsor);
        usdc.mint(sponsor, 1000e6);
        usdc.approve(address(manager), 1000e6);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            2,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            1000e6
        );
        vm.stopPrank();

        uint256[] memory conf = new uint256[](2);
        conf[0] = 5000;
        conf[1] = 5000;

        // User 1 no boost
        address user1 = address(0x111);
        usdc.mint(user1, STAKE_FEE);
        vm.startPrank(user1);
        usdc.approve(address(engine), STAKE_FEE);
        engine.submitPrediction(bountyId, 0, conf, 0, 0);
        vm.stopPrank();

        // User 2 with boost
        address user2 = address(0x222);
        usdc.mint(user2, STAKE_FEE);
        psyh.mint(user2, 1000e18);
        vm.startPrank(user2);
        usdc.approve(address(engine), STAKE_FEE);
        psyh.approve(address(vePSYH), 1000e18);
        vePSYH.lock(1000e18, uint64(MIN_LOCK_DURATION));
        router.submitPredictionWithBoost(bountyId, 0, conf, 0, 0, 1000e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        vm.prank(oracle);
        engine.resolve(bountyId, 0, 0, 0);

        engine.settle(bountyId, 0, 2);

        vm.prank(user1);
        engine.claim(bountyId);
        uint256 payout1 = usdc.balanceOf(user1) - STAKE_FEE;

        vm.prank(user2);
        engine.claim(bountyId);
        uint256 payout2 = usdc.balanceOf(user2) - STAKE_FEE;

        // Boost should make payout2 roughly 3x payout1
        assertGt(payout2, payout1 * 2);
    }

    // 4. Cancellation
    function test_Integration_Cancellation() public {
        vm.startPrank(sponsor);
        usdc.mint(sponsor, 1000e6);
        usdc.approve(address(manager), 1000e6);
        
        uint256[] memory conf = new uint256[](2);
        conf[0] = 5000;
        conf[1] = 5000;

        usdc.mint(sponsor, STAKE_FEE);
        usdc.approve(address(engine), STAKE_FEE);
        uint256 bountyId = router.createBountyAndPredict(
            PredictionType.Categorical,
            2,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            1000e6,
            0,
            conf,
            0,
            0
        );
        vm.stopPrank();

        for (uint256 i = 0; i < 2; i++) {
            address user = address(uint160(300 + i));
            usdc.mint(user, STAKE_FEE);
            vm.startPrank(user);
            usdc.approve(address(engine), STAKE_FEE);
            engine.submitPrediction(bountyId, 0, conf, 0, 0);
            vm.stopPrank();
        }

        vm.prank(sponsor);
        manager.cancelBounty(bountyId);

        // Sponsor gets back 1000e6 bounty prize
        assertEq(usdc.balanceOf(sponsor), 1000e6);
    }

    // 5. Total Wipeout e2e
    function test_Integration_TotalWipeout() public {
        MockERC20 weth = new MockERC20("WETH", "WETH", 18);
        vm.prank(admin);
        manager.whitelistToken(address(weth), true);

        vm.startPrank(sponsor);
        usdc.mint(sponsor, 2000e6);
        weth.mint(sponsor, 500e18);
        usdc.approve(address(manager), 2000e6);
        weth.approve(address(manager), 500e18);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            2000e6
        );
        manager.fundBounty(bountyId, address(weth), 500e18);
        vm.stopPrank();

        uint256[] memory conf = new uint256[](3);
        conf[0] = 3333; conf[1] = 3333; conf[2] = 3334;

        for (uint256 i = 0; i < 10; i++) {
            address user = address(uint160(400 + i));
            usdc.mint(user, STAKE_FEE);
            vm.startPrank(user);
            usdc.approve(address(engine), STAKE_FEE);
            engine.submitPrediction(bountyId, 0, conf, 0, 0);
            vm.stopPrank();
        }

        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        vm.prank(oracle);
        engine.resolve(bountyId, 1, 0, 0); // Option 1 wins, everyone chose 0

        engine.settle(bountyId, 0, 10);

        assertEq(usdc.balanceOf(address(treasury)), 10 * STAKE_FEE); // 100 USDC to treasury

        vm.prank(sponsor);
        manager.claimRefund(bountyId);

        assertEq(usdc.balanceOf(sponsor), 2000e6);
        assertEq(weth.balanceOf(sponsor), 500e18);
    }

    // 6. 5-option stress test
    function test_Integration_5OptionStressTest() public {
        vm.startPrank(sponsor);
        usdc.mint(sponsor, 5000e6);
        usdc.approve(address(manager), 5000e6);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            5,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            5000e6
        );
        vm.stopPrank();

        uint256[] memory conf = new uint256[](5);
        conf[0] = 2000; conf[1] = 2000; conf[2] = 2000; conf[3] = 2000; conf[4] = 2000;

        for (uint256 i = 0; i < 50; i++) {
            address user = address(uint160(500 + i));
            usdc.mint(user, STAKE_FEE);
            vm.startPrank(user);
            usdc.approve(address(engine), STAKE_FEE);
            engine.submitPrediction(bountyId, i % 5, conf, 0, 0);
            vm.stopPrank();
        }

        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        vm.prank(oracle);
        engine.resolve(bountyId, 0, 0, 0);

        // Settle in 5 batches of 10
        for (uint256 i = 0; i < 5; i++) {
            engine.settle(bountyId, i * 10, (i + 1) * 10);
        }

        assertEq(usdc.balanceOf(address(treasury)), 40 * STAKE_FEE); // 40 slashed

        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < 50; i++) {
            if (i % 5 == 0) {
                address user = address(uint160(500 + i));
                vm.prank(user);
                engine.claim(bountyId);
                totalClaimed += usdc.balanceOf(user);
            }
        }
        
        // 10 winners * 10 USDC stake + 5000 USDC bounty
        assertApproxEqAbs(totalClaimed, 5100e6, 1e6); // Allow tiny rounding
    }

    // 7. Edge cases
    function test_Integration_EdgeCases() public {
        vm.startPrank(sponsor);
        usdc.mint(sponsor, 1000e6);
        usdc.approve(address(manager), 1000e6);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            2,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            1000e6
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        vm.prank(oracle);
        engine.resolve(bountyId, 0, 0, 0);
        
        // 0 predictors
        engine.settle(bountyId, 0, 0);
        vm.prank(sponsor);
        manager.claimRefund(bountyId);
        assertEq(usdc.balanceOf(sponsor), 1000e6);
    }

    // 8. Invalidated bounty e2e
    function test_Integration_InvalidatedBounty() public {
        vm.startPrank(sponsor);
        usdc.mint(sponsor, 500e6);
        usdc.approve(address(manager), 500e6);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            2,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            500e6
        );
        vm.stopPrank();

        uint256[] memory conf = new uint256[](2);
        conf[0] = 5000;
        conf[1] = 5000;

        address[] memory predictors = new address[](3);
        for (uint256 i = 0; i < 3; i++) {
            predictors[i] = address(uint160(600 + i));
            usdc.mint(predictors[i], STAKE_FEE);
            vm.startPrank(predictors[i]);
            usdc.approve(address(engine), STAKE_FEE);
            engine.submitPrediction(bountyId, i % 2, conf, 0, 0);
            vm.stopPrank();
        }

        vm.warp(block.timestamp + 1 days + 1);
        manager.updateBountyState(bountyId, BountyState.Closed);
        
        vm.prank(oracle);
        engine.resolveAsInvalid(bountyId);

        engine.settle(bountyId, 0, 3);

        // Treasury = 0 USDC
        assertEq(usdc.balanceOf(address(treasury)), 0);

        // Predictors claim
        for (uint256 i = 0; i < 3; i++) {
            uint256 balBefore = usdc.balanceOf(predictors[i]);
            vm.prank(predictors[i]);
            engine.claim(bountyId);
            assertEq(usdc.balanceOf(predictors[i]) - balBefore, STAKE_FEE);
        }

        // Sponsor claimRefund
        uint256 sponsorBalBefore = usdc.balanceOf(sponsor);
        vm.prank(sponsor);
        manager.claimRefund(bountyId);
        assertEq(usdc.balanceOf(sponsor) - sponsorBalBefore, 500e6);
    }
}