---
name: research-handoff
description: "Research Hand-off: a portable protocol for delegating external research to the user's preferred chat AI with search capability. Generates parameterized research prompts, handles wrapper script automation, paste sanity checking, format tolerance, and batch merging. Works across any CLI agent — no dependency on WebFetch or any agent-specific tool. Triggers: 'research this', 'I need external data', 'do research on', 'find information about', 'Research Hand-off'."
---

# Research Hand-off — Portable External Research Protocol

> Delegate external research to the user's preferred chat AI with search capability. This skill generates structured research prompts, handles automation via wrapper scripts, validates returned content, and integrates results into target files.
>
> **Portable across CLI agents**: works with Claude Code, Cline, Aider, goose, continue.dev, OpenClaw, Manus, etc. No dependency on any agent-specific web-fetching tool.

---

## When to Use This Skill

Any time the executing AI needs **external, up-to-date information** that exceeds its training knowledge — especially content within the past 12 months. Common scenarios:

- Generating character cards (called by `character-toolkit`)
- Testing theories against recent events (called by `theory-test`)
- Interpreting recent news (called by `news-interpreter`)
- Any other skill that needs current data from the web

**The 12-month rule**: for any content falling within the most recent 12 months relative to today's date, **default to using this skill** rather than trusting training knowledge, which may be inaccurate, stale, or hallucinated.

---

## Inputs (provided by the calling skill or user)

| Input | Required | Description |
|---|---|---|
| `research_prompt` | Yes | The filled-in research prompt text (with all placeholders substituted). The calling skill is responsible for loading a template and filling parameters before invoking this skill. |
| `output_language` | No (default: English) | If set to a non-English language, this skill prepends a language instruction to the research prompt. |
| `integration_target` | No | File path where results should be written (e.g., a `references.md`). If not provided, results are returned to the calling skill as text. |
| `batch_items` | No | For batch mode: a list of `{id, research_prompt}` pairs to merge into one research call. |

---

## Environment Assumptions

- **A user with access to a chat AI with search capability** (Perplexity, ChatGPT with Search, Gemini Deep Research, Claude.ai, Kimi, 豆包, 元宝, etc.)
- **Optional**: `PSYCHOHISTORY_RESEARCH_TOOL` environment variable pointing to a wrapper script in `research-handoff/wrappers/` for automated execution
- **Optional**: `python3` + `jq` (used by wrapper scripts, not by the protocol itself)

**Intentionally NOT required**: Claude Code's `WebFetch` or any other CLI-agent-specific web-fetching tool.

---

## Protocol

### Step 1 — Wrapper Script Shortcut (check first)

Before invoking the manual copy-paste protocol, check if the user has configured an automated research tool:

```bash
echo "$PSYCHOHISTORY_RESEARCH_TOOL"
```

If set AND points to an executable file:

1. If `output_language` ≠ English, prepend the language instruction (see Step 2) to the `research_prompt`
2. Pipe the prompt via stdin to the executable, capture stdout:
   ```bash
   RESEARCH_RESULT=$(echo "$FILLED_PROMPT" | "$PSYCHOHISTORY_RESEARCH_TOOL")
   ```
3. If exit code 0 and stdout non-empty → use the result, **skip to Step 5** (integration)
4. If wrapper fails (non-zero exit, empty output, timeout) → report the error (show stderr), fall through to Step 2

**Reference wrapper scripts** are available in `research-handoff/wrappers/`:

| Script | Provider | Env var |
|---|---|---|
| `perplexity.sh` | Perplexity Sonar Pro | `PERPLEXITY_API_KEY` |
| `anthropic.sh` | Claude with `web_search` tool | `ANTHROPIC_API_KEY` |
| `openai.sh` | GPT-4o search preview | `OPENAI_API_KEY` |
| `gemini.sh` | Gemini 2.5 Pro with google_search grounding | `GEMINI_API_KEY` or `GOOGLE_API_KEY` |

See `research-handoff/wrappers/README.md` for setup, the wrapper contract, and verification guidance.

If `PSYCHOHISTORY_RESEARCH_TOOL` is not set → proceed to Step 2.

### Step 2 — Prepare the Research Prompt

1. Take the `research_prompt` provided by the calling skill (already filled with target-specific parameters)

2. **Always prepend** the following citation format instruction to the top of the prompt:

   > **CITATION FORMAT: Every factual claim or analytical conclusion must include an inline citation [N] (e.g., "IRGC controls an estimated 30% of Iran's economy [3]"). At the end of your response, provide a numbered source list: [N] Author/Organization, "Title", Date, URL. Claims without inline citations are treated as unsourced and may be discarded.**

3. **If `output_language` ≠ English**, also prepend the following language instruction:

   > **IMPORTANT: Return ALL of your findings in {output_language}. Even when summarizing sources in other languages, write your summaries and analysis in {output_language}. Section headers (§0, §1.1, etc.) should remain as-is in English for structural recognition. Source URLs and proper nouns may remain in their original language.**

### Step 3 — Emit the Prompt to the User

Output the prepared prompt as a copy-pasteable markdown code block, preceded by:

> *"I need external research. Copy the prompt below and paste it into your preferred chat AI with search capability. Recommended options:*
> - ***Perplexity*** *— English-language research with inline citations*
> - ***ChatGPT with Search*** *— general-purpose prompts*
> - ***Gemini Deep Research*** *— deep multi-step investigations (15-minute runs)*
> - ***Claude.ai with web search*** *— synthesis-heavy tasks*
> - ***Kimi / 豆包 / 元宝*** *— Chinese-language content*
>
> ⚠️ ***Important: many modern chat AIs put long research results in a side panel (Canvas / Artifact / Immersive panel), NOT in the main chat text. If your AI says "I've completed the research" but the actual content is in a side panel:***
> - ***Gemini Deep Research***: ***Option A (recommended)***: *click "Share & Export" → "Create Google Doc" → set sharing to "Anyone with the link can view" → paste the Google Doc URL back here (the CLI agent can read it directly via the export endpoint, with full source list intact).* ***Option B***: *click the research card/chip → select all text with Ctrl+A/Cmd+A → copy. Note: Gemini's "Copy content" button drops the source list — always use select-all or Option A instead.*
> - ***ChatGPT***: *if result opens in Canvas, click into it → select all → copy*
> - ***Claude.ai***: *if result appears as an Artifact, click it → copy its full content*
> - ***Perplexity / Kimi / 豆包 / 元宝***: *typically return in chat stream — copy normally*
>
> *Once you have the FULL research text (not just a "completed" message), paste it back here."*

### Step 4 — Wait and Validate the Paste

Wait for the user to return with pasted content.

**Google Doc URL detection**: If the user pastes a URL matching `docs.google.com/document/d/...` instead of text content, read the document directly via the export endpoint: append `/export?format=txt` to the document base URL (strip any existing query parameters or hash). This returns the full document as plain text including sources that Gemini's "Copy content" button would drop. Fetch using whatever URL-reading capability your CLI agent provides (`WebFetch`, `curl`, MCP tools). If fetching fails (permissions error), ask the user to set sharing to "Anyone with the link can view" and retry.

**Before integrating, run a paste sanity check**:

**Red flags** (any one = ask user to re-paste):
- Pasted content is under 500 characters total
- Contains `googleusercontent.com/immersive_entry_chip` (Gemini Canvas placeholder)
- Only says "I've completed the research" or similar with no §N section headers
- Contains a single URL reference but no research text body

If red flag detected, tell the user: *"It looks like you copied a placeholder instead of the actual research content. Your chat AI probably put the full results in a side panel (Canvas / Artifact). Please open that panel, select all the text, and paste it again."*

### Step 5 — Integrate the Results

Map the returned content's `##` sections to the target document's structure.

**Format tolerance protocol**:
- **Strict on section recognition**: top-level headers (§0, §1, §1.1, §2, etc.) must be identifiable. Minor rephrasing is OK if intent is clear.
- **Relaxed on sub-structure**: accept variations like bullets-vs-nested-lists, swapped field names, extra wording
- **On ambiguity**: ask the user one clarifying question before proceeding
- **If severely malformed**: show the user what's missing, offer to (a) manually annotate gaps or (b) re-run the prompt with a different chat AI

If `integration_target` was provided (a file path), write the integrated content to that file. Otherwise, return the content to the calling skill.

---

## Batch Mode

When the calling skill provides `batch_items` (multiple research targets to combine into one call):

### Merge Procedure

1. Take each item's `research_prompt` and wrap it with clear delimiters:

~~~
You will research multiple targets. For EACH target below, return findings
as a clearly-delimited section.

=== RESPONSE FORMAT ===

Use these exact delimiters for each target:

    <<<TARGET: [target_id]>>>
    [research sections as specified in the target's template]
    <<<END TARGET: [target_id]>>>

Do not add prose outside these sections.

=== TARGETS ===

--- Target 1: [id_1] ---

[filled research prompt for target 1]

--- Target 2: [id_2] ---

[filled research prompt for target 2]

... (continue for all targets)

=== END TARGETS ===
~~~

2. If `output_language` ≠ English, prepend the language instruction before everything
3. Dispatch via wrapper (Step 1) or manual paste (Steps 2-4)
4. Parse the returned content by splitting on `<<<TARGET: [id]>>>` / `<<<END TARGET: [id]>>>` delimiters
5. Return per-target content to the calling skill, keyed by `target_id`

**Batch size guidance**: max 4 targets without wrapper (chat AI context limits); 8+ comfortable with wrapper.

---

## Failure Modes

| Failure | Response |
|---|---|
| Wrapper script fails (non-zero exit) | Report stderr, fall through to manual protocol |
| Paste sanity check fails | Ask user to re-paste from Canvas/Artifact |
| Severely malformed content | Show gaps, offer re-run with different chat AI |
| User declines research entirely | Return to calling skill with a "research declined" signal; calling skill marks affected fields `strength: low` with "data unavailable" |

---

## Why Not WebFetch

This skill intentionally does not depend on Claude Code's `WebFetch` or any CLI-agent-specific web-fetching tool. The research happens in the user's chat AI, outside the CLI agent. This keeps the skill portable across all CLI agents AND produces higher-quality research (multi-step search, cross-referencing, citation tracking) than single-URL fetching.

**Future**: the engine module will add direct API calls to search-capable LLMs alongside this protocol. This skill remains as the fallback. See `engine/README.md` §4.

---

## Wrapper Contract

Any executable pointed to by `PSYCHOHISTORY_RESEARCH_TOOL` must:

1. **Read** a research prompt from **stdin** (plain text, may contain multi-line markdown)
2. **Write** research findings to **stdout** (plain text or markdown)
3. **Exit 0** on success, non-zero on error (error details on stderr)

That's the whole interface. Users can write custom wrappers (local Ollama, RAG pipelines, cached lookups, multi-provider chains) as long as they follow this contract.
