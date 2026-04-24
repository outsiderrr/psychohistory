// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVePSYHStaking} from "../interfaces/IVePSYHStaking.sol";
import {VeLock} from "../libraries/PsychohistoryTypes.sol";
import {MIN_LOCK_DURATION, MAX_LOCK_DURATION} from "../libraries/Constants.sol";

/**
 * @title VePSYHStaking
 * @notice Handles $PSYH staking, vePSYH generation, and delegation to bounties.
 */
contract VePSYHStaking is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IVePSYHStaking {
    using SafeERC20 for IERC20;

    bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");

    IERC20 public psyhToken;
    mapping(address => VeLock) public veLocks;

    uint256[50] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the VePSYHStaking contract.
     * @param _psyhToken Address of the $PSYH token.
     * @param _admin Address to be granted the DEFAULT_ADMIN_ROLE.
     */
    function initialize(address _psyhToken, address _admin) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        require(_psyhToken != address(0), "VePSYHStaking: zero address psyhToken");
        require(_admin != address(0), "VePSYHStaking: zero address admin");

        psyhToken = IERC20(_psyhToken);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice Locks $PSYH to receive vePSYH.
     * @param amount The amount of $PSYH to lock.
     * @param lockDuration The duration to lock the $PSYH.
     */
    function lock(uint256 amount, uint64 lockDuration) external nonReentrant {
        require(amount > 0, "VePSYHStaking: amount must be > 0");
        require(lockDuration >= MIN_LOCK_DURATION, "VePSYHStaking: lock duration < MIN");
        require(lockDuration <= MAX_LOCK_DURATION, "VePSYHStaking: lock duration > MAX");
        require(veLocks[msg.sender].psyhAmount == 0, "VePSYHStaking: existing active lock");

        psyhToken.safeTransferFrom(msg.sender, address(this), amount);

        uint64 start = uint64(block.timestamp);
        uint64 end = start + lockDuration;

        veLocks[msg.sender] = VeLock({
            psyhAmount: amount,
            vePSYHMinted: amount, // 1:1 for V2
            lockStart: start,
            lockEnd: end,
            delegatedTotal: 0
        });

        emit PSYHLocked(msg.sender, amount, lockDuration);
    }

    /**
     * @notice Unlocks $PSYH and burns vePSYH.
     */
    function unlock() external nonReentrant {
        VeLock storage userLock = veLocks[msg.sender];
        require(userLock.psyhAmount > 0, "VePSYHStaking: no active lock");
        require(block.timestamp >= userLock.lockEnd, "VePSYHStaking: lock not expired");
        require(userLock.delegatedTotal == 0, "VePSYHStaking: active delegations");

        uint256 amountToReturn = userLock.psyhAmount;
        delete veLocks[msg.sender];

        psyhToken.safeTransfer(msg.sender, amountToReturn);

        emit PSYHUnlocked(msg.sender, amountToReturn);
    }

    /**
     * @notice Delegates vePSYH to a prediction.
     * @param user The address of the predictor.
     * @param bountyId The ID of the bounty.
     * @param amount The amount of vePSYH to delegate.
     */
    function delegate(address user, uint256 bountyId, uint256 amount) external onlyRole(DELEGATE_ROLE) {
        require(amount > 0, "VePSYHStaking: delegate amount must be > 0");
        require(availableVePSYH(user) >= amount, "VePSYHStaking: insufficient available vePSYH");

        veLocks[user].delegatedTotal += amount;

        emit VePSYHDelegated(user, bountyId, amount);
    }

    /**
     * @notice Undelegates vePSYH from a prediction.
     * @param user The address of the predictor.
     * @param bountyId The ID of the bounty.
     * @param amount The amount of vePSYH to undelegate.
     */
    function undelegate(address user, uint256 bountyId, uint256 amount) external onlyRole(DELEGATE_ROLE) {
        require(amount > 0, "VePSYHStaking: undelegate amount must be > 0");
        require(veLocks[user].delegatedTotal >= amount, "VePSYHStaking: delegated amount underflow");

        veLocks[user].delegatedTotal -= amount;

        emit VePSYHUndelegated(user, bountyId, amount);
    }

    /**
     * @notice Returns the available vePSYH for a user.
     * @param user The address of the user.
     * @return The available vePSYH.
     */
    function availableVePSYH(address user) public view returns (uint256) {
        VeLock storage userLock = veLocks[user];
        if (userLock.vePSYHMinted >= userLock.delegatedTotal) {
            return userLock.vePSYHMinted - userLock.delegatedTotal;
        }
        return 0;
    }

    /**
     * @notice Gets the VeLock details for a user.
     * @param user The address of the user.
     * @return The VeLock details.
     */
    function getVeLock(address user) external view returns (VeLock memory) {
        return veLocks[user];
    }
}
