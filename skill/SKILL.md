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

#### Tier 2: CLI Auto-Generation (CLI Environment Only)

If no official card exists AND you are in CLI environment:

```
IF environment == CLI:
  → Check if Nuwa skill is installed locally
  → If installed:
    → Execute: npx skills run nuwa-skill "Distill {person_name}"
    → Wait for Nuwa to complete (may take 2-3 hours for thorough distillation)
    → Read the generated SKILL.md from the new perspective directory
    → Convert Nuwa output to Psychohistory character card JSON format
    → Validate against character-schema
    → Save to characters/{agent_id}.json for future use
  → If Nuwa not installed:
    → Prompt user: "Nuwa skill is not installed. Install with: npx skills add alchaincyf/nuwa-skill"
    → Fall through to Tier 3 as temporary measure
```

#### Tier 3: User-Provided / System-Derived (Chat Environment or Final Fallback)

If no official card exists AND you are in Chat environment (OR CLI Tier 2 failed):

```
IF environment == CHAT (or Tier 2 failed):
  → Pause the analysis
  → Output the following guided prompt to the user:
```

**Output this message to the user:**

---

⚠️ **Character card not found for: {person_name}**

I don't have a pre-built cognitive profile for this person. You have three options:

**Option A: Paste a character card**
If you have a JSON character card (from Nuwa skill, community, or your own creation), paste it here. Required format:

```json
{
  "card_version": "1.0",
  "agent_id": "person-id",
  "name": "Full Name",
  "role": "Current Position",
  "source": { "type": "user", "created_at": "YYYY-MM-DD" },
  "mental_models": [
    { "id": "mm-01", "name": "Model Name", "description": "How they see the world (min 20 chars)" }
  ],
  "decision_heuristics": [
    { "id": "dh-01", "name": "Rule Name", "description": "Quick judgment rule (min 20 chars)" }
  ],
  "concession_triggers": [
    { "id": "ct-01", "description": "Under what condition they would change stance" }
  ],
  "red_lines": ["What they absolutely will not accept"],
  "honesty_boundaries": ["What this card cannot capture"]
}
```

**Option B: Describe in natural language**
Tell me what you know about this person's thinking style, decision patterns, core values, and blind spots. I'll construct a system-derived card from your description.

**Option C: Proceed without a card**
I'll analyze this person based on publicly known information, but the cognitive modeling will be shallower. The analysis will be tagged `source: system-derived` throughout.

---

```
→ If user provides JSON: validate against character-schema
  → If valid: load and continue
  → If invalid: show specific errors, ask user to fix
→ If user provides natural language: construct card, tag source: system-derived
→ If user chooses Option C: proceed with shallow modeling
```

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

Analyze the current situation from three distinct perspectives:

#### Game Theory Engine [GT]
- What are each party's payoff matrices?
- Is there a Nash equilibrium?
- Who has first-mover advantage?
- Are there credible threats and commitments?

#### Psychological Model Engine [PSY]
- How do each agent's cognitive frameworks (from character cards) affect their interpretation?
- Are cognitive biases at play? (Check agent's `known_biases` field if available)
- Which direction does emotional momentum point?

#### Organizational Behavior Engine [ORG]
- What is each organization's inertial direction?
- How high is the internal friction cost of changing direction?
- Is there internal fragmentation or path dependence?
- How efficiently does information propagate through the organization?

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
- **Ranking position** (rank 1 = most likely)
- **Ranking rationale** (tagged by engine: [GT] / [PSY] / [ORG], with historical precedents where applicable)
- **Next-level node** (if further expansion is needed)

#### 5.3 Expand Key Branches

For higher-ranked branches, define the next level of event nodes to form a tree structure. Depth is determined by user needs.

#### 5.4 Output Format

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
