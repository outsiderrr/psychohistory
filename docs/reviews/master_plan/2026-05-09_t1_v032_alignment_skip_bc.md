# Skip-BC: T-1.1 / STAGE_1_TASKS V0.32 alignment

**Date**: 2026-05-09
**Category**: ① R-class follow-up (governance §5) — mechanical content sync of V0.31 references to V0.32 after L2-T0.D ratified V0.32 in commit `48f7f0e`.

**Files touched**:
- `docs/STAGE_1_TASKS.md` — T-1.2 / T-1.3 preview "Notable elements" sections: header `(from TDD V0.31 §X)` → `(from TDD V0.32 §X)`; added `int256 predictedValue/resolvedValue` (ADR-0009), `tvlCap` + `MAX_BOUNTY_TVL_CAP_DEFAULT` (ADR-0011), `CumulativeBrierStats` struct (ADR-0010), `ScheduledWithdrawal` time-lock primitives (ADR-0013), `whenNotPaused` gating + `Paused/Unpaused` events (ADR-0012), `getForecasterStats / getForecasterAverageScore / getForecasterWinRate` views (ADR-0010), and `BountyTvlCapExceeded` error / `createBounty(tvlCap)` parameter (ADR-0011).
- `docs/prompts/stage_1/T-1.1.md` — 6 V0.31 → V0.32 reference updates (required reading TDD ref, ADR range 0001–0005 → 0001–0014 with brief V0.32 ADR summary, README template, commit message template `Refs:` line, commit message template README description line, PR body `## Spec refs` section). One mention of "V0.31 is archived" intentionally preserved as an explanatory archive note.

**Why skip BC**: L1/L2 integration planner self-maintaining its own outputs (`STAGE_X_TASKS.md` + paste-ready prompts) after a TDD revision lock is mechanical content sync — not new design content. T-1.1 acceptance criteria are unchanged: it remains scaffolding-only (forge init + OZ v5 submodules + directory layout + foundry.toml + remappings.txt). V0.32 §2's new `Emergency pause` paragraph (ADR-0012 / `PausableUpgradeable` inheritance) is load-bearing for T1.2 / T1.3 and downstream contracts, but does not affect a scaffolding-only L3.

**Approver**: L1 master planning conversation (this conversation, branch `claude/elated-jepsen-43e752`).
