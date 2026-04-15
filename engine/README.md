# Engine

**English** · [中文](./README_CN.md)

> The multi-agent orchestration and simulation engine for Psychohistory.
> **Status: planned, not yet implemented.** This directory currently contains only this README.

The engine module is the planned runtime layer where the Psychohistory scenario schema (defined in [`../skill/references/schema.md`](../skill/references/schema.md)) is actually *executed* against agent/relationship data to produce dynamic possibility trees. It is the programmatic counterpart to the Skill module.

## Why a Separate Engine

The Skill module (`../skill/`) defines the data model and the analytic methodology — it specifies *how* a human analyst or an AI assistant should generate a possibility tree from a scenario. It works today, in any AI chat environment, using only markdown prompts.

The Engine module will formalize the same process as actual code — a runtime that:

- Takes a validated Scenario object as input
- Runs the three-engine analysis programmatically
- Produces a structured possibility tree output
- Supports interactive fact injection and re-computation
- Enables advanced inference modes that are impractical to run by hand

## Planned Capabilities

### 1. Reverse Inference Mode

Given a target outcome (e.g. *"Will the Fed raise rates in Q4 2026?"*), trace backward through the agent/relationship state to identify which prerequisite events would meaningfully increase the probability of the target.

This is **not** the forward possibility tree reversed. It is a separate inference subsystem that shares the same underlying data (agents, relationships, hard constraints) but uses a different algorithm — it searches for necessary / sufficient condition chains rather than expanding possibility branches.

- **Input**: target event + current scenario state
- **Output**: ranked list of "precondition paths" — each path is a chain of prerequisite events that, if they occurred, would meaningfully shift the target event's likelihood
- **Algorithm sketch**: identify the target event's direct agent-decision dependencies → recursively trace each agent's `concession_triggers` and their upstream drivers → terminate when reaching observable events the user can monitor

### 2. Theory Validation Mode

Users can propose a theory about how the world works, and the engine tests it against both historical facts and forward predictions.

**The key insight**: in the Psychohistory data model, a theory is naturally expressed as *a perturbation to one or more agent cognitive frameworks*. Examples:

- *"The Fed's real goal is asset price protection, not inflation control"* → replace the Fed's `mental_models` with an alternative set
- *"Trump is effectively controlled by Peter Thiel through JD Vance"* → add a high-weight `concession_trigger` on Trump keyed to Vance's preferences, and supplement Trump's mental models
- *"There is a coordinating group among global elites"* → add a new hidden agent with influence relationships to other agents

This is why every character card already has an optional `alternative_frameworks` field — it is the structural hook for this mode.

**Validation procedure**:

1. Run the scenario twice — once with the standard agent frameworks, once with the theory-perturbed frameworks
2. Compare each run's explanatory power against observed historical events: which run "predicts" the real past better?
3. Compare each run's forward predictions: which future events would distinguish the two theories?
4. Output: a verdict on the theory's consistency with history + a list of upcoming events whose outcomes would differentiate the standard and theory-perturbed worldviews

### 3. Collective Agents as First-Class Causal Nodes

Collective agents (e.g. the MAGA base, global oil market participants) currently appear in the schema as variables *inside* entity agent decision functions. The engine will upgrade them: when any of their `observable_state` values (polling averages, market prices, sentiment indices, voting intentions) crosses a strategically relevant threshold, that state change is promoted to a first-class Event node on the possibility tree.

This gives group-driven causality (market panics, sentiment phase transitions, social cascades) explicit structural status — rather than hiding it inside individual entity decision functions, where it is hard to reason about independently.

The structural preparation for this is already in the schema: see the `observable_state` field on collective agents in [`../skill/references/schema.md`](../skill/references/schema.md) §2.3.

### 4. Automatic Research via API Integration

Replace the **Research Hand-off** copy-paste protocol (the current skill-stage mechanism for getting external research into card generation, see `../skill/character-toolkit/SKILL.md` §Step 3.1) with **direct API calls** to search-capable LLMs. Users will configure API keys once for their preferred providers, and the engine will route research requests automatically based on task type and content language:

- **Perplexity API** — default for English-language factual research with inline citations
- **OpenAI Search API** — general-purpose prompts
- **Gemini API (Deep Research mode)** — for deep multi-step investigations
- **Claude API with web search** — for synthesis-heavy tasks
- **Kimi / 豆包 / 元宝 APIs (when available)** — for Chinese-language content

**Research Hand-off will be preserved as a fallback**, specifically for:

- Users who don't want to configure API keys (skill-stage workflow continues unchanged)
- Use cases where a chat UI has features not exposed via API (some products still have this asymmetry)
- API errors, quota exhaustion, or rate limits — graceful degradation to copy-paste
- Compliance scenarios where API usage is restricted but chat-UI is permitted

Unlike capabilities 1-3 (which are new analytical modes), this is **a plumbing upgrade** — it doesn't change what the system can reason about, only how efficiently it gets the raw material. The skill-stage design is fully compatible with engine-stage operation: the same `prompt-0X` Research Hand-off Templates can be repurposed as API call payloads with minor adaptation.

## What's NOT Planned

The engine is intentionally scoped to keep it honest. The following directions have been considered and declined at the current stage:

- **Precise probability quantification to percentage precision.** Requires a calibration loop with tracked predictions and outcomes, which we do not have. Ordinal ranking with transparent rationale is more honest.
- **Prediction-outcome sample collection infrastructure.** Prerequisite for probabilistic calibration — same reason.
- **External prediction-market data integration.** Tempting because our Events already use Polymarket-style binary propositions, but introduces dependencies we do not want at the current stage.

These decisions may be revisited if the project reaches a much later stage with real users and an accumulated prediction track record. For now, **Psychohistory is a structured reasoning tool, not a probability estimator.**

## Status

- [ ] Architecture design
- [ ] Minimum viable runtime (takes a Scenario JSON, runs three-engine analysis, outputs a possibility tree)
- [ ] Reverse inference mode
- [ ] Theory validation mode
- [ ] Collective `observable_state` event promotion
- [ ] Automatic research via API integration (with Research Hand-off preserved as fallback)
- [ ] Integration tests against the Skill module's example scenarios
