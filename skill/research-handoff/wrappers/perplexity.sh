#!/usr/bin/env bash
# Psychohistory research wrapper — Perplexity API
#
# ⚠️ REFERENCE TEMPLATE — verify API shape and model name against current
#    Perplexity docs before trusting this for real work.
#    See research-wrappers/README.md for verification guidance.
#
# Usage:
#   echo "research prompt" | ./perplexity.sh
#
# Requires:
#   - $PERPLEXITY_API_KEY environment variable
#   - curl, jq

set -e
set -o pipefail

if [[ -z "$PERPLEXITY_API_KEY" ]]; then
  echo "Error: PERPLEXITY_API_KEY environment variable not set" >&2
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

# Perplexity Sonar Pro has built-in web search; no additional tool config needed.
RESPONSE=$(curl -sS --max-time 300 https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -Rn --arg prompt "$PROMPT" '{
    model: "sonar-pro",
    messages: [
      {role: "user", content: $prompt}
    ],
    temperature: 0.2
  }')")

if [[ -z "$RESPONSE" ]]; then
  echo "Error: empty response from Perplexity API" >&2
  exit 1
fi

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [[ -z "$CONTENT" ]]; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error // .error_msg // empty')
  if [[ -n "$ERROR" ]]; then
    echo "Error from Perplexity API: $ERROR" >&2
  else
    echo "Error: unexpected response shape from Perplexity API" >&2
    echo "Raw response: $RESPONSE" >&2
  fi
  exit 1
fi

echo "$CONTENT"
