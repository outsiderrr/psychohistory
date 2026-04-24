// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {VePSYHStaking} from "../src/core/VePSYHStaking.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {VeLock} from "../src/libraries/PsychohistoryTypes.sol";
import {MIN_LOCK_DURATION, MAX_LOCK_DURATION} from "../src/libraries/Constants.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract VePSYHStakingTest is Test {
    VePSYHStaking public staking;
    MockERC20 public psyh;
    address public admin = address(1);
    address public user = address(2);
    address public delegateRoleUser = address(3);

    function setUp() public {
        psyh = new MockERC20("PSYH", "PSYH", 18);
        VePSYHStaking impl = new VePSYHStaking();
        
        bytes memory initData = abi.encodeWithSelector(
            VePSYHStaking.initialize.selector,
            address(psyh),
            admin
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl),
            admin,
            initData
        );

        staking = VePSYHStaking(address(proxy));

        vm.startPrank(admin);
        staking.grantRole(staking.DELEGATE_ROLE(), delegateRoleUser);
        vm.stopPrank();

        psyh.mint(user, 1000 ether);
        vm.prank(user);
        psyh.approve(address(staking), type(uint256).max);
    }

    // - lock happy path → VeLock stored, PSYH transferred
    function test_lock_HappyPath() public {
        vm.startPrank(user);
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION));
        vm.stopPrank();

        VeLock memory lockInfo = staking.getVeLock(user);
        assertEq(lockInfo.psyhAmount, 100 ether);
        assertEq(lockInfo.vePSYHMinted, 100 ether);
        assertEq(lockInfo.lockStart, block.timestamp);
        assertEq(lockInfo.lockEnd, block.timestamp + MIN_LOCK_DURATION);
        assertEq(lockInfo.delegatedTotal, 0);

        assertEq(psyh.balanceOf(address(staking)), 100 ether);
        assertEq(psyh.balanceOf(user), 900 ether);
        assertEq(staking.availableVePSYH(user), 100 ether);
    }

    // - lock duration < MIN → revert
    function test_lock_DurationTooShort() public {
        vm.startPrank(user);
        vm.expectRevert("VePSYHStaking: lock duration < MIN");
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION - 1));
        vm.stopPrank();
    }

    // - lock duration > MAX → revert
    function test_lock_DurationTooLong() public {
        vm.startPrank(user);
        vm.expectRevert("VePSYHStaking: lock duration > MAX");
        staking.lock(100 ether, uint64(MAX_LOCK_DURATION + 1));
        vm.stopPrank();
    }

    // - lock with existing active lock → revert
    function test_lock_ExistingActiveLock() public {
        vm.startPrank(user);
        staking.lock(50 ether, uint64(MIN_LOCK_DURATION));
        vm.expectRevert("VePSYHStaking: existing active lock");
        staking.lock(50 ether, uint64(MIN_LOCK_DURATION));
        vm.stopPrank();
    }

    // - unlock before lockEnd → revert
    function test_unlock_BeforeLockEnd() public {
        vm.startPrank(user);
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION));
        vm.expectRevert("VePSYHStaking: lock not expired");
        staking.unlock();
        vm.stopPrank();
    }

    // - unlock with delegations outstanding → revert
    function test_unlock_WithDelegations() public {
        vm.prank(user);
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION));

        vm.prank(delegateRoleUser);
        staking.delegate(user, 1, 50 ether);

        vm.warp(block.timestamp + MIN_LOCK_DURATION);

        vm.prank(user);
        vm.expectRevert("VePSYHStaking: active delegations");
        staking.unlock();
    }

    // - unlock happy path → PSYH returned
    function test_unlock_HappyPath() public {
        vm.prank(user);
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION));

        vm.warp(block.timestamp + MIN_LOCK_DURATION);

        vm.prank(user);
        staking.unlock();

        VeLock memory lockInfo = staking.getVeLock(user);
        assertEq(lockInfo.psyhAmount, 0);

        assertEq(psyh.balanceOf(address(staking)), 0);
        assertEq(psyh.balanceOf(user), 1000 ether);
    }

    // - delegate → reduces availableVePSYH
    function test_delegate() public {
        vm.prank(user);
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION));

        vm.prank(delegateRoleUser);
        staking.delegate(user, 1, 30 ether);

        assertEq(staking.availableVePSYH(user), 70 ether);
        VeLock memory lockInfo = staking.getVeLock(user);
        assertEq(lockInfo.delegatedTotal, 30 ether);
    }

    // - delegate > available → revert
    function test_delegate_ExceedsAvailable() public {
        vm.prank(user);
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION));

        vm.prank(delegateRoleUser);
        vm.expectRevert("VePSYHStaking: insufficient available vePSYH");
        staking.delegate(user, 1, 101 ether);
    }

    // - undelegate → restores availableVePSYH
    function test_undelegate() public {
        vm.prank(user);
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION));

        vm.startPrank(delegateRoleUser);
        staking.delegate(user, 1, 30 ether);
        staking.undelegate(user, 1, 10 ether);
        vm.stopPrank();

        assertEq(staking.availableVePSYH(user), 80 ether);
        VeLock memory lockInfo = staking.getVeLock(user);
        assertEq(lockInfo.delegatedTotal, 20 ether);
    }

    // - only DELEGATE_ROLE can delegate/undelegate
    function test_delegate_Undelegate_OnlyDelegateRole() public {
        vm.prank(user);
        staking.lock(100 ether, uint64(MIN_LOCK_DURATION));

        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, staking.DELEGATE_ROLE()));
        staking.delegate(user, 1, 30 ether);

        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user, staking.DELEGATE_ROLE()));
        staking.undelegate(user, 1, 30 ether);
        vm.stopPrank();
    }
}