// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {PredictionEngine} from "../src/core/PredictionEngine.sol";
import {BountyManager} from "../src/core/BountyManager.sol";
import {Treasury} from "../src/core/Treasury.sol";
import {VePSYHStaking} from "../src/core/VePSYHStaking.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {PredictionType, BountyState} from "../src/libraries/PsychohistoryTypes.sol";
import {STAKE_FEE, BPS} from "../src/libraries/Constants.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract PredictionEngineBaseTest is Test {
    PredictionEngine engine;
    BountyManager manager;
    Treasury treasury;
    VePSYHStaking vePSYH;
    MockERC20 usdc;
    MockERC20 psyh;
    
    address admin = address(1);
    address oracle = address(2);
    address sponsor = address(3);
    address proxyAdmin = address(4);
    
    function setUp() public virtual {
        vm.startPrank(admin);
        
        usdc = new MockERC20("USDC", "USDC", 6);
        psyh = new MockERC20("PSYH", "PSYH", 18);
        
        BountyManager managerImpl = new BountyManager();
        Treasury treasuryImpl = new Treasury();
        VePSYHStaking vePSYHImpl = new VePSYHStaking();
        PredictionEngine engineImpl = new PredictionEngine();
        
        manager = BountyManager(address(new TransparentUpgradeableProxy(
            address(managerImpl),
            proxyAdmin,
            abi.encodeWithSelector(BountyManager.initialize.selector, address(usdc), admin)
        )));
        
        treasury = Treasury(address(new TransparentUpgradeableProxy(
            address(treasuryImpl),
            proxyAdmin,
            abi.encodeWithSelector(Treasury.initialize.selector, address(usdc), admin)
        )));
        
        vePSYH = VePSYHStaking(address(new TransparentUpgradeableProxy(
            address(vePSYHImpl),
            proxyAdmin,
            abi.encodeWithSelector(VePSYHStaking.initialize.selector, address(psyh), admin)
        )));
        
        engine = PredictionEngine(address(new TransparentUpgradeableProxy(
            address(engineImpl),
            proxyAdmin,
            abi.encodeWithSelector(
                PredictionEngine.initialize.selector,
                address(manager),
                address(vePSYH),
                address(treasury),
                address(usdc),
                admin
            )
        )));
        
        engine.grantRole(engine.ORACLE_ROLE(), oracle);
        manager.grantRole(manager.PREDICTION_ENGINE_ROLE(), address(engine));
        manager.grantRole(manager.PREDICTION_ENGINE_ROLE(), address(this));
        treasury.grantRole(treasury.PREDICTION_ENGINE_ROLE(), address(engine));
        vePSYH.grantRole(vePSYH.DELEGATE_ROLE(), address(engine));
        manager.whitelistToken(address(usdc), true);
        manager.whitelistToken(address(psyh), true);
        
        vm.stopPrank();
    }
    
    function _createCategoricalBounty(uint8 optionsCount) internal returns (uint256) {
        vm.startPrank(sponsor);
        usdc.mint(sponsor, 1000e6);
        usdc.approve(address(manager), 1000e6);
        
        uint256 bountyId = manager.createBounty(
            PredictionType.Categorical,
            optionsCount,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100e6
        );
        vm.stopPrank();
        return bountyId;
    }
    
    function _createNumericalBounty() internal returns (uint256) {
        vm.startPrank(sponsor);
        usdc.mint(sponsor, 1000e6);
        usdc.approve(address(manager), 1000e6);
        
        uint256 bountyId = manager.createBounty(
            PredictionType.Numerical,
            0,
            "ipfs://metadata",
            uint64(block.timestamp + 1 days),
            uint64(block.timestamp + 2 days),
            address(usdc),
            100e6
        );
        vm.stopPrank();
        return bountyId;
    }
}
