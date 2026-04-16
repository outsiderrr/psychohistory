#!/usr/bin/env bash
# Psychohistory research wrapper — Google Gemini API with search grounding
#
# ⚠️ REFERENCE TEMPLATE — verify API shape, model name, and grounding tool
#    format against current Gemini API docs before trusting this for real work.
#    Google's API shapes change more frequently than others.
#    See research-wrappers/README.md for verification guidance.
#
# Usage:
#   echo "research prompt" | ./gemini.sh
#
# Requires:
#   - $GEMINI_API_KEY (or $GOOGLE_API_KEY) environment variable
#   - curl, jq

set -e
set -o pipefail

API_KEY="${GEMINI_API_KEY:-$GOOGLE_API_KEY}"

if [[ -z "$API_KEY" ]]; then
  echo "Error: neither GEMINI_API_KEY nor GOOGLE_API_KEY environment variable set" >&2
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

# Model: gemini-2.5-pro (or current latest pro model).
# Uses google_search grounding for web research.
RESPONSE=$(curl -sS --max-time 600 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -Rn --arg prompt "$PROMPT" '{
    contents: [
      {
        parts: [
          {text: $prompt}
        ]
      }
    ],
    tools: [
      {google_search: {}}
    ]
  }')")

if [[ -z "$RESPONSE" ]]; then
  echo "Error: empty response from Gemini API" >&2
  exit 1
fi

# Extract all text parts from the first candidate.
CONTENT=$(echo "$RESPONSE" | jq -r '[.candidates[0].content.parts[]? | .text // empty] | join("\n\n")')

if [[ -z "$CONTENT" ]]; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
  if [[ -n "$ERROR" ]]; then
    echo "Error from Gemini API: $ERROR" >&2
  else
    echo "Error: unexpected response shape from Gemini API" >&2
    echo "Raw response: $RESPONSE" >&2
  fi
  exit 1
fi

echo "$CONTENT"
