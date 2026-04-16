---
name: three-engine-analysis
description: "Three-Engine Analysis: analyze any decision situation from three complementary perspectives — Game Theory [GT], Psychological Models [PSY], and Organizational Behavior [ORG]. Works with or without formal character cards. A general-purpose analytical framework usable for geopolitics, business strategy, negotiations, policy analysis, and more. Triggers: 'three-engine analysis', 'GT PSY ORG analysis', 'analyze from game theory perspective', 'multi-perspective analysis', 'why did they decide this', '三引擎分析', '从博弈论角度分析'."
---

# Three-Engine Analysis Framework

> Analyze any decision situation from three distinct, complementary perspectives. Each engine sees the world differently; their convergence points are strong signals, their disagreements reveal genuine uncertainty.
>
> Independent atomic skill — can be used standalone or composed into larger skills (Psychohistory scenario analysis, theory validation, news interpretation, etc.).

---

## When to Use

Any time you need to understand **why agents make the decisions they do** — or predict what they might do next — from multiple analytical lenses. Examples:

- Geopolitical events: "Why did Russia do X?" / "What will Iran do next?"
- Business strategy: "How will the CEO respond to this competitive move?"
- Negotiations: "Where is the deal space? What are the credible threats?"
- Policy analysis: "Why was this regulation designed this way?"
- News interpretation: "Four countries visited China this week — what's the logic?"

**This framework is NOT a prediction tool** — it's a structured thinking tool that helps enumerate variables, causal chains, and analytical perspectives to avoid blind spots.

---

## Inputs

| Input | Required | Description |
|---|---|---|
| Decision situation | Yes | What happened, or what decision is being analyzed. Can be a single event, a pattern of events, or a hypothetical scenario. |
| Agent profiles | No | If formal character cards (Psychohistory format) are available, the [PSY] engine uses their `mental_models`, `decision_heuristics`, and `known_biases`. If not, the [PSY] engine works from publicly known behavior patterns. |
| Hard constraints | No | If known: physical, economic, institutional, or temporal boundaries that no agent can violate. Improves [GT] analysis quality. |
| output_language | No | Language for the analysis output. Default: English. |

---

## The Three Engines

### [GT] Game Theory Engine

Analyze the strategic structure of the situation:

- **Payoff matrices**: What does each party gain or lose from each possible action?
- **Nash equilibrium**: Is there a stable state where no party benefits from unilaterally changing strategy?
- **Dominant/dominated strategies**: Does any party have a clearly best (or clearly worst) option regardless of what others do?
- **Credible threats and commitments**: Can threats actually be carried out? Are commitments binding?
- **First-mover advantage**: Does acting first create leverage?
- **Signaling and screening**: What information is being communicated through actions?
- **Repeated game dynamics**: Is this a one-shot interaction or part of an ongoing relationship? (Affects cooperation incentives)

**[GT] is strongest when**: the situation has clear strategic actors with identifiable interests, and the "rules of the game" are somewhat stable.

**[GT] is weakest when**: actors behave irrationally, emotional factors dominate, or the game structure itself is unclear.

### [PSY] Psychological Model Engine

Analyze through the cognitive frameworks of the decision-makers:

**If character cards are available** (Psychohistory `*.json` files):
- Apply each agent's `mental_models`: how do they see the world?
- Apply `decision_heuristics`: what quick judgment rules do they follow?
- Check `known_biases`: are cognitive biases distorting their assessment?
- Check `concession_triggers`: what would make them change course?
- Check `red_lines`: what will they absolutely not do?

**If no character cards**:
- Analyze from publicly known behavior patterns
- Identify likely cognitive biases from past decisions
- Assess emotional momentum: are they escalating or de-escalating?
- Assess retreat threshold: how hard is it for them to back down?

**[PSY] is strongest when**: individual decision-makers have outsized influence (autocratic leaders, CEOs with strong control), and their personality/cognitive patterns are well-documented.

**[PSY] is weakest when**: decisions are made by large committees, or the decision-maker is unknown/replaceable.

### [ORG] Organizational Behavior Engine

Analyze through the lens of organizational dynamics:

- **Inertial direction**: What will the organization keep doing if no one intervenes?
- **Internal friction**: How much does it cost (politically, procedurally) to change direction?
- **Factional dynamics**: Are there internal factions pulling in different directions? Which is dominant?
- **Path dependence**: Has the organization locked itself into a trajectory that's hard to reverse?
- **Information propagation**: How fast does information flow through the organization? Are there bottlenecks or filters?
- **Institutional memory**: Does the organization "remember" past mistakes or repeat them?

**[ORG] is strongest when**: the actor is a large institution (government, military, corporation) where internal dynamics significantly constrain or shape external behavior.

**[ORG] is weakest when**: the actor is an individual or a very small team with no institutional overhead.

---

## Historical Precedent Priority

**Reasoning backed by historical precedents ranks higher than pure theoretical reasoning.**

When an agent's behavior pattern closely matches a known historical case, cite the precedent. Format example:

```
[PSY] Sunk cost bias at play. Historical precedent: In the Vietnam War,
the US escalated from advisors to 500,000 troops, driven by the same
core dynamic — inability to admit prior investment was wrong.
```

**Judgment criteria** for a valid precedent:
- **Core driving force** must be consistent with the current situation (surface similarity is not enough)
- **Structural conditions** must be comparable (note differences in era, technology, scale)
- **Known-outcome precedents** are stronger than ongoing analogies

Priority: precedent-backed reasoning > theory-backed reasoning > pure intuitive reasoning

---

## Output Format

Tag every reasoning line with its engine source. The output should have four sections:

```
## [GT] Game Theory Analysis
[Strategic structure, payoffs, equilibria, credible threats, signaling...]

## [PSY] Psychological Model Analysis
[Cognitive frameworks, biases, emotional momentum, retreat thresholds...]
[If character cards used: cite specific mental_model IDs, e.g. "mm-01 Everything Is a Deal"]

## [ORG] Organizational Behavior Analysis
[Inertia, factions, path dependence, internal friction, info propagation...]

## Synthesis
Where do the three engines converge? → High-confidence insight
Where do they disagree? → Genuine uncertainty that needs monitoring
What would each engine predict happens next?
```

---

## Quality Standards

| Good Analysis | Bad Analysis |
|---|---|
| Tags which engine each reasoning line comes from | Vaguely says "comprehensive analysis" |
| Acknowledges uncertainty and information gaps | Gives confident judgments on every point |
| Cites historical precedents where applicable | Pure theoretical speculation |
| Uses agent's specific cognitive framework if available | Generic "they want to win" |
| Notes where engines disagree (genuine uncertainty) | Presents a single narrative as if all engines agree |
| Distinguishes "what [GT] predicts" from "what [PSY] predicts" | Blends engines into an undifferentiated soup |

---

## Never Do

- **Never pretend all three engines agree when they don't** — disagreement between engines is valuable signal, not noise
- **Never skip an engine** — even if one seems less relevant, note that briefly ("ORG dynamics are minimal here because the actor is an individual, not an institution")
- **Never ignore character card data if available** — if a card says the agent has a specific bias, the [PSY] engine must address it
- **Never present pure speculation as historical precedent** — if there's no close match, say so
