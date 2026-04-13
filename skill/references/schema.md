# Psychohistory V1 — Protocol Layer Schema (Draft v1)

> This document defines the core data structures for the Psychohistory V1 scenario engine.
> All simulation inputs and outputs must conform to this protocol.

---

## 1. Scenario

The top-level container for all agents, constraints, events, and the possibility tree.

```json
{
  "scenario_id": "us-iran-2026-04",
  "title": "Situation analysis after US-Iran Islamabad talks collapse",
  "description": "April 12, 2026: Third round of US-Iran Islamabad talks collapsed. Vance left Pakistan. Analyzing possible trajectories after the two-week ceasefire expires.",
  "created_at": "2026-04-12",
  "time_horizon": {
    "start": "2026-04-12",
    "end": "2026-06-30",
    "description": "From talks collapse to potential medium-term outcomes"
  },
  "agents": [],
  "constraints": [],
  "events": [],
  "probability_tree": {}
}
```

---

## 2. Agent

### 2.1 Classification

Agents share a common base structure, differentiated by `agent_type`:
- `entity`: Individual decision-makers (heads of state, institutional leaders)
- `collective`: Group forces (voter bases, market participants), modeled via collective profiles

### 2.2 Entity Agent

Entity agent cognitive frameworks are loaded from character cards (`characters/*.json`).
See `references/character-schema.md` for the full character card JSON schema and validation rules.

The `cognitive_framework` field below shows how character card data maps into the scenario context:

```json
{
  "agent_id": "trump",
  "agent_type": "entity",
  "name": "Donald Trump",
  "role": "US President",
  "affiliation": "us-government",
  "cognitive_framework": {
    "source": "nuwa-skill/trump-perspective",
    "mental_models": [
      {
        "id": "mm-01",
        "name": "Everything Is a Deal",
        "description": "All relationships — international diplomacy, political alliances, business partnerships — are fundamentally transactions. Every deal has winners and losers."
      },
      {
        "id": "mm-02",
        "name": "Threats Are Leverage, Not Commitments",
        "description": "Tough talk is a bargaining tactic, not a commitment to action. Most threats aim to create fear to extract concessions."
      },
      {
        "id": "mm-03",
        "name": "Personalize Everything",
        "description": "Policy disputes are converted into personal vendettas. Once personal-level confrontation is triggered, the retreat threshold rises dramatically."
      }
    ],
    "decision_heuristics": [
      {
        "id": "dh-01",
        "name": "Scorecard Test",
        "description": "Every decision is first evaluated by its impact on his 'scorecard' (stock market, employment, approval ratings). Good scorecard → stay the course; deteriorating scorecard → consider pivoting."
      },
      {
        "id": "dh-02",
        "name": "Never Show Weakness",
        "description": "Never appear to retreat or back down in public. If retreat is necessary, it must be repackaged as 'victory'."
      }
    ],
    "concession_triggers": [
      {
        "id": "ct-01",
        "description": "Markets crash to psychological threshold",
        "current_status": "Not activated — oil price surge benefits energy stocks"
      },
      {
        "id": "ct-02",
        "description": "Major donors revolt",
        "current_status": "Not activated — defense industry donors supportive"
      },
      {
        "id": "ct-03",
        "description": "Opponent offers a face-saving exit",
        "current_status": "Partially activated — Iran proposed 10-point plan but deemed too demanding"
      },
      {
        "id": "ct-04",
        "description": "Base erodes",
        "current_status": "Not activated — MAGA support for striking Iran remains high"
      }
    ]
  },
  "relationships": []
}
```

### 2.3 Collective Agent

Collective agents use a four-layer profile instead of Nuwa distillation.

```json
{
  "agent_id": "maga-base",
  "agent_type": "collective",
  "name": "MAGA Base",
  "description": "Trump's core supporters: primarily white blue-collar workers, evangelical Christians, and anti-establishment voters",
  "affiliation": "us-domestic",
  "collective_profile": {
    "core_interests": [
      {
        "interest": "Economy, jobs, and cost of living",
        "priority": 1,
        "description": "Oil prices and consumer goods prices directly affect their quality of life and political attitudes"
      },
      {
        "interest": "National strength projection",
        "priority": 2,
        "description": "Support America showing force internationally, but not at the cost of significant US military casualties"
      },
      {
        "interest": "Anti-establishment sentiment",
        "priority": 3,
        "description": "Distrust of Washington elites and mainstream media; support Trump's norm-breaking style"
      }
    ],
    "current_disposition": {
      "issue": "US-Iran War",
      "stance": "Support",
      "intensity": "Medium-high",
      "description": "Generally supportive of hardline stance on Iran, but latent anxiety about prolonged war and rising oil prices"
    },
    "sensitivity_map": [
      {
        "event_type": "Significant US military casualties",
        "sensitivity": "Extreme",
        "expected_shift": "Support drops sharply",
        "description": "US military casualties are the MAGA base's most sensitive red line; strong historical memory of Vietnam and Iraq"
      },
      {
        "event_type": "Sustained oil price surge causing inflation",
        "sensitivity": "High",
        "expected_shift": "Support erodes gradually",
        "description": "Rising cost of living erodes war support, but with a time delay"
      },
      {
        "event_type": "Reports of Iranian civilian casualties",
        "sensitivity": "Low",
        "expected_shift": "Minimal impact",
        "description": "MAGA base has low sensitivity to enemy civilian casualties"
      }
    ],
    "influence_pathway": {
      "target_agent": "trump",
      "mechanism": "Poll approval ratings → Trump's 'Scorecard Test' decision heuristic",
      "description": "Base erosion transmits through declining approval ratings, triggering Trump's concession condition ct-04"
    }
  }
}
```

---

## 3. Agent Relationship

Relationships between agents are modeled through a loyalty mechanism supporting dynamic mode switching.

```json
{
  "relationship_id": "rel-001",
  "agent_a": "iran-government",
  "agent_b": "irgc-leadership",
  "affiliation": "iran",
  "relationship_type": "loyalty",
  "loyalty": {
    "current_value": 70,
    "threshold": 40,
    "current_mode": "loyal",
    "description": "IRGC currently follows the government's overall diplomatic direction, but has serious disagreements on whether to accept negotiation terms"
  },
  "mode_definitions": {
    "loyal": {
      "description": "agent_a can represent the entire affiliation (Iran), but agent_b's preferences exist as a hidden constraint in agent_a's decision function",
      "constraint_on_agent_a": "Cannot make decisions that would sharply decrease agent_b's loyalty, e.g., accepting 'surrender all enriched uranium' terms"
    },
    "independent": {
      "description": "agent_b becomes a fully independent agent with its own objective function and behavioral engine. Both still share 'preserving Iran's overall interests' as a variable, but weighted lower than their respective self-interests",
      "trigger": "Loyalty drops below threshold (40)"
    }
  },
  "loyalty_modifiers": [
    {
      "event_type": "Government accepts US enriched uranium terms",
      "impact": -30,
      "description": "Would be viewed by IRGC as a fundamental betrayal of national sovereignty"
    },
    {
      "event_type": "Major military victory on the battlefield",
      "impact": +10,
      "description": "Shared victory temporarily strengthens internal unity"
    },
    {
      "event_type": "US airstrikes cause major IRGC personnel losses",
      "impact": -15,
      "description": "IRGC may blame losses on the government's diplomatic weakness"
    }
  ]
}
```

---

## 4. Hard Constraint

Objective conditions that no agent can violate, forming the physical boundaries of the simulation.

```json
{
  "constraint_id": "con-001",
  "name": "Strait of Hormuz geographic bottleneck",
  "type": "geographical",
  "description": "Approximately 20% of global oil and LNG supply transits the Strait of Hormuz. The strait is only about 33km wide at its narrowest point; blockade by any party directly impacts global energy supply.",
  "cascading_effects": [
    {
      "domain": "Global energy prices",
      "description": "Continued blockade keeps oil prices elevated; full restoration of shipping may take months"
    },
    {
      "domain": "Global inflation pressure",
      "description": "Energy price increases cascade into higher transportation and consumer goods costs"
    },
    {
      "domain": "Shipping insurance",
      "description": "War zone shipping insurance rates surge; some shipowners may refuse transit"
    }
  ],
  "affected_agents": ["trump", "iran-government", "maga-base", "global-energy-market"]
}
```

---

## 5. Event

Events use Polymarket-style precise proposition definitions, satisfying four requirements:
1. **Binary outcome** — only "occurred" or "did not occur"
2. **Publicly verifiable** — can be independently confirmed by multiple parties
3. **Clear time window** — has a deadline or time period
4. **Precise description** — eliminates ambiguous interpretation

```json
{
  "event_id": "evt-001",
  "proposition": "Will the US and Iran sign a formal ceasefire extension agreement before April 22, 2026 (two-week ceasefire expiration)?",
  "time_window": {
    "deadline": "2026-04-22",
    "type": "deadline"
  },
  "verification_criteria": "Confirmed by simultaneous official statements from both US and Iranian sides",
  "current_status": "pending",
  "result": null,
  "causal_drivers": [
    {
      "agent_id": "trump",
      "driver": "Tension between Trump's 'Never Show Weakness' heuristic and 'Everything Is a Deal' model",
      "direction": "uncertain"
    },
    {
      "agent_id": "iran-government",
      "driver": "Iran insists on 'permanent ceasefire', rejects temporary arrangements",
      "direction": "oppose"
    },
    {
      "agent_id": "irgc-leadership",
      "driver": "IRGC favors continued military resistance, opposes compromise",
      "direction": "strongly oppose"
    },
    {
      "agent_id": "netanyahu",
      "driver": "Israel opposes US-Iran ceasefire, may sabotage talks through military action",
      "direction": "oppose"
    }
  ]
}
```

---

## 6. Possibility Tree

The tree consists of multiple Event nodes. Each node produces mutually exclusive branches ranked from most to least likely (`likelihood_rank` = 1 is most likely). The system does not output precise probabilities.

```json
{
  "tree_id": "tree-us-iran-main",
  "root_event": "evt-001",
  "snapshot_date": "2026-04-12",
  "nodes": [
    {
      "node_id": "node-001",
      "event_id": "evt-001",
      "proposition": "Will US-Iran sign ceasefire extension before April 22?",
      "branches": [
        {
          "branch_id": "branch-001c",
          "outcome": "No — hostilities resume after ceasefire expires",
          "likelihood_rank": 1,
          "ranking_rationale": "[GT] All three sticking points touch core interests; negotiation space is minimal; [PSY] Trump's 'Personalize Everything' is activated, retreat threshold is very high; [ORG] Israel continues to pressure, acting as deal-breaker",
          "next_node": "node-002c"
        },
        {
          "branch_id": "branch-001b",
          "outcome": "No — no deal signed, but de facto ceasefire holds (neither side resumes large-scale operations)",
          "likelihood_rank": 2,
          "ranking_rationale": "[GT] Both sides have incentives to avoid full escalation — US faces oil price pressure, Iran has limited military resources; [ORG] Restarting large-scale operations requires logistical preparation, inertia delays action",
          "next_node": "node-002b"
        },
        {
          "branch_id": "branch-001a",
          "outcome": "Yes — ceasefire extension agreement signed",
          "likelihood_rank": 3,
          "ranking_rationale": "[GT] Three core issues (strait, enriched uranium, frozen assets) all unresolved; [PSY] Vance called it the 'final offer', Iran announced no further talks planned; [ORG] IRGC resistance makes any compromise extremely difficult to pass internally",
          "next_node": "node-002a"
        }
      ]
    },
    {
      "node_id": "node-002c",
      "parent_branch": "branch-001c",
      "event_id": "evt-003",
      "proposition": "Within 30 days of hostilities resuming, will the US strike Iranian energy infrastructure (refineries, oil ports, Kharg Island)?",
      "branches": [
        {
          "branch_id": "branch-002c-1",
          "outcome": "Yes — strikes on energy infrastructure",
          "likelihood_rank": 1,
          "ranking_rationale": "[PSY] Trump publicly stated desire to control Kharg Island and Iranian oil, consistent with his 'Everything Is a Deal' model — controlling the opponent's resources is the ultimate leverage; [GT] Striking energy facilities is the most direct lever to force Iran back to the table",
          "next_node": null
        },
        {
          "branch_id": "branch-002c-2",
          "outcome": "No — military operations limited to military targets",
          "likelihood_rank": 2,
          "ranking_rationale": "[GT] Striking energy facilities would further spike global oil prices, harming US consumers; [PSY] Trump's 'Scorecard Test' heuristic may prevent decisions that worsen economic indicators; [ORG] UN warned this could constitute war crimes, creating organizational-level international resistance",
          "next_node": null
        }
      ]
    }
  ]
}
```

---

## 7. Behavioral Engine Tags

Each branch's `ranking_rationale` should tag which behavioral engine the reasoning comes from, helping users identify the source and limitations of each inference.

| Tag | Engine | Meaning |
|-----|--------|---------|
| `[GT]` | Game Theory | Reasoning based on payoff calculations, Nash equilibria, dominant strategies |
| `[PSY]` | Psychological Model | Reasoning based on agent cognitive frameworks, biases, emotional momentum |
| `[ORG]` | Organizational Behavior | Reasoning based on organizational inertia, group dynamics, structural friction |

Example:

```
"ranking_rationale": "[GT] Iran conceding under current conditions is a dominated strategy — accepting US terms yields no security guarantees; [PSY] Trump's 'Personalize Everything' model is activated, retreat threshold is extremely high. Historical precedent: Vietnam War escalation driven by sunk cost bias — same inability to admit prior investment was a mistake; [ORG] IRGC-government split within Iran makes any compromise package extremely difficult to pass internally"
```

---

## 8. Dynamic Injection and Hypothetical Simulation

The system supports two modes of information injection, differing in whether they alter the main tree.

### 8.1 Fact Injection (events that have occurred)

When new information emerges, users can inject it to **permanently update** the main tree's branch rankings.

```json
{
  "injection_id": "inj-001",
  "timestamp": "2026-04-15",
  "content": "Iran announces successful test of new hypersonic missile during ceasefire",
  "source": "Iranian official news agency",
  "verified": true,
  "impact_assessment": [
    {
      "target": "con-002",
      "effect": "Iran missile stockpile constraint's deterrence value increases"
    },
    {
      "target": "trump → ct-01",
      "effect": "Markets may drop on fear, potentially activating Trump's concession trigger"
    },
    {
      "target": "rel-001 → loyalty",
      "effect": "Military success may temporarily boost IRGC loyalty to government (+10)"
    },
    {
      "target": "node-001 → branch-001c",
      "effect": "Hostilities resumption branch ranking may need reassessment"
    }
  ]
}
```

### 8.2 Hypothetical Simulation (events that have not occurred)

Users can propose a hypothetical scenario; the system generates a **temporary branch tree** showing how reasoning and rankings would change. Does not alter the main tree.

```json
{
  "simulation_id": "sim-001",
  "timestamp": "2026-04-15",
  "hypothesis": "Assume Iran launches a massive missile attack on Israel during the ceasefire, causing significant civilian casualties",
  "is_factual": false,
  "simulated_impacts": [
    {
      "target": "trump → ct-03",
      "effect": "Face-saving exit condition is completely closed — Iran proactively breaking ceasefire gives Trump full justification for escalation"
    },
    {
      "target": "rel-001 → loyalty",
      "effect": "IRGC-government loyalty may drop sharply — if this action was not government-authorized"
    },
    {
      "target": "maga-base → current_disposition",
      "effect": "Base war support likely increases further — Iran becomes the clear 'aggressor'"
    }
  ],
  "simulated_tree_changes": [
    {
      "original_branch": "branch-001c (hostilities resume)",
      "original_rank": 1,
      "simulated_rank": 1,
      "change": "Ranking unchanged but certainty increases dramatically; expected scale of hostilities escalates"
    },
    {
      "original_branch": "branch-001a (agreement signed)",
      "original_rank": 3,
      "simulated_rank": 3,
      "change": "Likelihood drops to near zero"
    }
  ],
  "caveat": "The above is a hypothetical simulation, not based on events that have occurred. For exploring potential consequences of a specific scenario only."
}
```

---

## 9. User Input

The framework supports bidirectional interaction. Users can inject their own judgments at two levels:

### 9.1 Branch Proposal

Users can add new possibility branches to any node in the tree. The system evaluates ranking position based on existing agent frameworks, constraints, and engines.

```json
{
  "input_id": "ui-001",
  "input_type": "branch_proposal",
  "target_node": "node-001",
  "timestamp": "2026-04-13",
  "submitted_by": "user",
  "proposed_branch": {
    "outcome": "No formal agreement, but Iran unilaterally implements a 'toll transit' regime on the strait, creating de facto limited reopening",
    "user_rationale": "Iran needs revenue for post-war reconstruction. Full blockade also harms its own interests. Toll transit preserves control while restoring partial trade flow."
  },
  "system_evaluation": {
    "accepted": true,
    "recommended_rank": 2,
    "ranking_rationale": "[GT] Toll transit is Iran's dominant strategy — preserves strait control as leverage, generates direct revenue, and reduces international pressure from full blockade; [PSY] Consistent with Parliament Speaker Ghalibaf's public statement that 'the strait situation will not return to pre-war status'; [ORG] Iran's parliament has already begun reviewing strait governance legislation, organizational-level preparation is underway",
    "impact_on_existing_branches": [
      {
        "branch_id": "branch-001b",
        "change": "Original rank 2 drops to rank 3, as 'toll transit' is more structurally sustainable than a vague 'gray zone' status"
      }
    ]
  }
}
```

### 9.2 Cognitive Override

Users can supplement or override any agent's cognitive framework. User input coexists alongside Nuwa distillation output, distinguished by `source` field.

```json
{
  "input_id": "ui-002",
  "input_type": "cognitive_override",
  "target_agent": "trump",
  "timestamp": "2026-04-13",
  "submitted_by": "user",
  "action": "add_mental_model",
  "content": {
    "id": "mm-04",
    "name": "Resource Control Is Victory",
    "description": "Trump tends to view controlling the opponent's core resources (oil, shipping lanes, rare earth) as the ultimate form of war victory, rather than territorial occupation or regime change. This explains his repeated references to 'taking Kharg Island' and 'the US should collect the tolls'.",
    "source": "user",
    "basis": "Based on Trump's Financial Times interview about controlling Iranian oil, and his prior interest in Greenland's mineral resources"
  },
  "system_evaluation": {
    "consistency_check": "Highly consistent with existing mm-01 (Everything Is a Deal); can be viewed as mm-01's specific extension in wartime scenarios",
    "conflict_with_existing": null,
    "recommendation": "Accept. Suggest incorporating as a sub-model of mm-01 rather than an independent mental model."
  }
}
```

### 9.3 Source Tagging Convention

All content within agent cognitive frameworks must be tagged by source:

| Source Value | Meaning |
|-------------|---------|
| `nuwa-skill` | Generated by Nuwa.skill distillation |
| `user` | Manually added by user |
| `system-derived` | Derived by the system from available information |

---

## Glossary

| Term | Definition |
|------|-----------|
| Agent | An actor with independent decision-making power; either entity or collective |
| Loyalty | A dynamic value describing the obedience relationship between two agents within the same faction |
| Hard Constraint | An objective condition no agent can violate; forms the physical boundary of the simulation |
| Event | A Polymarket-style precise proposition satisfying: binary outcome, publicly verifiable, clear time window, precise description |
| Possibility Tree | A causal reasoning structure composed of Event nodes and mutually exclusive branches, ranked by likelihood |
| Dynamic Injection | Injecting new factual information to permanently update the tree's branch rankings |
| Branch Proposal | User-submitted new possibility branch, evaluated by the system for ranking position |
| Cognitive Override | User supplement or modification to an agent's cognitive framework, coexisting with Nuwa output |
| Source Tag | Field identifying content origin: nuwa-skill / user / system-derived |
| Hypothetical Simulation | Generating a temporary branch tree based on an assumed (not yet occurred) scenario; does not change the main tree |
| Historical Precedent | A known historical case whose core driving force is consistent with the current scenario; used to strengthen reasoning credibility |
