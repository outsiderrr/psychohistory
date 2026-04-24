// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {VeLock} from "../libraries/PsychohistoryTypes.sol";

interface IVePSYHStaking {
    event PSYHLocked(address indexed user, uint256 amount, uint64 lockDuration);
    event PSYHUnlocked(address indexed user, uint256 amount);
    event VePSYHDelegated(address indexed user, uint256 indexed bountyId, uint256 amount);
    event VePSYHUndelegated(address indexed user, uint256 indexed bountyId, uint256 amount);

    function lock(uint256 amount, uint64 lockDuration) external;
    function unlock() external;
    function delegate(address user, uint256 bountyId, uint256 amount) external;
    function undelegate(address user, uint256 bountyId, uint256 amount) external;

    function getVeLock(address user) external view returns (VeLock memory);
    function availableVePSYH(address user) external view returns (uint256);
}
