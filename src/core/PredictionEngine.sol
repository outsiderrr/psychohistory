// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IPredictionEngine} from "../interfaces/IPredictionEngine.sol";
import {IBountyManager} from "../interfaces/IBountyManager.sol";
import {IVePSYHStaking} from "../interfaces/IVePSYHStaking.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";
import {Prediction, SettlementState, Bounty, BountyState, PredictionType, BountyPrize} from "../libraries/PsychohistoryTypes.sol";
import {STAKE_FEE, BPS, WAD, MIN_BRIER, MAX_BOOST_WAD, MAX_BOOST_DELTA, SLASH_PERCENTILE_BPS} from "../libraries/Constants.sol";
import {BrierMath} from "../libraries/BrierMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract PredictionEngine is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IPredictionEngine {
    using SafeERC20 for IERC20;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    IBountyManager public bountyManager;
    IVePSYHStaking public vePSYH;
    ITreasury public treasury;
    IERC20 public usdc;

    mapping(uint256 => address[]) public predictorsByBounty;
    mapping(uint256 => mapping(address => Prediction)) public predictions;
    mapping(uint256 => mapping(address => bool)) public hasPredicted;
    mapping(uint256 => mapping(address => uint256[])) public confidenceArrays;
    mapping(uint256 => SettlementState) public settlements;
    mapping(uint256 => mapping(address => mapping(address => uint256))) public payoutsByToken;

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

    error InvalidMedianError();
    error AlreadyPredicted();
    error BountyNotActive();
    error BountyClosed();
    error BountyNotClosed();
    error ResolutionDeadlinePassed();
    error InvalidOption();
    error InvalidArrayLength();
    error InvalidConfidenceSum();
    error InvalidPrediction();
    error NotOracle();
    error AlreadyResolved();
    error NotResolved();
    error InvalidSettlementIndex();
    error AlreadySettled();
    error NotSettled();
    error NotWinner();
    error AlreadyClaimed();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _bountyManager,
        address _vePSYH,
        address _treasury,
        address _usdc,
        address _admin
    ) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        bountyManager = IBountyManager(_bountyManager);
        vePSYH = IVePSYHStaking(_vePSYH);
        treasury = ITreasury(_treasury);
        usdc = IERC20(_usdc);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function submitPrediction(
        uint256 bountyId,
        uint256 selectedOption,
        uint256[] calldata confidenceBpsArray,
        uint256 predictedValue,
        uint8 predictedDecimals
    ) external nonReentrant {
        Bounty memory bounty = bountyManager.getBounty(bountyId);
        if (bounty.state != BountyState.Active) revert BountyNotActive();
        if (block.timestamp >= bounty.closeTimestamp) revert BountyClosed();
        if (hasPredicted[bountyId][_msgSender()]) revert AlreadyPredicted();

        if (bounty.predictionType == PredictionType.Categorical) {
            if (selectedOption >= bounty.optionsCount) revert InvalidOption();
            if (confidenceBpsArray.length != bounty.optionsCount) revert InvalidArrayLength();
            
            uint256 sum = 0;
            for (uint256 i = 0; i < confidenceBpsArray.length; i++) {
                if (confidenceBpsArray[i] > BPS) revert InvalidPrediction();
                sum += confidenceBpsArray[i];
            }
            if (sum != BPS) revert InvalidConfidenceSum();
            if (predictedValue != 0 || predictedDecimals != 0) revert InvalidPrediction();
            
            confidenceArrays[bountyId][_msgSender()] = confidenceBpsArray;
        } else {
            if (confidenceBpsArray.length != 0) revert InvalidArrayLength();
            if (selectedOption != 0) revert InvalidOption();
            if (predictedDecimals > 18) revert InvalidPrediction();
        }

        hasPredicted[bountyId][_msgSender()] = true;
        predictorsByBounty[bountyId].push(_msgSender());

        Prediction storage pred = predictions[bountyId][_msgSender()];
        pred.predictor = _msgSender();
        pred.bountyId = bountyId;
        pred.selectedOption = selectedOption;
        pred.predictedValue = predictedValue;
        pred.predictedDecimals = predictedDecimals;
        pred.stakeAmount = STAKE_FEE;

        usdc.safeTransferFrom(_msgSender(), address(this), STAKE_FEE);

        emit PredictionSubmitted(bountyId, _msgSender(), selectedOption, predictedValue);
    }

    function delegateVePSYH(uint256 bountyId, uint256 vePSYHAmount) external nonReentrant {
        if (!hasPredicted[bountyId][_msgSender()]) revert InvalidPrediction();
        Bounty memory bounty = bountyManager.getBounty(bountyId);
        if (bounty.state != BountyState.Active) revert BountyNotActive();

        vePSYH.delegate(_msgSender(), bountyId, vePSYHAmount);
        
        predictions[bountyId][_msgSender()].vePSYHDelegated += vePSYHAmount;
    }

    function resolve(
        uint256 bountyId,
        uint256 resolvedValue,
        uint8 resolvedDecimals,
        uint256 medianError
    ) external nonReentrant onlyRole(ORACLE_ROLE) {
        Bounty memory bounty = bountyManager.getBounty(bountyId);
        if (bounty.state != BountyState.Closed) revert BountyNotClosed();
        if (block.timestamp > bounty.resolutionDeadline) revert ResolutionDeadlinePassed();
        
        SettlementState storage sState = settlements[bountyId];
        if (sState.resolved) revert AlreadyResolved();

        if (bounty.predictionType == PredictionType.Categorical) {
            if (resolvedValue >= bounty.optionsCount) revert InvalidOption();
        } else {
            address[] memory predictors = predictorsByBounty[bountyId];
            uint256 n = predictors.length;
            if (n > 0) {
                uint256 countBelow = 0;
                uint256 countEqual = 0;
                uint256 resolvedWad = resolvedValue * (10 ** (18 - resolvedDecimals));
                
                for (uint256 i = 0; i < n; i++) {
                    Prediction memory pred = predictions[bountyId][predictors[i]];
                    uint256 predictedWad = pred.predictedValue * (10 ** (18 - pred.predictedDecimals));
                    uint256 err = BrierMath.computeAbsoluteError(predictedWad, resolvedWad);
                    
                    if (err < medianError) {
                        countBelow++;
                    } else if (err == medianError) {
                        countEqual++;
                    }
                }
                
                uint256 ceilHalf = (n + 1) / 2;
                if (countBelow > n / 2 || (countBelow + countEqual) < ceilHalf) {
                    revert InvalidMedianError();
                }
            }
        }

        sState.resolved = true;
        sState.resolvedValue = resolvedValue;
        sState.resolvedDecimals = resolvedDecimals;
        sState.medianError = medianError;

        bountyManager.updateBountyState(bountyId, BountyState.Resolved);

        emit PredictionResolved(bountyId, resolvedValue, resolvedDecimals, medianError);
    }

    function resolveAsInvalid(uint256 bountyId) external onlyRole(ORACLE_ROLE) nonReentrant {
        Bounty memory bounty = bountyManager.getBounty(bountyId);

        // Must be in Closed state (prediction window ended, awaiting resolution)
        if (bounty.state != BountyState.Closed) revert BountyNotClosed();
        if (block.timestamp > bounty.resolutionDeadline) revert ResolutionDeadlinePassed();

        // Store settlement state — mark as invalidated, NOT resolved
        SettlementState storage ss = settlements[bountyId];
        if (ss.resolved) revert AlreadyResolved();
        
        ss.resolved = true;           // allows settle() to proceed
        ss.isTotalWipeout = false;    // NOT a wipeout — no slashing at all
        // Add a new flag:
        ss.isInvalidated = true;

        // Transition bounty state
        bountyManager.updateBountyState(bountyId, BountyState.Invalidated);

        emit BountyInvalidated(bountyId);
    }

    function settle(uint256 bountyId, uint256 startIndex, uint256 endIndex) external nonReentrant {
        SettlementState storage sState = settlements[bountyId];
        if (!sState.resolved) revert NotResolved();
        if (sState.fullySettled) revert AlreadySettled();
        if (startIndex != sState.settledUpTo) revert InvalidSettlementIndex();
        
        address[] memory predictors = predictorsByBounty[bountyId];
        uint256 length = predictors.length;
        if (endIndex > length) endIndex = length;

        if (sState.isInvalidated) {
            // INVALIDATED PATH: refund ALL predictors, no slashing, no Brier math
            for (uint256 i = startIndex; i < endIndex; i++) {
                address predictor = predictors[i];
                Prediction storage pred = predictions[bountyId][predictor];

                // Refund stake — no slashing
                pred.refunded = true;
                pred.slashed = false;
                // (stake refund happens in claim())

                // Release vePSYH delegation if any
                if (pred.vePSYHDelegated > 0) {
                    vePSYH.undelegate(predictor, bountyId, pred.vePSYHDelegated);
                }
            }

            sState.settledUpTo = endIndex;

            if (endIndex == length) {
                sState.fullySettled = true;
                // Sponsor can now call claimRefund() on BountyManager
                // No bounty distribution — no winners or losers
                bountyManager.updateBountyState(bountyId, BountyState.Settled);
            }
            return;  // skip all normal settlement logic
        }

        Bounty memory bounty = bountyManager.getBounty(bountyId);
        uint256 slashedTotal = 0;
        
        uint256 targetWinners = (length + 1) / 2; // only used for Numerical

        for (uint256 i = startIndex; i < endIndex; i++) {
            address predictor = predictors[i];
            Prediction storage pred = predictions[bountyId][predictor];
            
            bool isWinner = false;
            if (bounty.predictionType == PredictionType.Categorical) {
                if (pred.selectedOption == sState.resolvedValue) {
                    isWinner = true;
                }
            } else {
                uint256 predictedWad = pred.predictedValue * (10 ** (18 - pred.predictedDecimals));
                uint256 resolvedWad = sState.resolvedValue * (10 ** (18 - sState.resolvedDecimals));
                uint256 err = BrierMath.computeAbsoluteError(predictedWad, resolvedWad);
                
                if (err <= sState.medianError && sState.winnersCount < targetWinners) {
                    isWinner = true;
                }
            }
            
            if (isWinner) {
                pred.refunded = true;
                sState.winnersCount++;
            } else {
                pred.slashed = true;
                sState.slashedCount++;
                slashedTotal += STAKE_FEE;
                emit StakeSlashed(bountyId, predictor, STAKE_FEE);
            }
        }
        
        if (slashedTotal > 0) {
            usdc.safeIncreaseAllowance(address(treasury), slashedTotal);
            treasury.receiveSlashedFunds(bountyId, slashedTotal);
        }

        sState.settledUpTo = endIndex;

        if (endIndex == length) {
            sState.fullySettled = true;
            bountyManager.updateBountyState(bountyId, BountyState.Settled);
            
            if (sState.winnersCount == 0 && bounty.predictionType == PredictionType.Categorical) {
                sState.isTotalWipeout = true;
                bountyManager.markTotalWipeout(bountyId);
                emit TotalWipeout(bountyId);
            } else if (sState.winnersCount > 0) {
                _distributeBounty(bountyId, bounty);
            }
            
            // Release all vePSYH delegations
            for (uint256 i = 0; i < length; i++) {
                Prediction memory pred = predictions[bountyId][predictors[i]];
                if (pred.vePSYHDelegated > 0) {
                    vePSYH.undelegate(pred.predictor, bountyId, pred.vePSYHDelegated);
                }
            }
        }
    }

    function _distributeBounty(uint256 bountyId, Bounty memory bounty) internal {
        bountyManager.transferPrizesToEngine(bountyId);
        
        uint256 length = predictorsByBounty[bountyId].length;
        
        uint256[] memory boostedWeights = new uint256[](length);
        uint256 totalBoostedWeight = 0;
        
        uint256 boostDenominator = 0;
        for (uint256 i = 0; i < length; i++) {
            Prediction memory pred = predictions[bountyId][predictorsByBounty[bountyId][i]];
            if (pred.refunded && pred.vePSYHDelegated > boostDenominator) {
                boostDenominator = pred.vePSYHDelegated;
            }
        }

        for (uint256 i = 0; i < length; i++) {
            address predictor = predictorsByBounty[bountyId][i];
            Prediction memory pred = predictions[bountyId][predictor];
            if (!pred.refunded) continue;
            
            uint256 inverseWeight;
            if (bounty.predictionType == PredictionType.Categorical) {
                uint256[] memory bpsArray = confidenceArrays[bountyId][predictor];
                uint256[] memory wadArray = new uint256[](bpsArray.length);
                for (uint256 j = 0; j < bpsArray.length; j++) {
                    wadArray[j] = (bpsArray[j] * WAD) / BPS;
                }
                uint256 bs = BrierMath.computeCategoricalBrierScore(wadArray, settlements[bountyId].resolvedValue);
                inverseWeight = BrierMath.computeInverseWeight(bs);
            } else {
                uint256 predictedWad = pred.predictedValue * (10 ** (18 - pred.predictedDecimals));
                uint256 resolvedWad = settlements[bountyId].resolvedValue * (10 ** (18 - settlements[bountyId].resolvedDecimals));
                inverseWeight = BrierMath.computeInverseWeight(BrierMath.computeAbsoluteError(predictedWad, resolvedWad));
            }
            
            uint256 boost = BrierMath.computeBoost(pred.vePSYHDelegated, boostDenominator);
            uint256 bw = (inverseWeight * boost) / WAD;
            boostedWeights[i] = bw;
            totalBoostedWeight += bw;
        }
        
        BountyPrize[] memory prizes = bountyManager.getBountyPrizes(bountyId);
        
        for (uint256 i = 0; i < length; i++) {
            address predictor = predictorsByBounty[bountyId][i];
            if (!predictions[bountyId][predictor].refunded) continue;
            
            uint256 bw = boostedWeights[i];
            for (uint256 p = 0; p < prizes.length; p++) {
                uint256 payout = BrierMath.computePayout(bw, totalBoostedWeight, prizes[p].totalDeposited);
                if (payout > 0) {
                    payoutsByToken[bountyId][predictor][prizes[p].token] = payout;
                    emit BountyDistributed(bountyId, predictor, payout);
                }
            }
        }
    }

    function claim(uint256 bountyId) external nonReentrant {
        SettlementState storage sState = settlements[bountyId];
        if (!sState.fullySettled) revert NotSettled();
        
        Prediction storage pred = predictions[bountyId][_msgSender()];
        if (!pred.refunded) revert NotWinner();
        
        uint256 totalPayout = STAKE_FEE;
        pred.refunded = false; // Use refunded as a reentrancy guard for STAKE_FEE
        
        BountyPrize[] memory prizes = bountyManager.getBountyPrizes(bountyId);
        for (uint256 i = 0; i < prizes.length; i++) {
            address token = prizes[i].token;
            uint256 payout = payoutsByToken[bountyId][_msgSender()][token];
            if (payout > 0) {
                payoutsByToken[bountyId][_msgSender()][token] = 0;
                IERC20(token).safeTransfer(_msgSender(), payout);
            }
        }
        
        usdc.safeTransfer(_msgSender(), totalPayout);
        emit StakeRefunded(bountyId, _msgSender(), totalPayout);
    }

    function getPrediction(uint256 bountyId, address predictor) external view returns (Prediction memory) {
        return predictions[bountyId][predictor];
    }

    function getPredictorCount(uint256 bountyId) external view returns (uint256) {
        return predictorsByBounty[bountyId].length;
    }
}
