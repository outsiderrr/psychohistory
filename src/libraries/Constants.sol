// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

uint256 constant STAKE_FEE = 10e6;          // 10 USDC
uint256 constant WAD = 1e18;
uint256 constant BPS = 10_000;
uint256 constant MIN_BRIER = 1e12;          // floor to prevent div-by-zero
uint256 constant MAX_BRIER_SCORE = 2e18;    // theoretical max for any N
uint256 constant MAX_BOOST_WAD = 3e18;      // max vePSYH boost
uint256 constant MAX_BOOST_DELTA = 2e18;    // boost range: 1x–3x
uint256 constant MIN_LOCK_DURATION = 7 days;
uint256 constant MAX_LOCK_DURATION = 4 * 365 days;
uint256 constant DISPUTE_WINDOW = 24 hours;
uint256 constant SLASH_PERCENTILE_BPS = 5_000;  // bottom 50%
uint256 constant MAX_OPTIONS = 5;
uint256 constant MIN_OPTIONS = 2;
