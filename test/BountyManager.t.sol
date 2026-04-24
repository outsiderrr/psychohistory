// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {BountyManager} from "../src/core/BountyManager.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {PredictionType, BountyState, Bounty, BountyPrize} from "../src/libraries/PsychohistoryTypes.sol";
import {MIN_OPTIONS, MAX_OPTIONS} from "../src/libraries/Constants.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract BountyManagerTest is Test {
    BountyManager manager;
    MockERC20 usdc;
    MockERC20 mockToken1;
    MockERC20 mockToken2;
    MockERC20 nonWhitelistedToken;

    address admin = address(1);
    address creator = address(2);
    address stranger = address(3);
    address predictionEngine = address(4);

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        mockToken1 = new MockERC20("Token1", "TK1", 18);
        mockToken2 = new MockERC20("Token2", "TK2", 18);
        nonWhitelistedToken = new MockERC20("NWToken", "NWT", 18);

        BountyManager impl = new BountyManager();
        bytes memory initData = abi.encodeWithSelector(
            BountyManager.initialize.selector,
            address(usdc),
            admin
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl),
            admin,
            initData
        );

        manager = BountyManager(address(proxy));

        vm.startPrank(admin);
        manager.whitelistToken(address(usdc), true);
        manager.whitelistToken(address(mockToken1), true);
        manager.whitelistToken(address(mockToken2), true);
        manager.grantRole(manager.PREDICTION_ENGINE_ROLE(), predictionEngine);
        vm.stopPrank();

        usdc.mint(creator, 1000000 * 10**6);
        mockToken1.mint(creator, 1000 ether);
        mockToken2.mint(creator, 1000 ether);
        nonWhitelistedToken.mint(creator, 1000 ether);

        vm.startPrank(creator);
        usdc.approve(address(manager), type(uint256).max);
        mockToken1.approve(address(manager), type(uint256).max);
        mockToken2.approve(address(manager), type(uint256).max);
        nonWhitelistedToken.approve(address(manager), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(stranger);
        usdc.approve(address(manager), type(uint256).max);
        mockToken1.approve(address(manager), type(uint256).max);
        mockToken2.approve(address(manager), type(uint256).max);
        vm.stopPrank();
        
        vm.warp(1000000); // Avoid closeTimestamp in past issues for timestamp 0
    }

    function test_CreateBounty_Categorical_N3() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        Bounty memory b = manager.getBounty(bountyId);
        assertEq(b.bountyId, bountyId);
        assertEq(b.creator, creator);
        assertEq(b.metadataURI, "ipfs://metadata");
        assertEq(uint(b.predictionType), uint(PredictionType.Categorical));
        assertEq(b.optionsCount, 3);
        assertEq(b.closeTimestamp, block.timestamp + 1 days);
        assertEq(b.resolutionDeadline, block.timestamp + 2 days);
        assertEq(uint(b.state), uint(BountyState.Active));

        BountyPrize[] memory prizes = manager.getBountyPrizes(bountyId);
        assertEq(prizes.length, 1);
        assertEq(prizes[0].token, address(usdc));
        assertEq(prizes[0].totalDeposited, 100 * 10**6);
    }

    function test_Revert_CreateBounty_Categorical_InvalidN() public {
        vm.startPrank(creator);
        
        vm.expectRevert("BountyManager: invalid optionsCount");
        manager.createBounty(
            PredictionType.Categorical,
            6,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );

        vm.expectRevert("BountyManager: invalid optionsCount");
        manager.createBounty(
            PredictionType.Categorical,
            1,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        
        vm.stopPrank();
    }

    function test_CreateBounty_Numerical_N0() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Numerical,
            0,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        Bounty memory b = manager.getBounty(bountyId);
        assertEq(b.optionsCount, 0);
        assertEq(uint(b.predictionType), uint(PredictionType.Numerical));
    }

    function test_Revert_CreateBounty_Numerical_N3() public {
        vm.startPrank(creator);
        vm.expectRevert("BountyManager: Numerical must have 0 options");
        manager.createBounty(
            PredictionType.Numerical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();
    }

    function test_Revert_CreateBounty_NonWhitelistedToken() public {
        vm.startPrank(creator);
        vm.expectRevert("BountyManager: token not whitelisted");
        manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(nonWhitelistedToken),
            100 * 10**6
        );
        vm.stopPrank();
    }

    function test_Revert_CreateBounty_CloseTimestampPast() public {
        vm.startPrank(creator);
        vm.expectRevert("BountyManager: closeTimestamp in past");
        manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp - 1),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();
    }

    function test_FundBounty() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        
        manager.fundBounty(bountyId, address(usdc), 50 * 10**6);
        BountyPrize[] memory prizes = manager.getBountyPrizes(bountyId);
        assertEq(prizes.length, 1);
        assertEq(prizes[0].totalDeposited, 150 * 10**6);

        manager.fundBounty(bountyId, address(mockToken1), 200 ether);
        prizes = manager.getBountyPrizes(bountyId);
        assertEq(prizes.length, 2);
        assertEq(prizes[1].token, address(mockToken1));
        assertEq(prizes[1].totalDeposited, 200 ether);
        
        vm.stopPrank();
    }

    function test_Revert_FundBounty_NonActive() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        manager.cancelBounty(bountyId);
        
        vm.expectRevert("BountyManager: bounty not Active");
        manager.fundBounty(bountyId, address(usdc), 50 * 10**6);
        vm.stopPrank();
    }

    function test_CancelBounty() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        
        uint256 balanceBefore = usdc.balanceOf(creator);
        manager.cancelBounty(bountyId);
        uint256 balanceAfter = usdc.balanceOf(creator);
        
        assertEq(balanceAfter - balanceBefore, 100 * 10**6);
        Bounty memory b = manager.getBounty(bountyId);
        assertEq(uint(b.state), uint(BountyState.Cancelled));
        vm.stopPrank();
    }

    function test_CancelBounty_ByAdmin() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        uint256 balanceBefore = usdc.balanceOf(creator);
        vm.startPrank(admin);
        manager.cancelBounty(bountyId);
        vm.stopPrank();
        
        uint256 balanceAfter = usdc.balanceOf(creator);
        assertEq(balanceAfter - balanceBefore, 100 * 10**6);
        Bounty memory b = manager.getBounty(bountyId);
        assertEq(uint(b.state), uint(BountyState.Cancelled));
    }

    function test_Revert_CancelBounty_Stranger() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        vm.startPrank(stranger);
        vm.expectRevert("BountyManager: unauthorized");
        manager.cancelBounty(bountyId);
        vm.stopPrank();
    }

    function test_ClaimRefund() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        vm.startPrank(predictionEngine);
        manager.updateBountyState(bountyId, BountyState.Closed);
        manager.updateBountyState(bountyId, BountyState.Resolved);
        manager.updateBountyState(bountyId, BountyState.Settled);
        manager.markTotalWipeout(bountyId);
        vm.stopPrank();

        vm.startPrank(creator);
        uint256 balanceBefore = usdc.balanceOf(creator);
        manager.claimRefund(bountyId);
        uint256 balanceAfter = usdc.balanceOf(creator);
        
        assertEq(balanceAfter - balanceBefore, 100 * 10**6);
        assertTrue(manager.sponsorRefundClaimed(bountyId));
        vm.stopPrank();
    }

    function test_Revert_ClaimRefund_Stranger() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        vm.startPrank(predictionEngine);
        manager.updateBountyState(bountyId, BountyState.Closed);
        manager.updateBountyState(bountyId, BountyState.Resolved);
        manager.updateBountyState(bountyId, BountyState.Settled);
        manager.markTotalWipeout(bountyId);
        vm.stopPrank();

        vm.startPrank(stranger);
        vm.expectRevert("BountyManager: not creator");
        manager.claimRefund(bountyId);
        vm.stopPrank();
    }

    function test_Revert_ClaimRefund_NotWipeout() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        vm.startPrank(predictionEngine);
        manager.updateBountyState(bountyId, BountyState.Closed);
        manager.updateBountyState(bountyId, BountyState.Resolved);
        manager.updateBountyState(bountyId, BountyState.Settled);
        vm.stopPrank();

        vm.startPrank(creator);
        vm.expectRevert("BountyManager: not total wipeout or invalidated");
        manager.claimRefund(bountyId);
        vm.stopPrank();
    }

    function test_Revert_ClaimRefund_Twice() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        vm.startPrank(predictionEngine);
        manager.updateBountyState(bountyId, BountyState.Closed);
        manager.updateBountyState(bountyId, BountyState.Resolved);
        manager.updateBountyState(bountyId, BountyState.Settled);
        manager.markTotalWipeout(bountyId);
        vm.stopPrank();

        vm.startPrank(creator);
        manager.claimRefund(bountyId);
        
        vm.expectRevert("BountyManager: refund already claimed");
        manager.claimRefund(bountyId);
        vm.stopPrank();
    }

    function test_Revert_StateTransition_ResolvedToActive() public {
        vm.startPrank(creator);
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            3,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100 * 10**6
        );
        vm.stopPrank();

        vm.startPrank(predictionEngine);
        manager.updateBountyState(bountyId, BountyState.Closed);
        manager.updateBountyState(bountyId, BountyState.Resolved);
        
        vm.expectRevert("BountyManager: invalid state transition");
        manager.updateBountyState(bountyId, BountyState.Active);
        vm.stopPrank();
    }
}
