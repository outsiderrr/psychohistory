# Psychohistory · Macro Event Scenario Engine 🌳

**English** · [中文](./README_CN.md)

> Not a crystal ball — a structured thinking tool.

Input any unfolding complex event; get a multi-agent game-theoretic analysis and a possibility tree.

Helps you enumerate key decision-makers, hard constraints, causal chains, and possible outcomes — to avoid blind spots, not to predict the future.

## See It in Action

**Input:** "Analyze the situation after the US-Iran talks collapsed"

**Output:**

```
🌳 Will the US and Iran sign a ceasefire extension before April 22?

├── ① Hostilities resume after ceasefire expires ⭐ Rank 1
│   ├── [GT] All three sticking points touch core interests; negotiation space is minimal
│   ├── [PSY] Trump's "Personalize Everything" model is activated; retreat threshold is very high
│   └── [ORG] Israel continues to pressure, acting as a deal-breaker
│
├── ② No deal signed, but de facto ceasefire holds
│   ├── [GT] Both sides have incentives to avoid full escalation
│   └── [ORG] Restarting large-scale military operations requires logistical preparation time
│
└── ③ Ceasefire extension agreement signed
    ├── [GT] Three core issues (strait, enriched uranium, frozen assets) remain unresolved
    └── [PSY] Vance called it the "final offer"; Iran announced no further talks planned
```

Each branch is tagged with its reasoning source: `[GT]` Game Theory · `[PSY]` Psychological Model · `[ORG]` Organizational Behavior

## What It Does

1. **Identify Key Agents** — Who makes decisions? Who influences decision-makers? What's their cognitive framework?
2. **Map Hard Constraints** — What are the immovable physical and institutional boundaries?
3. **Three-Engine Analysis** — Game theory, psychological models, and organizational behavior each weigh in
4. **Generate Possibility Tree** — Rank mutually exclusive outcomes from most to least likely, each with reasoning
5. **Continuous Interaction** — Inject new information, add new options, modify agent profiles

## What It Doesn't Do

- ❌ Does not predict the future
- ❌ Does not output precise probability numbers
- ❌ Does not pretend to be omniscient

## Install

```bash
npx skills add your-username/psychohistory-skill
```

After installation, try:

- "Analyze the US-Iran situation"
- "What will the Fed do next on interest rates?"
- "Map out the NVIDIA vs AMD AI chip competition"

## Use Cases

- **Geopolitics** — War trajectory, diplomatic games, sanctions impact
- **Macroeconomics** — Central bank policy, trade wars, energy markets
- **Business Competition** — CEO decision analysis, industry shifts, M&A dynamics
- **Policy Analysis** — Legislative processes, regulatory changes, elections

## Core Concepts

### Agent

Any actor with independent decision-making power. Two types:
- **Entity Agent** — Individuals or institutional leaders (Trump, Netanyahu)
- **Collective Agent** — Group forces introduced as needed (MAGA base, Wall Street)

### Loyalty Relationship

Agents within the same faction are connected through a dynamic loyalty value:
- **Loyal Mode** — A can represent the whole faction, but B's preferences act as a hidden constraint
- **Independent Mode** — Once loyalty drops below threshold, B becomes a fully independent agent

### Three Engines

| Tag | Engine | What It Examines |
|-----|--------|-----------------|
| `[GT]` | Game Theory | Payoff matrices, Nash equilibria, credible threats |
| `[PSY]` | Psychological Model | Cognitive frameworks, biases, emotional momentum |
| `[ORG]` | Organizational Behavior | Inertia, internal friction, path dependence |

### Historical Precedent Priority

Reasoning backed by historical precedents ranks higher than pure theoretical reasoning. When an agent's behavior pattern closely matches a known historical pattern, the precedent must be cited in the ranking rationale.

### Possibility Tree

Each node is a Polymarket-style precise proposition (binary outcome, publicly verifiable, clear time window, precise description). Branches are ranked by likelihood — no numerical probabilities.

## Nuwa.skill Integration

Psychohistory's agent cognitive frameworks can directly reference persona skills distilled by [Nuwa.skill](https://github.com/alchaincyf/nuwa-skill).

Nuwa distills "how this person thinks"; Psychohistory puts those distilled personas into constrained game scenarios.

Currently available personas: Trump, Musk, Zhang Yiming, Munger, and 13 others.

## File Structure

```
skill/
├── README.md                        # English introduction (you're reading this)
├── README_CN.md                     # Chinese introduction
├── SKILL.md                         # Core execution instructions (for AI)
├── characters/
│   └── psychohistory/
│       └── trump.json               # Example character card (Trump)
├── references/
│   ├── schema.md                    # Scenario data structure definitions
│   └── character-schema.md          # Character card JSON schema & validation
└── character-toolkit/               # Character card generation toolkit (submodule)
    ├── README.md                    # English index
    ├── README_CN.md                 # Chinese index
    └── prompt-01..04                # Generation prompts
```

## Character Card System

Psychohistory uses standardized JSON character cards to model key decision-makers' cognitive frameworks.

**Three-tier loading mechanism:**
1. **Official library first** — Check `characters/` directory for pre-built cards
2. **CLI auto-generation** — If missing and in CLI environment, auto-invoke Nuwa.skill
3. **Chat manual input** — If missing and in web chat, guide user to paste a card or describe in natural language

All character cards, regardless of source, must pass unified schema validation.

## User Interaction

Four interaction modes after initial analysis:

**Inject Facts:** "Breaking news — Iran test-fired a hypersonic missile" → Permanently updates the main tree's rankings and reasoning

**Hypothetical Simulation:** "What if Iran launched a massive missile attack on Israel?" → Generates a temporary hypothetical branch tree without changing the main tree

**Add New Options:** "You missed a possibility — Iran might charge tolls on the strait" → System evaluates ranking position for the new option

**Modify Agent Profile:** "I think Trump has another trait — he sees resource control as victory" → System checks consistency and incorporates into analysis

## Design Philosophy

Inspired by Asimov's "Psychohistory," but this is not sci-fi prophecy — it's engineered structural thinking support.

Core belief: **Not helping you compute answers, but helping you ask the right questions.**

## Roadmap

- [x] Protocol layer schema definition
- [x] Skill version (current)
- [ ] Standalone web app (visual probability tree + interactive scenario planning)
- [ ] Reverse convergence tree (work backwards from a target outcome to map prerequisite condition chains; complements the forward divergence tree)
- [ ] Theory validation mode (user proposes causal hypothesis, system searches for supporting/opposing evidence)
- [ ] Automated collective agent profiling
- [ ] Deep integration with Nuwa.skill

## License

MIT

---

*Psychohistory doesn't create prophecies — it creates perspectives.*
