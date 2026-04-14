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

## CLI-first Design

This toolkit **defaults to CLI environments** and is **portable across CLI agents** (Claude Code, Cline, Aider, goose, continue.dev, OpenClaw, Manus, etc.). All phase-based prompts and `SKILL.md` assume the following are available:

- Filesystem read/write access
- `git rev-parse --show-toplevel` for automatic project root detection
- `python3` + `jsonschema` for automated schema validation
- **A user with access to a chat AI with search capability** (Perplexity, ChatGPT with Search, Gemini Deep Research, Claude.ai, Kimi, 豆包, 元宝, etc.) — used by the **Research Hand-off** protocol during research phases

### Research Hand-off (not WebFetch)

This toolkit intentionally does **not** depend on Claude Code's `WebFetch` or any other CLI-agent-specific web-fetching tool. Research is delegated to the user's chat AI via a copy-paste protocol:

1. `SKILL.md` recognizes that a Phase needs external research
2. It generates a parameterized research prompt from the relevant `prompt-0X` file's `## Appendix: Research Hand-off Template`
3. The user copies the prompt into their preferred chat AI with search capability
4. The chat AI runs the research and returns structured findings
5. The user pastes the findings back into the CLI session, which integrates them into `references.md`

This keeps the toolkit portable across CLI agents — any CLI agent that can read/write files and run Python can use it — and also produces **higher-quality research than single-URL fetching**, because search-capable chat AIs do multi-step research with cross-referencing and citation tracking.

### Chat-AI as an escape hatch (Export Mode)

If you want to generate an **entire card** inside a chat AI rather than using CLI at all, invoke `SKILL.md` in **Export Mode**. It produces a self-contained, chat-AI-adapted prompt you can paste into ChatGPT / Claude.ai / Trae / Gemini / etc. After the chat AI responds, bring the `references.md` + JSON content back to your CLI session for validation and saving.

### Optional enhancement: MCP integration (not currently developed)

If your CLI agent supports **MCP (Model Context Protocol)** and you have a search MCP server configured (e.g. Perplexity MCP, Brave Search MCP), the Research Hand-off copy-paste step could in principle be replaced by direct MCP tool calls — the skill would invoke the MCP tool and receive research results inline, skipping the user's manual copy-paste.

**This is not currently implemented.** It may be added in a future skill version if MCP search servers become widely available and standardized. For now, Research Hand-off via copy-paste is the only research path in the skill stage.

### Future: engine stage API integration (not currently developed)

In the upcoming `engine/` module (see [`../../engine/README.md`](../../engine/README.md)), the Research Hand-off copy-paste dance can be replaced by **direct API calls** to search-capable LLMs (Perplexity API, OpenAI Search API, Gemini API, etc.). Users will configure API keys once, and the engine will route research requests automatically. Research Hand-off will remain as a fallback for users who don't configure API keys, who need chat-UI-specific features, or who hit API errors.

**This is an engine-stage feature, not a skill-stage feature.** It will not be added to the skill — it's specifically what the engine module exists to enable.

---

## Universal Rules

These rules apply to every type of character card:

1. **All JSON must pass standard parser validation** — no syntax errors allowed
2. **All text content in English** — fields like `name` and `description` must be English-only
3. **Date format: YYYY-MM-DD only** — no incomplete dates accepted
4. **`agent_id` is lowercase alphanumeric + hyphens** — e.g. `us-federal-reserve`, `maga-base`
5. **Every card must have `honesty_boundaries`** — explicitly stating what the card cannot capture

---

## Methodology Principles (v1.1)

The following 5 principles apply across all **phase-based prompts** (prompt-02 / 03 / 04) and form the foundation of the character-card generation methodology. prompt-01 (personal entity) inherits principles 1, 3, 4, and 5 through its dependency on the Nuwa multi-phase distillation pipeline; principle 2 applies to it as well.

1. **Two-stage minimum** — Research phase first, structuring phase second. Never go directly from blank to JSON.
2. **references.md is the primary artifact** — JSON is its compressed index. Write the notes first → compile the JSON from them → verify every JSON field points back to specific evidence in references.md.
3. **Evidence strength grading** — Every conclusion is annotated `strength: high / medium / low`. `high` requires multi-case support; `low` is allowed but must be explicitly flagged.
4. **Explicit cognitive boundaries** — `honesty_boundaries` must include type-specific declarations:
   - Organizations: factional divergence disclaimer
   - Collectives: internal heterogeneity disclaimer
   - Relationships: scenario-binding disclaimer
5. **Historical precedent priority** — Reasoning backed by historical cases ranks above pure theoretical reasoning; precedent-free inferences are flagged `strength: low`.

These 5 are **hard requirements**, not suggestions. Any JSON produced by a phase-based prompt that violates any of them must go back to the corresponding Phase to add evidence or correct its strength grading.

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
