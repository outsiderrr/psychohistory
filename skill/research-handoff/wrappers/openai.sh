#!/usr/bin/env bash
# Psychohistory research wrapper — OpenAI with search-capable model
#
# ⚠️ REFERENCE TEMPLATE — verify API shape and model availability against
#    current OpenAI docs before trusting this for real work. OpenAI's
#    search-capable model lineup changes frequently — if gpt-4o-search-preview
#    is unavailable, try the Responses API with an explicit web_search tool,
#    or a current search-enabled model.
#    See research-wrappers/README.md for verification guidance.
#
# Usage:
#   echo "research prompt" | ./openai.sh
#
# Requires:
#   - $OPENAI_API_KEY environment variable
#   - curl, jq

set -e
set -o pipefail

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "Error: OPENAI_API_KEY environment variable not set" >&2
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

# Uses gpt-4o-search-preview via Chat Completions — it has built-in web browsing.
# If this model is unavailable, try: gpt-4o-mini-search-preview, or use the
# Responses API (/v1/responses) with an explicit {type: "web_search"} tool.
RESPONSE=$(curl -sS --max-time 300 https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -Rn --arg prompt "$PROMPT" '{
    model: "gpt-4o-search-preview",
    messages: [
      {role: "user", content: $prompt}
    ]
  }')")

if [[ -z "$RESPONSE" ]]; then
  echo "Error: empty response from OpenAI API" >&2
  exit 1
fi

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [[ -z "$CONTENT" ]]; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
  if [[ -n "$ERROR" ]]; then
    echo "Error from OpenAI API: $ERROR" >&2
  else
    echo "Error: unexpected response shape from OpenAI API" >&2
    echo "Raw response: $RESPONSE" >&2
  fi
  exit 1
fi

echo "$CONTENT"
