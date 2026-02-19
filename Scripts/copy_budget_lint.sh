#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=0

count_words() {
  local file="$1"
  local line_limit="$2"

  sed -n "1,${line_limit}p" "$file" \
    | rg 'Text\("|Button\("|title:\s*"|subtitle:\s*"|detail:\s*"|label:\s*"|metric:\s*"' \
    | rg -v 'accessibilityIdentifier|systemImage|systemName|rawValue|\.title|\.metric|_cta|Profile and access' \
    | rg -o '"[^"]+"' \
    | tr -d '"' \
    | sed 's/[^[:alnum:] ]/ /g' \
    | awk '{ for (i = 1; i <= NF; i++) words++ } END { print words + 0 }'
}

check_budget() {
  local name="$1"
  local file="$2"
  local line_limit="$3"
  local budget="$4"

  local words
  words="$(count_words "$file" "$line_limit")"

  if [[ "$words" -le "$budget" ]]; then
    echo "PASS ${name}: ${words}/${budget} words"
  else
    echo "FAIL ${name}: ${words}/${budget} words"
    failures=$((failures + 1))
  fi
}

check_budget "Today above-the-fold" \
  "${ROOT_DIR}/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift" \
  230 \
  75

check_budget "Regulate above-the-fold" \
  "${ROOT_DIR}/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift" \
  290 \
  75

check_budget "Data above-the-fold" \
  "${ROOT_DIR}/MindSense-AI-v1.0.0/Features/Shell/DataView.swift" \
  250 \
  75

if [[ "$failures" -gt 0 ]]; then
  echo "Copy budget lint failed with ${failures} violation(s)."
  exit 1
fi

echo "Copy budget lint passed."
