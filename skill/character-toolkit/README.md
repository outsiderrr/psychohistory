# Psychohistory · Character Card Generation Toolkit (Index)

**English** · [中文](./README_CN.md)

> This toolkit contains standardized prompts for generating all types of character cards used by Psychohistory.
> Pick the prompt file that matches the type of character you want to generate.

---

## Character Type Router

```
What are you generating?
│
├── A specific individual? (Trump, Netanyahu, Powell)
│   └── 👉 Use prompt-01-personal-entity.md (invokes the Nuwa skill)
│
├── An organization? (Federal Reserve, IRGC, Apple Inc., Iranian government)
│   └── 👉 Use prompt-02-org-entity.md
│
├── A collective? (MAGA voters, US stock market participants, Iranian public)
│   └── 👉 Use prompt-03-collective.md
│
└── A relationship between agents? (Trump ↔ Vance, Iran gov ↔ IRGC)
    └── 👉 Use prompt-04-relationship.md
```

---

## File List

| File | Purpose | Output Format |
|------|---------|---------------|
| `prompt-01-personal-entity.md` | Personal entity card (invokes Nuwa skill) | `[agent_id].json` |
| `prompt-02-org-entity.md` | Organization entity card (government / company / military) | `[agent_id].json` |
| `prompt-03-collective.md` | Collective agent profile | `[agent_id].json` |
| `prompt-04-relationship.md` | Inter-agent relationship definition | `[rel_id].json` |

---

## Universal Rules

These rules apply to every type of character card:

1. **All JSON must pass standard parser validation** — no syntax errors allowed
2. **All text content in English** — fields like `name` and `description` must be English-only
3. **Date format: YYYY-MM-DD only** — no incomplete dates accepted
4. **`agent_id` is lowercase alphanumeric + hyphens** — e.g. `us-federal-reserve`, `maga-base`
5. **Every card must have `honesty_boundaries`** — explicitly stating what the card cannot capture

---

## Save Paths

| Type | Path |
|------|------|
| Nuwa raw data | `characters/nuwa/[agent_id].md` |
| Personal entity JSON | `characters/psychohistory/[agent_id].json` |
| Organization entity JSON | `characters/psychohistory/[agent_id].json` |
| Collective agent JSON | `characters/psychohistory/[agent_id].json` |
| Relationship JSON | `characters/relationships/[rel_id].json` |
| References file (evidence chain) | Same directory as the JSON, with `.references.md` suffix |

Every character card and every relationship definition must also produce a references file (`.references.md`) documenting the evidence chain behind each conclusion. The references file is for users who want to verify or refine the conclusions; it does not affect engine execution.

---

## Quick Judgment: Entity or Collective?

Ask yourself one question: **Does this character have a single "final decision-maker"?**

- Yes → Entity. Even large organizations qualify as entities if one person or a small committee can make the call.
- No → Collective. No one can represent the whole group in making a decision; behavior is a statistical emergent outcome.

**What about gray zones?**

Some characters fall between the two — e.g. Iran's Supreme National Security Council, which has a collective decision-making mechanism but no single dictator. In such cases, model it as an **organization entity**, but explicitly note the peculiarities of the internal decision-making mechanism in the card.
