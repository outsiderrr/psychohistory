---
name: psychohistory-character-toolkit
description: "Psychohistory Character Card Generation Toolkit. Orchestrates generation of character cards (personal / organization / collective) and inter-agent relationships, routes to phase-based prompts (prompt-01/02/03/04), enforces the 5 design principles, produces references.md as primary artifact with JSON as compressed index, runs Python schema validation. CLI-first; Export mode emits chat-AI-ready prompts on request. Triggers: 'generate character card', 'create agent card', 'add agent to scenario', 'make a card for', 'export character prompt', 'I need a card for', '生成角色卡', '为X做张卡', '导出 prompt'."
---

# Psychohistory · Character Card Generation Toolkit

> Orchestration skill for generating character cards and inter-agent relationship definitions.
> Delegates phase-by-phase execution to the four phase-based prompts in this directory (`prompt-01` / `prompt-02` / `prompt-03` / `prompt-04`) and enforces cross-cutting concerns (5 design principles, output paths, schema validation).
>
> **CLI-first design**: assumes filesystem access, `git`, `python3` + `jsonschema`, and `WebFetch`. For chat-AI users, see §Export Mode below.

---

## Environment Assumptions

This skill is designed for **CLI environments** and is **portable across CLI agents** (Claude Code, Cline, Aider, goose, continue.dev, OpenClaw, Manus, etc.). It assumes the following are available:

- **Filesystem read/write** at the project root, discoverable via `git rev-parse --show-toplevel`
- **Python 3** with the `jsonschema` library (or pip-installable: `pip install jsonschema`)
- **git** for project root detection
- **A user with access to a chat AI with search capability** (Perplexity, ChatGPT with Search, Gemini Deep Research, Claude.ai, Kimi, 豆包, 元宝, etc.) — used by the **Research Hand-off** protocol (§Step 3.1 below) during the research phases of card generation. This skill does not call those chat AIs directly; it produces research prompts that the user runs in their preferred tool and brings results back

**Intentionally NOT required**: CLI-agent-specific web-fetching tools such as Claude Code's `WebFetch`. Research is delegated to the user's chat AI via copy-paste, which keeps this skill portable across CLI agents.

**Optional enhancement — MCP (Model Context Protocol), not currently implemented**: if your CLI agent supports MCP and you have a search MCP server configured (e.g. Perplexity MCP, Brave Search MCP), the Research Hand-off copy-paste step could in principle be replaced by direct MCP tool calls. This is **not currently developed** — may be added in a future skill version if MCP search servers become widely available and standardized. See `character-toolkit/README.md` §CLI-first Design for the planned MCP integration note.

**Chat-AI users** (users who want to run the full generation inside a chat AI rather than from a CLI at all): this skill does not execute natively in chat-AI environments. Instead, invoke this skill from CLI in **Export Mode** (§below) — it produces a self-contained prompt you can paste into any chat AI to execute the generation there.

---

## 5 Design Principles (enforced across all Phases)

All phase-based prompts under this toolkit enforce the following principles. Canonical statement: `character-toolkit/README.md` §方法论原则. Any generated card that violates any of these must return to the responsible Phase for correction — never ship a card that fails these gates.

1. **Two-stage minimum** — research phase first, structuring phase second
2. **references.md is the primary artifact** — JSON is a compressed index compiled from references.md
3. **Evidence strength grading** — `strength: high / medium / low` on every testable claim
4. **Explicit cognitive boundaries** — type-specific disclaimers in `honesty_boundaries`
5. **Historical precedent priority** — cases-backed reasoning ranks above pure theoretical reasoning

---

## Step 0 — Intent Detection

When invoked, classify the user's request into one of three modes:

| Intent pattern | Mode | Example triggers |
|---|---|---|
| "Generate/create a card for X" | **Single-Card** (default) | "Generate IRGC's card", "Create a card for Netanyahu" |
| "Generate multiple cards" / "Set up all the X-side cards" | **Batch** | "Set up all the Iran-side cards for the US-Iran scenario" |
| "Give me a prompt for X" / "Export for X" / "Run this in ChatGPT" | **Export** | "Export the org card prompt for IRGC so I can paste it into Claude.ai" |

If the user's intent is ambiguous, ask **one** clarifying question before proceeding. Do not guess.

---

## Step 1 — Identify Project Root

Before any file I/O, resolve the project root:

```bash
git rev-parse --show-toplevel
```

Store the result as `<PROJECT_ROOT>`. All subsequent output file paths are computed relative to this root.

If `git rev-parse` fails (not in a git repo), search upward from the current working directory for a `skill/SKILL.md` marker file and use its parent directory as the project root. If neither method works, ask the user for the project root path explicitly.

**Output path convention** (after `<PROJECT_ROOT>` is resolved):

| File | Path |
|---|---|
| Nuwa raw data (personal entities only) | `<PROJECT_ROOT>/skill/characters/nuwa/[agent_id].md` |
| Character references.md (all non-relationship cards) | `<PROJECT_ROOT>/skill/characters/psychohistory/[agent_id].references.md` |
| Character JSON (all non-relationship cards) | `<PROJECT_ROOT>/skill/characters/psychohistory/[agent_id].json` |
| Relationship references.md | `<PROJECT_ROOT>/skill/characters/relationships/[rel_id].references.md` |
| Relationship JSON | `<PROJECT_ROOT>/skill/characters/relationships/[rel_id].json` |

Create any missing subdirectories with `mkdir -p` before writing.

---

## Step 2 — Route by Card Type

From the user's target description, determine the card type:

| Target | Judgment | Prompt file | Output `card_type` |
|---|---|---|---|
| A specific individual | Real person with a name | `prompt-01-personal-entity.md` | `personal-entity` |
| An organization with central decision-making | Has a "final decision-maker" (person or small committee) | `prompt-02-org-entity.md` | `organization-entity` |
| A group without central decision-making | No single decision-maker; behavior is statistical emergence | `prompt-03-collective.md` | `collective` |
| A relationship between two existing cards | User specifies "relationship between A and B" | `prompt-04-relationship.md` | (not a character card) |

**The final decision-maker test**: ask "does this target have a single person or small committee who can make the call?" Yes → entity. No → collective. See `character-toolkit/README.md` §快速判断 for gray-area guidance.

**Gray-zone default**: when ambiguous between `organization-entity` and `collective` (e.g., Iran's Supreme National Security Council — collective mechanism but no single dictator), default to `organization-entity` with `decision_structure.type: "committee"` and explicitly note the peculiarity of the internal mechanism in `honesty_boundaries`.

---

## Step 3 — Execute the Selected Prompt's Phase Flow

Read the selected prompt file via the `Read` tool and follow its Phase 0 → Phase N sequence exactly as specified. Each phase-based prompt is self-describing; **this skill's role is orchestration, not reimplementation**. The phase content lives in the prompt files.

### 3.1 Research Phase Handling — Research Hand-off protocol

When a Phase requires external research (historical cases, recent decisions, polling data, market movements, current organizational state, interaction history), follow the degradation chain below.

**The 12-month rule**: For any content falling within the most recent 12 months relative to today's date, **do not trust the executing AI's training knowledge**. Fresh data is often inaccurate, stale, or hallucinated. Training knowledge is reliable only for stable historical content that has settled into the record.

**Degradation chain (check each option in order; use the first one available)**:

#### 3.1.0 — Wrapper script shortcut (check first)

Before invoking the full Research Hand-off protocol, check if the user has configured an automated research tool via the `PSYCHOHISTORY_RESEARCH_TOOL` environment variable.

```bash
echo "$PSYCHOHISTORY_RESEARCH_TOOL"
```

If it is set AND points to an executable file:

1. Fill in the research prompt as you would for Step 3 of the main protocol (load the prompt-0X `## Appendix: Research Hand-off Template`, substitute placeholders)
2. Pipe the filled prompt via stdin to the executable, capture stdout:
   ```bash
   FILLED_PROMPT=$(...)  # constructed by this skill
   RESEARCH_RESULT=$(echo "$FILLED_PROMPT" | "$PSYCHOHISTORY_RESEARCH_TOOL")
   ```
3. If exit code is 0 and stdout is non-empty:
   - Use `$RESEARCH_RESULT` as the research findings, **skip to Step 6 of the main protocol** (integration into references.md)
   - Skip the user-copy-paste dance entirely
4. If the wrapper fails (non-zero exit code, empty output, timeout, or error string on stderr):
   - Report the failure to the user (show the wrapper's stderr)
   - Fall through to the standard Research Hand-off protocol below (steps 1-7)

**This shortcut is primarily for users of CLI agents that bring their own API key** (OpenClaw, Cline, Aider, goose, continue.dev, etc.), who can configure a ready-to-use wrapper script from `character-toolkit/research-wrappers/`. Claude Code users whose Anthropic credentials are not exposed to the shell can still set up a separate API key (e.g., Perplexity) for this step.

If `PSYCHOHISTORY_RESEARCH_TOOL` is not set → proceed with the standard protocol below.

See `character-toolkit/research-wrappers/README.md` for available reference scripts (Perplexity, Anthropic, OpenAI, Gemini), setup instructions, and the wrapper contract.

#### 3.1.1 — Standard Research Hand-off protocol (manual copy-paste)

If the wrapper shortcut is unavailable or failed, use the standard protocol:

1. **Identify the research need** based on the current Phase of the loaded prompt-0X file. Typical needs:
   - `prompt-02` (organization) — historical decision cases, factional structure, current trajectory, key dependencies
   - `prompt-03` (collective) — polling data, sensitivity calibration precedents, observable state current values
   - `prompt-04` (relationship) — direct interaction history between the two endpoint agents
   - `prompt-01` (personal, fallback only) — if Nuwa is unavailable, delegate the full cognitive profile research via hand-off

2. **Load the Research Hand-off Template** from the corresponding prompt-0X file's `## Appendix: Research Hand-off Template` section. Each phase-based prompt file has one appended after its main execution flow.

3. **Fill in the parameters**. Substitute placeholders with specific values from the user's request:
   - `{TARGET_NAME}`, `{AGENT_A_NAME}`, `{AGENT_B_NAME}` — target names
   - `{TIME_WINDOW_START}`, `{TIME_WINDOW_END}` — typically "2-3 years ago" through today
   - `{SCENARIO_CONTEXT}`, `{TARGET_AGENT_ID}` — scenario-level context

4. **Emit the filled research prompt** to the user as a copy-pasteable markdown code block, preceded by guidance:

   > *"I need external research for this Phase. Copy the prompt below and paste it into your preferred chat AI with search capability. Recommended options (ranked by typical strength):*
   > - ***Perplexity*** *— English-language research with inline citations*
   > - ***ChatGPT with Search*** *— general-purpose prompts*
   > - ***Gemini Deep Research*** *— deep multi-step investigations (15-minute runs)*
   > - ***Claude.ai with web search*** *— synthesis-heavy tasks*
   > - ***Kimi / 豆包 / 元宝*** *— Chinese-language content*
   >
   > *Once the chat AI returns its findings, paste the entire response back here and say 'integrate this research for [target]'."*

5. **Wait for the user** to return with pasted content. Do not proceed to the next Phase without it.

6. **Integrate the returned research** into `references.md` by mapping its `##` sections (§1 Source Materials, §2 Historical ..., etc.) to the corresponding `references.md` sections. Apply the **format tolerance protocol**:
   - **Strict on section recognition**: top-level headers must be identifiable (minor rephrasing is OK if the intent is clear)
   - **Relaxed on sub-structure**: accept variations like bullets-vs-nested-lists, swapped field names, extra wording
   - **On ambiguity**: ask the user one clarifying question before proceeding
   - **If severely malformed**: show the user specifically what's missing, offer to either (a) manually annotate the gaps or (b) re-run the research prompt with a different chat AI

7. **If Research Hand-off is declined** (user says "just use what you know" or similar), fall back to training knowledge with explicit `strength: low` on any fresh-data claims, and mark data gaps as "unavailable" in references.md. **Never fabricate** recent data.

**Why not WebFetch**: This skill intentionally does not depend on Claude Code's `WebFetch` or any other CLI-agent-specific web-fetching tool. Research Hand-off is portable across any CLI agent because the actual web research happens in the user's chat AI, outside the CLI agent entirely. It also produces higher-quality research than single-URL fetching, because search-capable chat AIs do multi-step research with cross-referencing and citation tracking.

*Future enhancement (engine stage)*: The engine module will replace the copy-paste step with **direct API calls** to search-capable LLMs (Perplexity API, OpenAI Search API, Gemini API, etc.), while keeping Research Hand-off as a fallback for users who don't configure API keys, who need chat-UI-specific features, or who hit API errors. See `engine/README.md` §Planned Capabilities.

### 3.2 Checkpoint Behavior

Each Phase ends with a Checkpoint that commits the Phase's output to the correct `references.md` section. Behavior differs by interaction mode:

- **Automatic mode** (default): continue directly to the next Phase without pausing
- **Interactive mode**: pause, print the Phase's produced content, and wait for the user to say "continue" or propose adjustments before proceeding

Interactive mode is activated when the user explicitly requests it with "interactive", "step by step", "let me review each phase", "审阅", "一步一步", or similar. If not explicitly requested, run in automatic mode.

### 3.3 Prerequisite Gates (especially prompt-04)

`prompt-04-relationship.md` has a Phase 0 **hard gate**: both endpoint cards must exist and pass schema validation before proceeding. This skill enforces the gate strictly — if either endpoint card is missing or invalid, terminate the flow and report specifically which card is missing. **Do not attempt to "fake" the gate** or generate a relationship card against nonexistent endpoints.

### 3.4 Writing Output Files

As each Phase completes, write its output to the correct file via the `Edit` or `Write` tool:

- Phase 1-N research notes → append to `references.md`
- Final Phase JSON compilation → write to `.json`

Use the paths computed in Step 1. Always write to the canonical path — do not write to temp locations and move.

---

## Step 4 — Schema Validation

After the selected prompt's final Phase produces JSON, run JSON Schema validation against `skill/references/character-schema.md`:

```bash
python3 << 'PYEOF'
import json, re, sys

PROJECT_ROOT = "<RESOLVED_PROJECT_ROOT>"
SCHEMA_MD = f"{PROJECT_ROOT}/skill/references/character-schema.md"
CARD_JSON = "<OUTPUT_CARD_PATH>"

with open(SCHEMA_MD) as f:
    content = f.read()

section_start = content.find("## 2. JSON Schema Definition")
if section_start < 0:
    sys.exit("⚠️  Could not locate JSON Schema section in character-schema.md")

rest = content[section_start:]
match = re.search(r"```json\n(\{[\s\S]*?\n\})\n```", rest)
if not match:
    sys.exit("⚠️  Could not extract JSON Schema block")

schema = json.loads(match.group(1))

with open(CARD_JSON) as f:
    card = json.load(f)

try:
    import jsonschema
except ImportError:
    print("⚠️  jsonschema not installed. Install with: pip install jsonschema")
    print(f"Card has been saved to {CARD_JSON} but not schema-validated.")
    print("Manual validation required.")
    sys.exit(0)

try:
    jsonschema.validate(card, schema)
    print(f"✓ Card passes schema validation: {CARD_JSON}")
except jsonschema.ValidationError as e:
    print(f"✗ Schema validation failed at {'/'.join(str(p) for p in e.path)}:")
    print(f"  {e.message}")
    sys.exit(1)
PYEOF
```

Before running: substitute `<RESOLVED_PROJECT_ROOT>` with the actual project root path from Step 1, and `<OUTPUT_CARD_PATH>` with the actual JSON file path from Step 3.

If validation fails, report the specific field and error, return to the responsible Phase (usually the JSON compilation Phase) for correction, and re-run validation.

**Relationship cards**: `character-schema.md` does not cover relationships (they live in `schema.md §3`). For relationships, run a reduced manual check against the self-check list in `prompt-04-relationship.md` Phase 6 instead of the Python validation above.

---

## Step 5 — Batch Coordination (when in Batch Mode)

Batch mode handles multiple related cards in dependency order.

### 5.1 Parse the batch request

The user's request typically looks like:

> "Set up the Iran-side cards for the US-Iran 2026 scenario: I need iran-government, irgc-leadership, plus the iran-gov ↔ irgc relationship."

Parse this into two lists:

- **Character cards**: `iran-government` (organization-entity), `irgc-leadership` (organization-entity)
- **Relationships**: `rel-001 iran-gov ↔ irgc` (loyalty)

### 5.2 Sort by dependency order

Rules:

1. All character cards first — they have no dependencies on other cards
2. Relationships last — their Phase 0 gate requires endpoint cards to exist
3. Within character cards, order is flexible

### 5.3 Batch Research Collection (reduces N copy-pastes to 1)

Before executing individual card generation, collect research for all **non-relationship cards** in one merged Research Hand-off call. This reduces N copy-pastes to 1 for users without a wrapper script, and collapses per-card API calls to one batch call for wrapper-script users.

Relationships are handled separately in step 5.5 — they need endpoint character cards to exist first.

**Procedure**:

1. **Gather research needs**: for each character card in the batch (personal / organization / collective), load its corresponding prompt-0X's `## Appendix: Research Hand-off Template`.

2. **Fill each template** with that card's parameters (`{TARGET_NAME}`, `{TIME_WINDOW_*}`, `{SCENARIO_CONTEXT}`, etc.).

3. **Construct a merged research prompt** using clear delimiters so the response can be split per target:

~~~
You will research multiple targets for a Psychohistory scenario. For EACH
target listed below, return findings as a separate clearly-delimited section.

=== RESPONSE FORMAT ===

Use the following exact delimiters for each target's section. Do not add
prose outside these delimited sections.

    <<<TARGET: [target_id]>>>
    [complete research sections §1-§N as specified in the target's template]
    <<<END TARGET: [target_id]>>>

=== TARGETS ===

--- Target 1: [target_id_1] ([card_type_1]) ---

[filled-in Research Hand-off Template for target 1]

--- Target 2: [target_id_2] ([card_type_2]) ---

[filled-in Research Hand-off Template for target 2]

... (continue for all character cards in the batch)

=== END TARGETS ===
~~~

4. **Dispatch the merged prompt**:
   - **If `PSYCHOHISTORY_RESEARCH_TOOL` is configured** (see §Step 3.1.0): pipe the entire merged prompt to the wrapper via stdin, capture the response from stdout — one API call for the whole batch
   - **Otherwise**: emit the merged prompt to the user as one copy-pasteable block (preceded by the chat-AI recommendation from §Step 3.1.1), wait for the user to paste the response back — one copy-paste round-trip for the whole batch

5. **Parse the returned content**: split the response on `<<<TARGET: [id]>>>` and `<<<END TARGET: [id]>>>` delimiters to get per-target research. Apply the format tolerance protocol from §Step 3.1.1 — the target boundaries must be identifiable, but minor variations inside each section are acceptable.

6. **Cache per-target research**: store each target's parsed research keyed by `agent_id` for consumption by step 5.4.

**Batch size guidance**:

- **Without wrapper (manual paste)**: recommend **max 4 character cards** per merged prompt to avoid exceeding chat AI context limits (Perplexity, ChatGPT Search, etc. typically cap input around 30-50K tokens). If the user requests more, warn and split into sub-batches of ≤4.
- **With wrapper**: constrained by the provider's API context window (modern LLMs: 100K+ tokens — 8+ cards comfortable). Quality may still degrade past ~6 cards per call; consider sub-batching for very large sets.

### 5.4 Execute individual card generation

For each character card in dependency-sorted order:

1. Run Steps 1-4 (single-card flow) for that card, **but skip Step 3.1 Research Phase Handling** — use the cached per-target research from step 5.3 instead
2. Integrate the cached research into the card's `references.md` at the appropriate `§1`-`§N` sections (per the prompt-0X's phase structure)
3. Continue with the non-research phases (structural analysis, pattern extraction, JSON compilation, Python schema validation)
4. Collect the result (paths, validation status)
5. If validation fails and cannot be resolved, **stop the batch** and report the failing card

### 5.5 Handle relationship cards

If the batch includes relationship cards, handle them **after** all character cards are complete so that `prompt-04`'s Phase 0 endpoint-card gate passes.

- **1-2 relationships**: run Steps 1-4 individually for each (standard single-card flow, including Step 3.1 Research Phase Handling for interaction history)
- **3+ relationships**: optionally run a second merged research collection using `prompt-04-relationship.md`'s Research Hand-off Template — collect all interaction histories in one call, then generate individual relationship cards from the cached research

### 5.6 Report summary

After all items complete (or after stopping on failure):

```
Batch generation summary
========================
Character cards generated:
  ✓ iran-government      (organization-entity, passed validation)
  ✓ irgc-leadership      (organization-entity, passed validation)

Relationships defined:
  ✓ rel-001  iran-government ↔ irgc-leadership  (loyalty, current_value: 70, loyal mode)

Files written:
  <PROJECT_ROOT>/skill/characters/psychohistory/iran-government.{json,references.md}
  <PROJECT_ROOT>/skill/characters/psychohistory/irgc-leadership.{json,references.md}
  <PROJECT_ROOT>/skill/characters/relationships/rel-001.{json,references.md}

Research mode: [wrapper: perplexity.sh] or [manual Hand-off]
Research calls: 1 merged (character cards) + 1 merged (relationships) = 2 total
  (vs. 3 individual calls in the non-batched flow)

Total: 3 artifacts, 0 validation failures
```

---

## Export Mode

Export Mode produces a self-contained prompt that the user can paste into any chat AI (ChatGPT, Claude.ai, Trae, Gemini, etc.) to execute the card generation there. Use this when:

- The user explicitly asks for a chat-AI-ready prompt
- The user wants to leverage a specific chat AI's strengths
- The user wants to outsource generation to a collaborator who doesn't have Claude Code access

Activation phrases: "give me a prompt for...", "export the prompt for...", "I want to run this in ChatGPT/Claude.ai/Trae", "生成提示词", "导出 prompt"

### Step E1: Gather parameters

Determine from the user:

- **Card type** — personal-entity / organization-entity / collective / relationship
- **Target** — specific agent_id or description (for relationship: target_a and target_b)
- **Scenario context** — optional but often needed to contextualize the card
- **For relationships only**: confirmation that both endpoint cards exist and are valid

If any critical parameter is missing, ask one clarifying question.

### Step E2: Load and transform the prompt

1. **Read** the appropriate `prompt-0X-*.md` file via the `Read` tool
2. **Extract** the section from `# 提示词正文` through the end of the final Phase's output requirements
3. **Substitute** the placeholder fields with the user's values:
   - `【目标人物】` / `【目标组织】` / `【目标群体】` → user-specified target
   - `【场景背景】` → user-specified scenario
   - `【建模粒度】`, `【关联个人卡】`, `【角色 A】`, `【角色 B】` → fill as appropriate
4. **Rewrite** CLI-specific content for chat-AI compatibility:
   - Remove absolute / project-root-relative file save paths
   - Replace file-writing instructions with: "Output the references.md content as one markdown code block, then the JSON as a second code block. Do not attempt to save files."
   - Remove the Python `jsonschema` validation step (chat AIs cannot run it)
   - Remove references to `git rev-parse --show-toplevel` and other Bash commands
   - Remove Checkpoint language that implies multi-turn interaction (collapse into "run all phases sequentially in a single response")
5. **Prepend** a chat-AI preamble:
   > *"You are being asked to generate a Psychohistory character card by following a phase-based methodology. Execute Phase 0 through the final Phase sequentially in one response. Your output must be two markdown code blocks: first the full references.md content, then the JSON. Do not save files directly — a human will handle that after receiving your response."*
6. **Append** a postamble:
   > *"Once the human receives your response, they will bring it back to Claude Code where the `psychohistory-character-toolkit` skill will validate the JSON against the v1.1 schema and save both artifacts to the correct paths."*

### Step E3: Emit the export

Output the transformed prompt to the user as a clearly-marked copy-pasteable block:

```
📋 **Export prompt ready** — copy everything between the triple-dashes below
and paste it into your chat AI.

Once you receive a response, bring the references.md and JSON content back
here and say "integrate these export results for <agent_id>" so I can
validate and save them.

---

[the transformed prompt]

---
```

### Step E4: Integrate results when they return

When the user returns with chat-AI-generated content (often pasted as two code blocks or as one large block):

1. Parse the user's paste — identify the references.md content and the JSON content
2. Compute output paths (Step 1 rules apply)
3. Write both files
4. Run Step 4 schema validation on the JSON
5. Report validation results; if failures, show specific errors and ask user to either fix manually or request a re-export

### What Export Mode does NOT do

- Does not save files (the chat AI produces output as text; human copies it back)
- Does not run validation on the chat AI's output directly (validation happens on integration back)
- Does not support batch export — export is per-card by design (if you need 5 cards, run export 5 times)

---

## Interaction with `skill/SKILL.md`

`skill/SKILL.md` is the main Psychohistory scenario analysis skill. Its Phase 1.5 "Character Card Loading Router" handles the case when a scenario analysis needs an agent card that isn't in the official library.

Under the v1.1 architecture:

- **Phase 1.5 Tier 1** (official library lookup) — unchanged
- **Phase 1.5 Tier 2** (CLI auto-generation) — **delegates to this toolkit**. The main scenario skill invokes `psychohistory-character-toolkit` with the target agent and scenario context; this skill runs the full phase-based pipeline and saves the card
- **Phase 1.5 Tier 3** (chat fallback) — **uses this toolkit's Export Mode**. Produces a self-contained prompt for the user to run in a chat AI, then re-ingests the results via Step E4

This replaces the pre-v1.1 Tier 2 which directly invoked Nuwa. Nuwa is still invoked, but now as a sub-step inside `prompt-01-personal-entity.md` Phase 1, not directly from the main scenario skill.

---

## Failure Modes & Responses

| Failure | Response |
|---|---|
| `git rev-parse --show-toplevel` fails | Search for `skill/SKILL.md` marker file; if not found, ask user for project root |
| Target card type unclear | Ask one clarifying question; default to `personal-entity` if the user's description mentions a named individual |
| prompt-04 Phase 0 gate fails (missing endpoint cards) | Report specifically which endpoint is missing; offer to generate it first (sub-invocation) or terminate |
| Nuwa.skill invocation fails (during prompt-01 Phase 1) | Report Nuwa's error; offer to fall back to Export Mode |
| Recent-data research cannot be completed via Research Hand-off | Pause, show the user what was attempted, offer to (a) retry with a different chat AI, (b) fall back to training knowledge with `strength: low`, or (c) mark fields as "data unavailable"; never fabricate |
| JSON Schema validation fails | Report the specific field and error; return to the compilation Phase for correction; re-run validation |
| Python `jsonschema` library missing | Report and instruct `pip install jsonschema`; card is still saved but unvalidated (flagged) |
| File write fails | Report path + error; ask user to check permissions |

---

## Quick Reference

| Action | How to invoke |
|---|---|
| Generate a personal entity card | "Generate a card for [person name]" |
| Generate an organization card | "Create a card for [organization name]" |
| Generate a collective card | "Create a profile for [group name] affecting [target_agent]" |
| Define a relationship | "Define the relationship between [agent_a] and [agent_b] in [scenario]" |
| Batch generation | "Generate all the [X-side] cards for [scenario]" |
| Export a prompt for chat AI | "Give me a prompt for generating [target] that I can paste into ChatGPT" |
| Interactive mode | Add "step by step" or "interactive" to any of the above |
| Integrate export results back | "Integrate these export results for [agent_id]" |

---

## Reference Documents

- `prompt-01-personal-entity.md` — phase-based flow for personal entities (Phases 0-4)
- `prompt-02-org-entity.md` — phase-based flow for organization entities (Phases 0-6)
- `prompt-03-collective.md` — phase-based flow for collective agents (Phases 0-8)
- `prompt-04-relationship.md` — phase-based flow for inter-agent relationships (Phases 0-6)
- `character-toolkit/README.md` — toolkit index, 5 design principles, save paths, CLI-first statement
- `../references/character-schema.md` — polymorphic v1.1 schema for all three card types
- `../references/schema.md` — scenario schema including relationship structure
- `../SKILL.md` — main Psychohistory scenario analysis skill (Phase 1.5 delegates to this toolkit)
