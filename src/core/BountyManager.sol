// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PredictionType, BountyState, BountyPrize, Bounty} from "../libraries/PsychohistoryTypes.sol";
import {IBountyManager} from "../interfaces/IBountyManager.sol";
import {MIN_OPTIONS, MAX_OPTIONS} from "../libraries/Constants.sol";

/**
 * @title BountyManager
 * @notice Manages bounty lifecycle: create, fund, cancel, claimRefund.
 */
contract BountyManager is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IBountyManager {
    using SafeERC20 for IERC20;

    bytes32 public constant PREDICTION_ENGINE_ROLE = keccak256("PREDICTION_ENGINE_ROLE");

    uint256 public nextBountyId;
    mapping(uint256 => Bounty) internal _bounties;
    mapping(address => bool) public whitelistedTokens;
    IERC20 public usdc;
    
    mapping(uint256 => bool) public isTotalWipeout;
    mapping(uint256 => bool) public isInvalidated;
    mapping(uint256 => bool) public sponsorRefundClaimed;

    address public router;

    function setRouter(address _router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        router = _router;
    }

    function _msgSender() internal view override returns (address sender) {
        if (msg.sender == router) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view override returns (bytes calldata) {
        if (msg.sender == router) {
            return msg.data[:msg.data.length - 20];
        }
        return super._msgData();
    }

    uint256[49] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the BountyManager contract.
     * @param _usdc Address of the USDC token.
     * @param _admin Address to be granted the DEFAULT_ADMIN_ROLE.
     */
    function initialize(address _usdc, address _admin) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        require(_usdc != address(0), "BountyManager: zero address usdc");
        require(_admin != address(0), "BountyManager: zero address admin");

        usdc = IERC20(_usdc);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice Whitelists or removes a token from the whitelist.
     * @param token Address of the token.
     * @param status Boolean indicating whitelist status.
     */
    function whitelistToken(address token, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistedTokens[token] = status;
    }

    /**
     * @notice Creates a new bounty.
     * @param predictionType Type of prediction (Categorical or Numerical).
     * @param optionsCount Number of options for Categorical prediction.
     * @param metadataURI URI for bounty metadata.
     * @param closeTimestamp Timestamp when predictions close.
     * @param resolutionDeadline Deadline for bounty resolution.
     * @param prizeToken Initial prize token to fund.
     * @param prizeAmount Amount of initial prize token.
     * @return bountyId ID of the created bounty.
     */
    function createBounty(
        PredictionType predictionType,
        uint8 optionsCount,
        string calldata metadataURI,
        uint64 closeTimestamp,
        uint64 resolutionDeadline,
        address prizeToken,
        uint256 prizeAmount
    ) external nonReentrant returns (uint256 bountyId) {
        require(closeTimestamp > block.timestamp, "BountyManager: closeTimestamp in past");
        require(resolutionDeadline > closeTimestamp, "BountyManager: invalid resolutionDeadline");
        require(whitelistedTokens[prizeToken], "BountyManager: token not whitelisted");
        require(prizeAmount > 0, "BountyManager: prizeAmount must be > 0");

        if (predictionType == PredictionType.Categorical) {
            require(optionsCount >= MIN_OPTIONS && optionsCount <= MAX_OPTIONS, "BountyManager: invalid optionsCount");
        } else {
            require(optionsCount == 0, "BountyManager: Numerical must have 0 options");
        }

        bountyId = nextBountyId++;
        Bounty storage bounty = _bounties[bountyId];
        bounty.bountyId = bountyId;
        bounty.creator = _msgSender();
        bounty.metadataURI = metadataURI;
        bounty.predictionType = predictionType;
        bounty.optionsCount = optionsCount;
        bounty.startTimestamp = uint64(block.timestamp);
        bounty.closeTimestamp = closeTimestamp;
        bounty.resolutionDeadline = resolutionDeadline;
        bounty.state = BountyState.Active;

        bounty.prizes.push(BountyPrize({
            token: prizeToken,
            totalDeposited: prizeAmount,
            distributed: 0,
            refunded: 0
        }));

        IERC20(prizeToken).safeTransferFrom(_msgSender(), address(this), prizeAmount);

        emit BountyCreated(bountyId, _msgSender(), predictionType, optionsCount);
        emit BountyFunded(bountyId, prizeToken, prizeAmount);
    }

    /**
     * @notice Funds an active bounty with an additional token.
     * @param bountyId The ID of the bounty.
     * @param token Address of the prize token.
     * @param amount Amount of prize token to fund.
     */
    function fundBounty(uint256 bountyId, address token, uint256 amount) external nonReentrant {
        require(amount > 0, "BountyManager: amount must be > 0");
        require(whitelistedTokens[token], "BountyManager: token not whitelisted");
        Bounty storage bounty = _bounties[bountyId];
        require(bounty.state == BountyState.Active, "BountyManager: bounty not Active");

        bool tokenExists = false;
        for (uint256 i = 0; i < bounty.prizes.length; i++) {
            if (bounty.prizes[i].token == token) {
                bounty.prizes[i].totalDeposited += amount;
                tokenExists = true;
                break;
            }
        }

        if (!tokenExists) {
            bounty.prizes.push(BountyPrize({
                token: token,
                totalDeposited: amount,
                distributed: 0,
                refunded: 0
            }));
        }

        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);

        emit BountyFunded(bountyId, token, amount);
    }

    /**
     * @notice Cancels an active bounty.
     * @param bountyId The ID of the bounty.
     */
    function cancelBounty(uint256 bountyId) external nonReentrant {
        Bounty storage bounty = _bounties[bountyId];
        require(_msgSender() == bounty.creator || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BountyManager: unauthorized");
        require(bounty.state == BountyState.Active, "BountyManager: not Active");

        _transitionState(bountyId, BountyState.Cancelled);
        
        // Refund prizes to creator
        for (uint256 i = 0; i < bounty.prizes.length; i++) {
            BountyPrize storage prize = bounty.prizes[i];
            if (prize.totalDeposited > 0) {
                uint256 refundAmount = prize.totalDeposited;
                prize.refunded += refundAmount;
                IERC20(prize.token).safeTransfer(bounty.creator, refundAmount);
            }
        }
    }

    /**
     * @notice Claims a refund for a total wipeout bounty.
     * @param bountyId The ID of the bounty.
     */
    function claimRefund(uint256 bountyId) external nonReentrant {
        Bounty storage bounty = _bounties[bountyId];
        require(_msgSender() == bounty.creator, "BountyManager: not creator");
        require(bounty.state == BountyState.Settled, "BountyManager: not Settled");
        require(isTotalWipeout[bountyId] || isInvalidated[bountyId], "BountyManager: not total wipeout or invalidated");
        require(!sponsorRefundClaimed[bountyId], "BountyManager: refund already claimed");

        sponsorRefundClaimed[bountyId] = true;

        for (uint256 i = 0; i < bounty.prizes.length; i++) {
            BountyPrize storage prize = bounty.prizes[i];
            uint256 amountToRefund = prize.totalDeposited - prize.distributed;
            if (amountToRefund > 0) {
                prize.refunded += amountToRefund;
                IERC20(prize.token).safeTransfer(_msgSender(), amountToRefund);
                emit SponsorRefundClaimed(bountyId, _msgSender(), prize.token, amountToRefund);
            }
        }
    }

    /**
     * @notice Marks a bounty as total wipeout.
     * @param bountyId The ID of the bounty.
     */
    function markTotalWipeout(uint256 bountyId) external onlyRole(PREDICTION_ENGINE_ROLE) {
        isTotalWipeout[bountyId] = true;
    }

    /**
     * @notice Internal helper to transition bounty states with valid-transition matrix.
     * @param bountyId The ID of the bounty.
     * @param newState The new state to transition to.
     */
    function _transitionState(uint256 bountyId, BountyState newState) internal {
        Bounty storage bounty = _bounties[bountyId];
        BountyState currentState = bounty.state;
        
        bool valid = false;
        if (currentState == BountyState.Active) {
            valid = (newState == BountyState.Closed || newState == BountyState.Cancelled);
        } else if (currentState == BountyState.Closed) {
            valid = (newState == BountyState.Resolved || newState == BountyState.Cancelled || newState == BountyState.Invalidated);
        } else if (currentState == BountyState.Resolved) {
            valid = (newState == BountyState.Settled);
        } else if (currentState == BountyState.Invalidated) {
            valid = (newState == BountyState.Settled);
        }

        require(valid, "BountyManager: invalid state transition");
        
        if (newState == BountyState.Invalidated) {
            isInvalidated[bountyId] = true;
        }

        bounty.state = newState;
        emit BountyStateChanged(bountyId, newState);
    }
    
    /**
     * @notice Updates bounty state from prediction engine.
     * @param bountyId The ID of the bounty.
     * @param newState The new state to transition to.
     */
    function updateBountyState(uint256 bountyId, BountyState newState) external onlyRole(PREDICTION_ENGINE_ROLE) {
        _transitionState(bountyId, newState);
    }

    function transferPrizesToEngine(uint256 bountyId) external onlyRole(PREDICTION_ENGINE_ROLE) {
        Bounty storage bounty = _bounties[bountyId];
        for (uint256 i = 0; i < bounty.prizes.length; i++) {
            BountyPrize storage prize = bounty.prizes[i];
            if (prize.totalDeposited > 0) {
                IERC20(prize.token).safeTransfer(msg.sender, prize.totalDeposited);
            }
        }
    }

    /**
     * @notice Returns bounty details.
     * @param bountyId The ID of the bounty.
     * @return The Bounty struct.
     */
    function getBounty(uint256 bountyId) external view returns (Bounty memory) {
        return _bounties[bountyId];
    }

    /**
     * @notice Returns bounty prizes.
     * @param bountyId The ID of the bounty.
     * @return Array of BountyPrize structs.
     */
    function getBountyPrizes(uint256 bountyId) external view returns (BountyPrize[] memory) {
        return _bounties[bountyId].prizes;
    }
}
