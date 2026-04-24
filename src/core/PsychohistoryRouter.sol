// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBountyManager} from "../interfaces/IBountyManager.sol";
import {IPredictionEngine} from "../interfaces/IPredictionEngine.sol";
import {PredictionType} from "../libraries/PsychohistoryTypes.sol";

/**
 * @title PsychohistoryRouter
 * @notice Thin facade for atomic multi-step operations like create + predict, or predict + boost.
 */
contract PsychohistoryRouter is Initializable, ContextUpgradeable {
    using SafeERC20 for IERC20;

    IBountyManager public bountyManager;
    IPredictionEngine public predictionEngine;
    IERC20 public usdc;

    uint256[50] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the Router.
     * @param _bountyManager Address of BountyManager.
     * @param _predictionEngine Address of PredictionEngine.
     * @param _usdc Address of USDC token.
     */
    function initialize(
        address _bountyManager,
        address _predictionEngine,
        address _usdc
    ) external initializer {
        __Context_init_unchained();
        require(_bountyManager != address(0), "Router: zero address BM");
        require(_predictionEngine != address(0), "Router: zero address PE");
        require(_usdc != address(0), "Router: zero address USDC");

        bountyManager = IBountyManager(_bountyManager);
        predictionEngine = IPredictionEngine(_predictionEngine);
        usdc = IERC20(_usdc);
    }

    /**
     * @notice Atomically creates a bounty and submits the first prediction.
     */
    function createBountyAndPredict(
        PredictionType predictionType,
        uint8 optionsCount,
        string calldata metadataURI,
        uint64 closeTimestamp,
        uint64 resolutionDeadline,
        address prizeToken,
        uint256 prizeAmount,
        uint256 selectedOption,
        uint256[] calldata confidenceBpsArray,
        uint256 predictedValue,
        uint8 predictedDecimals
    ) external returns (uint256 bountyId) {
        bytes memory createData = abi.encodeWithSelector(
            bountyManager.createBounty.selector,
            predictionType,
            optionsCount,
            metadataURI,
            closeTimestamp,
            resolutionDeadline,
            prizeToken,
            prizeAmount
        );
        bytes memory createCallData = abi.encodePacked(createData, msg.sender);
        (bool success1, bytes memory returnData) = address(bountyManager).call(createCallData);
        if (!success1) {
            _revert(returnData);
        }
        bountyId = abi.decode(returnData, (uint256));

        bytes memory predictData = abi.encodeWithSelector(
            predictionEngine.submitPrediction.selector,
            bountyId,
            selectedOption,
            confidenceBpsArray,
            predictedValue,
            predictedDecimals
        );
        bytes memory predictCallData = abi.encodePacked(predictData, msg.sender);
        (bool success2, bytes memory returnData2) = address(predictionEngine).call(predictCallData);
        if (!success2) {
            _revert(returnData2);
        }
    }

    /**
     * @notice Atomically submits a prediction and delegates vePSYH for a boost.
     */
    function submitPredictionWithBoost(
        uint256 bountyId,
        uint256 selectedOption,
        uint256[] calldata confidenceBpsArray,
        uint256 predictedValue,
        uint8 predictedDecimals,
        uint256 vePSYHAmount
    ) external {
        bytes memory predictData = abi.encodeWithSelector(
            predictionEngine.submitPrediction.selector,
            bountyId,
            selectedOption,
            confidenceBpsArray,
            predictedValue,
            predictedDecimals
        );
        bytes memory predictCallData = abi.encodePacked(predictData, msg.sender);
        (bool success1, bytes memory returnData1) = address(predictionEngine).call(predictCallData);
        if (!success1) {
            _revert(returnData1);
        }

        bytes memory delegateData = abi.encodeWithSelector(
            predictionEngine.delegateVePSYH.selector,
            bountyId,
            vePSYHAmount
        );
        bytes memory delegateCallData = abi.encodePacked(delegateData, msg.sender);
        (bool success2, bytes memory returnData2) = address(predictionEngine).call(delegateCallData);
        if (!success2) {
            _revert(returnData2);
        }
    }

    /**
     * @notice Reverts with the original error from a low-level call.
     */
    function _revert(bytes memory returnData) internal pure {
        if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert("Router: low-level call failed");
        }
    }
}
