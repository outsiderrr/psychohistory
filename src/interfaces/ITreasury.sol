// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ITreasury {
    event SlashedFundsReceived(uint256 indexed bountyId, uint256 amount);
    event BuybackAndBurn(address indexed dexRouter, uint256 amountIn, uint256 amountOut);

    function receiveSlashedFunds(uint256 bountyId, uint256 amount) external;
    function buybackAndBurn(address dexRouter, bytes calldata swapData, uint256 minPSYOut) external;
}
