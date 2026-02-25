#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${ROOT_DIR}/MindSense-AI-v1.0.0"

failures=0

check_forbidden_pattern() {
  local name="$1"
  local pattern="$2"
  local output

  output="$(rg -n --glob '*.swift' "$pattern" "$SOURCE_ROOT" || true)"
  if [[ -n "$output" ]]; then
    echo "FAIL ${name}"
    echo "$output"
    failures=$((failures + 1))
  else
    echo "PASS ${name}"
  fi
}

check_forbidden_pattern \
  "deprecated MindSenseSummaryMoreText usage" \
  "MindSenseSummaryMoreText"

check_forbidden_pattern \
  "generic disclosure labels (More/Less)" \
  '(collapsedLabel|expandedLabel):\s*"(More|Less)"'

check_forbidden_pattern \
  "plain generic disclosure buttons (More/Less)" \
  'Button\("More"\)|Button\("Less"\)'

if [[ "$failures" -gt 0 ]]; then
  echo "Disclosure lint failed with ${failures} violation(s)."
  exit 1
fi

echo "Disclosure lint passed."
