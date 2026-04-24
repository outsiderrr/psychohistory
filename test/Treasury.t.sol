// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console2} from "forge-std/Test.sol";
import {Treasury} from "../src/core/Treasury.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract MaliciousERC20 is MockERC20 {
    Treasury public treasury;

    constructor() MockERC20("Malicious", "MAL", 6) {}

    function setTreasury(Treasury _treasury) external {
        treasury = _treasury;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (address(treasury) != address(0)) {
            treasury.receiveSlashedFunds(1, amount);
        }
        return super.transferFrom(from, to, amount);
    }
}

contract TreasuryTest is Test {
    Treasury public treasury;
    MockERC20 public usdc;

    address public admin = makeAddr("admin");
    address public engine = makeAddr("engine");
    address public operator = makeAddr("operator");
    address public random = makeAddr("random");

    event SlashedFundsReceived(uint256 indexed bountyId, uint256 amount);
    event BuybackAndBurn(address indexed dexRouter, uint256 amountIn, uint256 amountOut);

    error ReentrancyGuardReentrantCall();

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        Treasury impl = new Treasury();

        bytes memory initData = abi.encodeWithSelector(
            Treasury.initialize.selector,
            address(usdc),
            admin
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl),
            admin,
            initData
        );

        treasury = Treasury(address(proxy));

        vm.startPrank(admin);
        treasury.grantRole(treasury.PREDICTION_ENGINE_ROLE(), engine);
        treasury.grantRole(treasury.TREASURY_OPERATOR_ROLE(), operator);
        vm.stopPrank();
    }

    function test_ReceiveSlashedFunds_HappyPath() public {
        uint256 amount = 100e6;
        usdc.mint(engine, amount);
        
        vm.startPrank(engine);
        usdc.approve(address(treasury), amount);

        vm.expectEmit(true, false, false, true);
        emit SlashedFundsReceived(1, amount);

        treasury.receiveSlashedFunds(1, amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(treasury)), amount);
        assertEq(treasury.slashedPerBounty(1), amount);
    }

    function test_RevertWhen_ReceiveSlashedFunds_Unauthorized() public {
        uint256 amount = 100e6;
        usdc.mint(random, amount);

        vm.startPrank(random);
        usdc.approve(address(treasury), amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                random,
                treasury.PREDICTION_ENGINE_ROLE()
            )
        );
        treasury.receiveSlashedFunds(1, amount);
        vm.stopPrank();
    }

    function test_BuybackAndBurn_HappyPath() public {
        address router = makeAddr("router");
        bytes memory swapData = "";

        vm.prank(operator);
        vm.expectEmit(true, false, false, true);
        emit BuybackAndBurn(router, 0, 100e18);

        treasury.buybackAndBurn(router, swapData, 100e18);
    }

    function test_RevertWhen_BuybackAndBurn_Unauthorized() public {
        address router = makeAddr("router");
        bytes memory swapData = "";

        vm.startPrank(random);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                random,
                treasury.TREASURY_OPERATOR_ROLE()
            )
        );
        treasury.buybackAndBurn(router, swapData, 100e18);
        vm.stopPrank();
    }

    function test_RevertWhen_Reentrancy_ReceiveSlashedFunds() public {
        MaliciousERC20 malUsdc = new MaliciousERC20();
        Treasury malImpl = new Treasury();
        
        bytes memory initData = abi.encodeWithSelector(
            Treasury.initialize.selector,
            address(malUsdc),
            admin
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(malImpl),
            admin,
            initData
        );
        
        Treasury malTreasury = Treasury(address(proxy));

        vm.startPrank(admin);
        malTreasury.grantRole(malTreasury.PREDICTION_ENGINE_ROLE(), engine);
        malTreasury.grantRole(malTreasury.PREDICTION_ENGINE_ROLE(), address(malUsdc));
        vm.stopPrank();

        malUsdc.setTreasury(malTreasury);

        uint256 amount = 100e6;
        malUsdc.mint(engine, amount);

        vm.startPrank(engine);
        malUsdc.approve(address(malTreasury), amount);

        vm.expectRevert(ReentrancyGuardReentrantCall.selector);
        malTreasury.receiveSlashedFunds(1, amount);
        vm.stopPrank();
    }
}
