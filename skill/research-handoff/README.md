# Research Hand-off

**English** · [中文](./README_CN.md)

> Portable protocol for delegating external research to the user's preferred chat AI with search capability. Independent atomic skill — can be installed and used standalone or composed into larger skills.

## What it does

When an AI skill needs up-to-date information that exceeds its training knowledge, this skill:

1. Generates a structured research prompt (from a template provided by the calling skill)
2. Optionally routes through a wrapper script for fully automated API-based research
3. If no wrapper: emits the prompt for the user to copy-paste into their preferred chat AI
4. Validates the returned content (paste sanity check, format tolerance)
5. Returns structured research results to the calling skill

## Install

This skill lives in the Psychohistory monorepo at `skill/research-handoff/`. To use it standalone, copy this directory to your project's skill folder, or install the full Psychohistory skill set.

*When community demand arises, this will be published as an independent repo for `npx skills add`.*

## Key features

- **Portable**: works across any CLI agent (Claude Code, Cline, Aider, goose, OpenClaw, etc.)
- **No WebFetch dependency**: research happens in the user's chat AI, not via agent-specific tools
- **Wrapper automation**: optional API-based automation via `PSYCHOHISTORY_RESEARCH_TOOL` env var
- **Paste sanity check**: catches Gemini Canvas / ChatGPT Canvas / Claude Artifacts placeholder issues
- **Batch mode**: merge multiple research requests into one copy-paste round-trip
- **Multilingual**: `output_language` parameter controls response language; §N headers stay English for structural recognition
- **Format tolerance**: strict on section recognition, relaxed on sub-structure

## Used by

- `character-toolkit` — for character card generation research phases
- `news-interpreter` — for gathering context and cross-checking facts (planned)
- `theory-test` — for gathering cross-validation evidence (planned)
- Any custom skill that needs external research

## Reference wrapper scripts

Pre-built wrappers in `wrappers/` for Perplexity, Anthropic Claude, OpenAI, and Gemini. See `wrappers/README.md` for setup and the wrapper contract.
