// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";

/**
 * @title Treasury
 * @notice Receives slashed USDC and handles future buyback-and-burn.
 */
contract Treasury is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, ITreasury {
    using SafeERC20 for IERC20;

    bytes32 public constant PREDICTION_ENGINE_ROLE = keccak256("PREDICTION_ENGINE_ROLE");
    bytes32 public constant TREASURY_OPERATOR_ROLE = keccak256("TREASURY_OPERATOR_ROLE");

    IERC20 public usdc;
    mapping(uint256 => uint256) public slashedPerBounty;

    uint256[50] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the Treasury contract.
     * @param _usdc Address of the USDC token.
     * @param _admin Address to be granted the DEFAULT_ADMIN_ROLE.
     */
    function initialize(address _usdc, address _admin) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        require(_usdc != address(0), "Treasury: zero address usdc");
        require(_admin != address(0), "Treasury: zero address admin");

        usdc = IERC20(_usdc);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice Receives slashed funds from the PredictionEngine.
     * @param bountyId The ID of the bounty.
     * @param amount The amount of USDC slashed.
     */
    function receiveSlashedFunds(uint256 bountyId, uint256 amount) external nonReentrant onlyRole(PREDICTION_ENGINE_ROLE) {
        require(amount > 0, "Treasury: amount must be > 0");
        slashedPerBounty[bountyId] += amount;
        
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        
        emit SlashedFundsReceived(bountyId, amount);
    }

    /**
     * @notice Placeholder for future buyback and burn functionality.
     * @param dexRouter Address of the DEX router.
     * @param swapData Encoded swap data for the DEX.
     * @param minPSYOut Minimum amount of PSYH tokens to receive.
     */
    function buybackAndBurn(address dexRouter, bytes calldata swapData, uint256 minPSYOut) external nonReentrant onlyRole(TREASURY_OPERATOR_ROLE) {
        swapData; // silence unused variable warning
        // V2 MVP: just emit event, hold funds (DEX integration deferred)
        emit BuybackAndBurn(dexRouter, 0, minPSYOut);
    }
}
