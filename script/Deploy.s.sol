// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {Treasury} from "../src/core/Treasury.sol";
import {VePSYHStaking} from "../src/core/VePSYHStaking.sol";
import {BountyManager} from "../src/core/BountyManager.sol";
import {PredictionEngine} from "../src/core/PredictionEngine.sol";
import {PsychohistoryRouter} from "../src/core/PsychohistoryRouter.sol";

import {MockERC20} from "../test/mocks/MockERC20.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        // Get oracle address from env, or default to deployer
        address oracle = vm.envOr("ORACLE_ADDRESS", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // --- 0. Mocks ---
        address usdc = vm.envOr("USDC_ADDRESS", address(0));
        address psyh = vm.envOr("PSYH_ADDRESS", address(0));

        if (usdc == address(0)) {
            MockERC20 mockUsdc = new MockERC20("USD Coin", "USDC", 6);
            usdc = address(mockUsdc);
            console2.log("Mock USDC deployed at:", usdc);
        } else {
            console2.log("Using USDC at:", usdc);
        }

        if (psyh == address(0)) {
            MockERC20 mockPsyh = new MockERC20("Psychohistory", "PSYH", 18);
            psyh = address(mockPsyh);
            console2.log("Mock PSYH deployed at:", psyh);
        } else {
            console2.log("Using PSYH at:", psyh);
        }

        address proxyAdminOwner = deployer;

        // --- 1. BrierMath ---
        // Note: BrierMath is a library with internal functions only, so it is
        // inlined directly into contracts that use it during compilation.
        // No standalone deployment is required.
        console2.log("BrierMath is an internal library (inlined automatically)");

        // --- 2. Treasury ---
        Treasury treasuryLogic = new Treasury();
        TransparentUpgradeableProxy treasuryProxy = new TransparentUpgradeableProxy(
            address(treasuryLogic),
            proxyAdminOwner,
            abi.encodeWithSelector(Treasury.initialize.selector, usdc, deployer)
        );
        Treasury treasury = Treasury(address(treasuryProxy));
        console2.log("Treasury deployed at:", address(treasury));

        // --- 3. VePSYHStaking ---
        VePSYHStaking stakingLogic = new VePSYHStaking();
        TransparentUpgradeableProxy stakingProxy = new TransparentUpgradeableProxy(
            address(stakingLogic),
            proxyAdminOwner,
            abi.encodeWithSelector(VePSYHStaking.initialize.selector, psyh, deployer)
        );
        VePSYHStaking vePSYH = VePSYHStaking(address(stakingProxy));
        console2.log("VePSYHStaking deployed at:", address(vePSYH));

        // --- 4. BountyManager ---
        BountyManager bountyLogic = new BountyManager();
        TransparentUpgradeableProxy bountyProxy = new TransparentUpgradeableProxy(
            address(bountyLogic),
            proxyAdminOwner,
            abi.encodeWithSelector(BountyManager.initialize.selector, usdc, deployer)
        );
        BountyManager bountyManager = BountyManager(address(bountyProxy));
        console2.log("BountyManager deployed at:", address(bountyManager));

        // --- 5. PredictionEngine ---
        PredictionEngine engineLogic = new PredictionEngine();
        TransparentUpgradeableProxy engineProxy = new TransparentUpgradeableProxy(
            address(engineLogic),
            proxyAdminOwner,
            abi.encodeWithSelector(
                PredictionEngine.initialize.selector,
                address(bountyManager),
                address(vePSYH),
                address(treasury),
                usdc,
                deployer
            )
        );
        PredictionEngine predictionEngine = PredictionEngine(address(engineProxy));
        console2.log("PredictionEngine deployed at:", address(predictionEngine));

        // --- 6. PsychohistoryRouter ---
        PsychohistoryRouter routerLogic = new PsychohistoryRouter();
        TransparentUpgradeableProxy routerProxy = new TransparentUpgradeableProxy(
            address(routerLogic),
            proxyAdminOwner,
            abi.encodeWithSelector(
                PsychohistoryRouter.initialize.selector,
                address(bountyManager),
                address(predictionEngine),
                usdc
            )
        );
        PsychohistoryRouter router = PsychohistoryRouter(address(routerProxy));
        console2.log("PsychohistoryRouter deployed at:", address(router));

        // --- 7. Grant Roles ---
        // Treasury: PredictionEngine -> PREDICTION_ENGINE_ROLE
        treasury.grantRole(treasury.PREDICTION_ENGINE_ROLE(), address(predictionEngine));
        console2.log("Granted PREDICTION_ENGINE_ROLE on Treasury to PredictionEngine");

        // VePSYHStaking: PredictionEngine -> DELEGATE_ROLE
        vePSYH.grantRole(vePSYH.DELEGATE_ROLE(), address(predictionEngine));
        console2.log("Granted DELEGATE_ROLE on VePSYHStaking to PredictionEngine");

        // PredictionEngine: Oracle -> ORACLE_ROLE
        predictionEngine.grantRole(predictionEngine.ORACLE_ROLE(), oracle);
        console2.log("Granted ORACLE_ROLE on PredictionEngine to Oracle:", oracle);

        // BountyManager: PredictionEngine -> PREDICTION_ENGINE_ROLE
        bountyManager.grantRole(bountyManager.PREDICTION_ENGINE_ROLE(), address(predictionEngine));
        console2.log("Granted PREDICTION_ENGINE_ROLE on BountyManager to PredictionEngine");

        vm.stopBroadcast();
    }
}
