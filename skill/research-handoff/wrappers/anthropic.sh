#!/usr/bin/env bash
# Psychohistory research wrapper — Anthropic Claude API with web_search tool
#
# ⚠️ REFERENCE TEMPLATE — verify API shape, tool version, and model name against
#    current Anthropic docs before trusting this for real work.
#    See research-wrappers/README.md for verification guidance.
#
# Usage:
#   echo "research prompt" | ./anthropic.sh
#
# Requires:
#   - $ANTHROPIC_API_KEY environment variable
#   - curl, jq

set -e
set -o pipefail

if [[ -z "$ANTHROPIC_API_KEY" ]]; then
  echo "Error: ANTHROPIC_API_KEY environment variable not set" >&2
  exit 1
fi

for tool in curl jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: required tool '$tool' not found in PATH" >&2
    exit 1
  fi
done

PROMPT=$(cat)

if [[ -z "$PROMPT" ]]; then
  echo "Error: no prompt received on stdin" >&2
  exit 1
fi

# Model: Claude Sonnet 4.5 (or later) recommended for research tasks.
# Web search tool type: web_search_20250305 (as of 2025-05; check for newer versions).
RESPONSE=$(curl -sS --max-time 600 https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$(jq -Rn --arg prompt "$PROMPT" '{
    model: "claude-sonnet-4-5",
    max_tokens: 8192,
    tools: [
      {
        type: "web_search_20250305",
        name: "web_search",
        max_uses: 10
      }
    ],
    messages: [
      {role: "user", content: $prompt}
    ]
  }')")

if [[ -z "$RESPONSE" ]]; then
  echo "Error: empty response from Anthropic API" >&2
  exit 1
fi

# Extract all text blocks from the content array (ignore tool_use / tool_result blocks).
CONTENT=$(echo "$RESPONSE" | jq -r '[.content[]? | select(.type == "text") | .text] | join("\n\n")')

if [[ -z "$CONTENT" ]]; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
  if [[ -n "$ERROR" ]]; then
    echo "Error from Anthropic API: $ERROR" >&2
  else
    echo "Error: unexpected response shape from Anthropic API" >&2
    echo "Raw response: $RESPONSE" >&2
  fi
  exit 1
fi

echo "$CONTENT"
