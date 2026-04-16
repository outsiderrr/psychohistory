# Research Wrappers

**English** · [中文](./README_CN.md)

Reference wrapper scripts for automating the Research Hand-off protocol via direct API calls to search-capable LLMs. Use these if you already have an API key for one of the supported providers and want to skip the manual copy-paste between CLI and chat AI during card generation.

## Who this is for

Primarily for users of CLI agents that **bring their own API key** — OpenClaw, Cline, Aider, goose, continue.dev, etc. — where the API key is already in your environment as part of normal CLI-agent setup. The scripts work in any CLI agent that can run Bash.

**Claude Code users** can still use these: Claude Code doesn't expose its internal API credentials to your shell, but you can independently configure a separate API key (Perplexity / Anthropic / OpenAI / Gemini) specifically for the research step.

## How the skill uses them

`character-toolkit/SKILL.md` Step 3.1 (Research Phase Handling) checks for the `PSYCHOHISTORY_RESEARCH_TOOL` environment variable:

1. If it is set to an executable file path, the skill pipes the filled-in research prompt via stdin, reads the stdout as research findings, and integrates them into `references.md` — **skipping the manual copy-paste entirely**.
2. If the executable fails (non-zero exit, empty output, timeout), the skill reports the error and falls back to standard Research Hand-off (manual copy-paste via chat AI).
3. If `PSYCHOHISTORY_RESEARCH_TOOL` is not set, the skill goes directly to standard Research Hand-off.

## Available wrappers

| Script | Provider | Env var | Notes |
|---|---|---|---|
| `perplexity.sh` | Perplexity | `PERPLEXITY_API_KEY` | Dedicated research LLM with built-in web search. **Recommended default** — purpose-built for this use case, cleanest API |
| `anthropic.sh` | Anthropic Claude | `ANTHROPIC_API_KEY` | Uses Claude with `web_search_20250305` tool; strong synthesis |
| `openai.sh` | OpenAI | `OPENAI_API_KEY` | Uses `gpt-4o-search-preview` via Chat Completions |
| `gemini.sh` | Google Gemini | `GEMINI_API_KEY` or `GOOGLE_API_KEY` | Uses Gemini 2.5 Pro with `google_search` grounding |

## Setup

1. **Pick a wrapper** based on the API key you already have (or choose fresh — Perplexity is recommended for research use cases). You only need one.

2. **Export your API key** in your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

   ```bash
   export PERPLEXITY_API_KEY="pplx-..."
   ```

3. **Point `PSYCHOHISTORY_RESEARCH_TOOL`** at the absolute path of the wrapper script:

   ```bash
   export PSYCHOHISTORY_RESEARCH_TOOL="$HOME/Desktop/psychohistory/skill/character-toolkit/research-wrappers/perplexity.sh"
   ```

4. **Make the script executable**:

   ```bash
   chmod +x "$HOME/Desktop/psychohistory/skill/character-toolkit/research-wrappers/"*.sh
   ```

5. **Test with a trivial prompt**:

   ```bash
   echo "What is the population of Iceland as of 2025?" | "$PSYCHOHISTORY_RESEARCH_TOOL"
   ```

   You should see a text answer (not an error). If it fails, check stderr for the specific error message.

6. **Reload your shell** (`source ~/.zshrc` or open a new terminal), then invoke `character-toolkit/SKILL.md` normally. Research phases will now automatically route through the wrapper.

## ⚠️ Verification required before real use

These wrapper scripts are **reference templates based on API shapes as of 2025-05**. LLM API formats evolve; before trusting a wrapper for real project work, you should:

1. **Check current API docs** for your provider — endpoints, auth headers, model names, and request/response shapes all change over time
2. **Run the test command** from step 5 above
3. **Verify the output** is a real answer, not an error dump

Known fragile points by provider:

- **Perplexity** — model name (`sonar-pro` valid as of 2025; check for renames)
- **Anthropic** — `web_search` tool type (`web_search_20250305`) and model name (`claude-sonnet-4-5`); both get newer versions
- **OpenAI** — `gpt-4o-search-preview` availability varies; may need to switch to the Responses API with an explicit `web_search` tool, or to a newer search-enabled model
- **Gemini** — `google_search` grounding format and model name (`gemini-2.5-pro`); Google's APIs change more often than others

If you find a script needs updating, edit it directly — they are intentionally short (< 100 lines each) and self-contained. Consider contributing the update back to the repo.

## Cost and rate-limit awareness

Each wrapper invocation makes a real API call that costs money. Rough estimates per single card research (2-5K output tokens):

| Provider | Approx cost per card |
|---|---|
| Perplexity Sonar Pro | $0.01 – $0.03 |
| Claude Sonnet 4.5 with web_search | $0.05 – $0.15 (higher due to tool-use loops) |
| GPT-4o-search-preview | $0.02 – $0.08 |
| Gemini 2.5 Pro with grounding | $0.02 – $0.06 |

For batch research (see `character-toolkit/SKILL.md` §Step 5.3 Batch Research Collection), cost scales roughly linearly with the number of cards — or slightly sub-linear if the chat AI reuses shared context.

Rate limits: each provider has their own. For occasional use (a few cards per day) none should be a concern. For batch generation of dozens of cards, check your provider's quota page.

## The wrapper contract

`character-toolkit/SKILL.md` only expects three things from whatever executable `PSYCHOHISTORY_RESEARCH_TOOL` points at:

1. **Reads a research prompt from stdin** (plain text, may contain multi-line markdown)
2. **Writes research findings to stdout** (plain text or markdown)
3. **Exits 0 on success**, non-zero on error; error details go to stderr

That's the whole interface. **You can write your own wrapper** — it doesn't have to be one of these four. Ideas:

- Local Ollama instance with a web-search plugin (Perplexica-style)
- A RAG pipeline against your private research corpus
- Chained calls (separate search API → separate synthesis LLM)
- A cached wrapper that stores results by prompt hash and only calls the API on cache miss
- A multi-provider wrapper that tries Perplexity first, falls back to Anthropic on failure

If your wrapper respects the contract, it Just Works with the skill.

## Why this is not called automatically

The skill is **CLI-first** and intentionally portable across CLI agents. Requiring a specific tool (like Claude Code's `WebFetch`) or a specific MCP server setup would break portability. The `PSYCHOHISTORY_RESEARCH_TOOL` env var is an **opt-in escape hatch**: users who want automation configure it; users who don't continue using standard Research Hand-off (manual copy-paste). Both paths produce the same quality of references.md output — the only difference is the human-in-the-loop step.

For MCP integration and direct engine-level API calls, see `../README.md` §CLI-first Design and [`../../../engine/README.md`](../../../engine/README.md) §Planned Capabilities §4.
