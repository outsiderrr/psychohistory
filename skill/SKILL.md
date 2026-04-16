---
name: psychohistory
description: "Psychohistory: Macro event scenario analysis and possibility tree engine. Input any unfolding complex event (geopolitical conflicts, policy games, business competition, etc.), output structured multi-agent game-theoretic analysis and a ranked possibility tree. Triggers: 'scenario analysis', 'analyze the situation', 'possibility tree', 'game theory analysis', 'war game', 'what if', 'how will this play out'. Use this skill whenever the user mentions any ongoing geopolitical, macroeconomic, or business competition event and wants to explore possible outcomes."
---

# Psychohistory · Macro Event Scenario Engine

> Not a crystal ball — a structured thinking tool. Helps you enumerate key variables, causal chains, and possible branches to avoid blind spots.

## Core Philosophy

Psychohistory does not predict the future. It does the following:
1. **Identify Key Agents** — Who makes decisions? Who influences decision-makers?
2. **Map Hard Constraints** — What are the immovable physical and institutional boundaries?
3. **Three-Engine Analysis** — How do game theory, psychological models, and organizational behavior each read the situation?
4. **Generate Possibility Tree** — What are the mutually exclusive possible outcomes? Rank them by likelihood.
5. **Accept User Input** — Users can add new options, modify agent profiles, inject new information, or run hypothetical simulations.

**Reference documents:**
- `references/schema.md` — Full data structure definitions (JSON field specs and examples)
- `references/character-schema.md` — Character card JSON schema and validation rules
- `characters/` — Official pre-built character cards

---

## Environment Detection

Psychohistory operates in two distinct environments. Detect which one you are in **before** executing any analysis.

### CLI Environment
You are in CLI mode if ANY of the following are true:
- You have filesystem access (can read/write files, run shell commands)
- You are running inside Claude Code, OpenClaw, Manus, or similar agent frameworks
- You can execute subprocess commands

### Chat Environment
You are in Chat mode if:
- You are running in a web-based conversational interface (Claude.ai, ChatGPT, Gemini, etc.)
- You have no filesystem access
- The user pasted the SKILL.md content directly into the conversation

**The environment determines the fallback path for missing character cards (see Phase 1.5).**

---

## Execution Flow

### Phase 0: Understand Requirements (1 minute)

After receiving user input, confirm:

1. **What is the event**: The specific ongoing event or situation
2. **Time horizon**: How far out should the analysis look? (Two weeks? Three months? A year?)
3. **Focus area**: Which aspect does the user care most about? (Military? Economic? Diplomatic?)
4. **Depth**: Quick overview (1 core question + 3-5 branches) or deep analysis (multi-layer nested tree)?

If the user says "analyze X situation" with sufficient context → default to medium depth, proceed directly to Phase 1.

---

### Phase 1: Information Gathering

**Search for the latest developments on the event.** This step is critical — analysis must be based on current facts, not outdated information.

Information dimensions to gather:
- Latest status and timeline of the event
- Latest statements and actions by all parties
- Key numbers and facts (military force comparison, economic data, polls, etc.)
- Known points of disagreement and consensus

**Source priority**: Official statements > Authoritative media reports > Commentary and analysis

After gathering, briefly report the current situation to the user. Confirm understanding is correct before proceeding to Phase 1.5.

---

### Phase 1.5: Character Card Loading (Router)

After identifying the key figures in the scenario, load their character cards using the following **three-tier priority system**:

#### Tier 1: Official Library Lookup (All Environments)

Check the `characters/` directory for a matching `{agent_id}.json` file.

```
IF characters/{agent_id}.json EXISTS:
  → Load the JSON file
  → Validate against character-schema (see references/character-schema.md)
  → If valid: use as agent's cognitive framework
  → If invalid: log warning, fall through to Tier 2
```

**Currently available official cards:** `trump.json` (more to be added)

#### Tier 2: CLI Auto-Generation via character-toolkit (CLI Environment Only)

If no official card exists AND you are in CLI environment, delegate to the character-toolkit skill:

```
IF environment == CLI:
  → Invoke psychohistory-character-toolkit (skill/character-toolkit/SKILL.md)
  → Pass: target agent name, current scenario context, any known source URLs
  → character-toolkit will:
    - Route to the appropriate phase-based prompt
      (prompt-01 for personal, prompt-02 for organization, prompt-03 for collective)
    - For personal entities, prompt-01 internally invokes Nuwa.skill as its
      Phase 1 cognitive distillation step
    - Run the full phase-based flow (references.md as primary artifact,
      JSON as compressed index, Python jsonschema validation)
    - Save outputs to skill/characters/psychohistory/[agent_id].{json,references.md}
  → If character-toolkit terminates with a prerequisite error:
    - Report what's missing specifically (missing Nuwa, missing recent data,
      missing endpoint card for a relationship, etc.)
    - Either retry with the missing input, or fall through to Tier 3
```

Note: Nuwa is no longer invoked directly from this router. It is now a sub-step of prompt-01-personal-entity.md Phase 1 inside character-toolkit. This gives personal-entity cards the same phase-based methodology (references.md primary, strength grading, type-specific honesty_boundaries disclaimers) as organization and collective cards.

#### Tier 3: Export Mode / User-Provided (Chat Environment or Final Fallback)

If in Chat environment OR CLI Tier 2 failed irrecoverably, offer the user the following options in order of preference:

**Option A (recommended, CLI available): character-toolkit Export Mode**

From CLI, invoke `psychohistory-character-toolkit` in Export Mode. It will generate a self-contained prompt the user can paste into their preferred chat AI (ChatGPT, Claude.ai, Trae, Gemini, etc.). Once the chat AI produces output, the user returns to CLI with the references.md + JSON content, and character-toolkit validates and saves them to the canonical paths.

Instruct user: *"I'll generate an export prompt for [target]. Paste it into your preferred AI, receive the references.md + JSON output, then paste both back here so I can validate and save them."*

**Option B: Paste an existing card**

If the user already has a pre-generated JSON card (from community, previous Nuwa run, or their own prior work), they can paste it directly. Validate against character-schema v1.1. On validation failure, show specific errors and offer Option A or C.

**Option C: Describe in natural language**

If the user wants minimal effort and Options A and B are unavailable, describe the agent's characteristics in natural language (thinking style, decision patterns, core values, blind spots). Construct a `system-derived` card from the description. Tag `source: system-derived`. Warn that this produces a shallow card suitable only for low-stakes analysis — upgrade via Option A or B before serious use.

**Option D: Proceed without a card**

Analyze the agent based on publicly known information without a formal card. All reasoning about this agent is tagged `source: system-derived`. The modeling will be shallower; use only for low-stakes or illustrative scenarios.

#### Validation Gate

**ALL character cards, regardless of origin, must pass validation before use.**

Validation checks (see `references/character-schema.md` for full spec):
1. `card_version` must be `"1.0"`
2. `agent_id` must be lowercase alphanumeric + hyphens
3. `mental_models` must have 2-10 items, each with `id`, `name`, `description` (min 20 chars)
4. `decision_heuristics` must have 2-12 items
5. `concession_triggers` must have at least 1 item
6. `red_lines` must have at least 1 item
7. `honesty_boundaries` must have at least 1 item

If validation fails, output specific errors and request correction.

---

### Phase 2: Agent Identification and Modeling

#### 2.1 Identify Entity Agents

Core question: **Who has independent decision-making power in this event?**

For each entity agent, load their character card (Phase 1.5) and output:
- **Identity**: Name, position, faction
- **Core objectives**: What do they want in this event?
- **Cognitive framework**: Loaded from character card. Tag source: `official` / `nuwa-skill` / `user` / `system-derived`
- **Concession triggers**: From character card, with `current_status` updated for this specific scenario
- **Red lines**: From character card

#### 2.2 Identify Agent Relationships

For agents within the same faction, assess loyalty relationships:
- **Current mode**: Loyal mode (can be represented) or independent mode (acting autonomously)?
- **Loyalty risk**: What events could trigger a mode switch?

#### 2.3 Identify Collective Agents (on demand)

**Only model a collective when it explicitly appears as a variable in an entity agent's decision function.**

For each collective agent, output a four-layer profile:
- **Core interest list** (ranked by priority)
- **Current disposition** (support/oppose/neutral on specific issue, plus intensity)
- **Sensitivity map** (what types of events would significantly shift their disposition)
- **Influence pathway** (through what mechanism do they affect entity agents)

---

### Phase 3: Hard Constraint Mapping

Identify objective conditions that no agent can violate:

- **Geographical**: Immutable geographic realities (strait locations, distances, terrain)
- **Military**: Weapons stockpiles, force deployments, supply lines
- **Economic**: Resource dependencies, sanctions effects, market tolerance
- **Institutional**: International law, treaty obligations, domestic legal procedures
- **Temporal**: Election cycles, agreement expiration dates, seasonal factors

For each constraint, note its **cascading effects** — how does it impact other variables?

---

### Phase 4: Three-Engine Analysis

**Read `three-engine/SKILL.md`** using the Read tool and apply its [GT] / [PSY] / [ORG] framework to the agents identified in Phase 2, under the constraints mapped in Phase 3.

- For each agent with a loaded character card (Phase 1.5), pass the card to the [PSY] engine so it uses the agent's `mental_models`, `decision_heuristics`, and `known_biases`
- For agents without cards, the [PSY] engine works from publicly known behavior patterns
- Tag every reasoning line with its engine source: `[GT]`, `[PSY]`, or `[ORG]`
- Note where engines converge (high-confidence insight) and where they disagree (genuine uncertainty)

The Three-Engine Analysis skill handles: the full analytical methodology, historical precedent priority rules, output format standards, and quality checks. See `three-engine/SKILL.md` for the complete framework.

---

### Phase 5: Generate Possibility Tree

#### 5.1 Define the Root Node

Express the core question as a **Polymarket-style precise proposition** satisfying four requirements:
1. Binary outcome (yes/no)
2. Based on publicly verifiable facts
3. Clear time window
4. Precise description with objective judgment criteria

#### 5.2 List Mutually Exclusive Branches

For the root node, list all reasonable mutually exclusive possibilities (typically 3-5), ranked from most to least likely (`likelihood_rank`).

Each branch contains:
- **Outcome description**
- **Resolution horizon** — the time scale in which this branch would be resolved (e.g. `short` for days, `medium` for 2-6 weeks, `long` for months, `strategic` for 6+ months). Branches with radically different horizons answer different questions and should not be ranked against each other directly
- **Ranking position** (rank 1 = most likely, within the same resolution horizon)
- **Ranking rationale** (tagged by engine: [GT] / [PSY] / [ORG], with historical precedents where applicable)
- **Next-level node** (if further expansion is needed)

#### 5.3 Branch Credibility Check (Game-Theoretic Closure)

Before finalizing branch rankings, apply a closure check to each highly-ranked branch (especially ranks 1-2):

**Ask**: If the deciding agent had fully anticipated all downstream agent responses at decision time, would this branch still be their optimal choice?

**Why this matters**: The tree is generated serially (agent A decides → agent B reacts → agent C reacts), but real strategic decision-makers reason with anticipation — they model what the other side will do *before* committing to their own move. A branch that requires decision-makers to ignore obvious downstream consequences is not a Nash-credible path, no matter how "locally reasonable" each step looks in isolation.

**Procedure**:
1. Take a candidate rank-1 or rank-2 branch
2. Walk forward through its 1-2 levels of downstream consequences
3. Ask: given those consequences, would the original deciding agent still make this choice *if they had fully anticipated them at decision time*?
4. If no → either (a) downgrade the branch, (b) refactor it to reflect the underlying strategic commitment / deterrence problem, or (c) explicitly flag via [PSY] that the branch depends on a bounded-rationality or emotional-override assumption that interrupts the agent's anticipatory reasoning

**Example**: "US strikes Iranian oil infrastructure → Iran closes Strait of Hormuz → oil shock" looks locally coherent at every step. Closure check: at the moment of the US strike decision, would the US still strike if they fully anticipated Iran would close the strait? If yes (US judges itself willing to absorb the oil shock to force capitulation), the branch stands. If no (US cost-benefit flips once the oil shock is factored in), the branch is not Nash-credible — the real strategic question shifts to "how credible is Iran's threat to close the strait?" rather than "does the US strike?"

**Document the result**: In each branch's `ranking_rationale`, note whether it passed the credibility check. If it required a [PSY] override (e.g. "Trump's mm-03 Personalize Everything suppresses anticipatory reasoning once confrontation is personalized"), tag that assumption explicitly.

#### 5.4 Expand Key Branches

For higher-ranked branches, define the next level of event nodes to form a tree structure. Depth is determined by user needs.

#### 5.5 Output Format

```
🌳 Possibility Tree: [Core Question]
├── ① [Most likely outcome] ⭐ Rank 1
│   ├── Rationale: [GT] ... [PSY] ... [ORG] ...
│   └── 🌳 Next: [Sub-question]
│       ├── ① [Sub-outcome A] ⭐ Rank 1
│       └── ② [Sub-outcome B]
├── ② [Second most likely]
│   └── Rationale: [GT] ... [PSY] ... [ORG] ...
└── ③ [Least likely]
    └── Rationale: [GT] ... [PSY] ... [ORG] ...
```

---

### Phase 6: Interaction (Ongoing)

After the initial analysis, enter interaction mode:

#### 6.1 Fact Injection (Dynamic Injection)
User: "Breaking news — XXX just happened"
→ This event **has occurred**. Permanently update the main tree: reassess agent states, constraints, and branch rankings. Clearly note which branches changed ranking and why.

#### 6.2 Hypothetical Simulation
User: "What if XXX happened?"
→ This event **has not occurred**. Do not change the main tree. Generate a temporary "hypothetical branch tree" showing how reasoning and rankings would change. Label: "The following is a hypothetical simulation, not based on events that have occurred."

Distinction:
- Fact injection → changes the main tree (permanent)
- Hypothetical simulation → generates a temporary branch (does not affect main tree)

#### 6.3 Add New Branch (Branch Proposal)
User: "You missed a possibility — XXX"
→ Accept the new branch, evaluate its ranking position, provide rationale, adjust existing branch rankings.

#### 6.4 Modify Agent Cognitive Framework (Cognitive Override)
User: "I think Trump has another trait you didn't consider — XXX"
→ Accept user input (tag `source: user`), validate against character-schema rules, check consistency with existing models, incorporate into analysis.

#### 6.5 Switch Focus
User: "Now analyze the impact of this event on oil markets"
→ Using the same agent and constraint framework, generate a new possibility tree from the new angle.

---

## Quality Standards

### Historical Precedent Priority

Reasoning backed by historical precedents should rank higher than pure theoretical reasoning.

When an agent's behavior pattern closely matches a known historical pattern, cite the precedent. Format:

```
"[PSY] Sunk cost bias at play. Historical precedent: In the Vietnam War, the US escalated from military advisors to 500,000 troops, driven by the same core dynamic — inability to admit prior investment was wrong. Trump's 'we already won' framing closely parallels the Johnson administration's 'victory is just around the corner' rhetoric."
```

**Judgment criteria:**
- Is the core driving force consistent with the current scenario? (Surface similarity is not enough)
- Are structural conditions comparable? (Differences in era, technology, landscape must be noted)
- Is the precedent's outcome known? (Known-outcome precedents > ongoing analogies)

Precedent-backed reasoning > Theory-backed reasoning without precedent > Pure intuitive reasoning

---

### Good Analysis vs Bad Analysis

| Good Analysis | Bad Analysis |
|--------------|-------------|
| Tags which engine each reasoning line comes from | Vaguely says "comprehensive analysis" |
| Acknowledges uncertainty and information gaps | Gives confident judgments on every branch |
| 3-5 mutually exclusive branches with clear rationale | Either 1 "most likely" or 20 vague options |
| Agent profiles loaded from validated character cards | Agent profiles only say "they want to win" |
| Hard constraints include cascading effect analysis | Hard constraints are one-line descriptions |
| Tree nodes are verifiable precise propositions | Nodes are vague narrative descriptions |

### Never Do

- **Never pretend to predict the future** — this is a thinking tool, not an oracle
- **Never output precise probability numbers** — rank only, no quantification
- **Never ignore uncertainty** — every branch must note what could upend it
- **Never package generic analysis as deep insight** — if info is insufficient, say so
- **Never omit key agents** — better to list one extra than miss a key decision-maker
- **Never use an unvalidated character card** — all cards must pass schema validation

---

## Nuwa.skill Integration

Psychohistory's character cards can be generated by Nuwa.skill:

- **CLI users**: If Nuwa is installed, the system can auto-invoke it to distill missing persons
- **Chat users**: Direct them to run Nuwa locally or obtain community-generated cards
- All Nuwa-sourced content is tagged `source: nuwa-skill`
- Nuwa output must be converted to Psychohistory character card format and validated

---

## Reference Documents

- `references/schema.md` — Full scenario data structure definitions
- `references/character-schema.md` — Character card JSON schema and validation rules
- `characters/*.json` — Official pre-built character cards
