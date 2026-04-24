# Psychohistory V2 Testnet Deployment Checklist

## Prerequisites
- Configure `PRIVATE_KEY` in `.env`
- Configure RPC URL (e.g. `SEPOLIA_RPC_URL`) in `.env`
- Configure Etherscan API key for contract verification (`ETHERSCAN_API_KEY`)
- If Mock tokens are already deployed, configure `USDC_ADDRESS` and `PSYH_ADDRESS` in `.env`. Otherwise, the script will deploy them automatically.
- (Optional) Configure `ORACLE_ADDRESS`. If omitted, defaults to the deployer address.

## Deployment Steps
- [ ] Deploy mock USDC + PSYH tokens on Sepolia (Handled by the deploy script if env variables are empty)
- [ ] Deploy all contracts via `Deploy.s.sol`:
  ```bash
  forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
  ```
- [ ] Verify all contracts on Etherscan (Using `--verify` flag in the command above)
- [ ] Save deployed contract addresses for frontend config and backend oracle.

## Post-Deployment Smoke Tests

- [ ] **End-to-End Prediction Flow**
  - [ ] Approve `BountyManager` for USDC (sponsor).
  - [ ] Sponsor calls `BountyManager.createBounty` to create a categorical bounty and fund it.
  - [ ] Approve `PredictionEngine` for 10 USDC stake (predictor).
  - [ ] Predictor calls `PredictionEngine.submitPrediction` on the bounty.
  - [ ] Oracle multisig calls `PredictionEngine.resolve` with the correct outcome.
  - [ ] Anyone calls `PredictionEngine.settle(0, count)` to process predictors.
  - [ ] Predictor calls `PredictionEngine.claim` to pull their refund and bounty payout.

- [ ] **Treasury Verification**
  - [ ] Create a bounty, have at least one winning and one losing prediction.
  - [ ] Resolve and settle.
  - [ ] Verify the `Treasury` contract balance has increased by the slashed funds (10 USDC per loser).

- [ ] **Total Wipeout Scenario**
  - [ ] Create a categorical bounty.
  - [ ] Predictors submit predictions.
  - [ ] Resolve the bounty with an outcome that NO ONE predicted.
  - [ ] Settle all predictors (everyone loses).
  - [ ] Verify `PredictionEngine` sets `isTotalWipeout` to true.
  - [ ] Sponsor calls `BountyManager.claimRefund(bountyId)`.
  - [ ] Verify the sponsor receives their full bounty amount back.
  - [ ] Verify the slashed stakes are still sent to the Treasury.

- [ ] **Event Emission Verification**
  - [ ] Verify `BountyCreated` event on `BountyManager`.
  - [ ] Verify `PredictionSubmitted` event on `PredictionEngine`.
  - [ ] Verify `BountyResolved` event on `PredictionEngine`.
  - [ ] Verify `BountySettled` event on `PredictionEngine`.
  - [ ] Verify `BountyClaimed` event on `PredictionEngine`.
