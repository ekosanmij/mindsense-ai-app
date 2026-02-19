#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/MindSense-AI-v1.0.0.xcodeproj"
SCHEME="MindSense-AI-v1.0.0"
UITEST_TARGET="MindSense-AI-v1.0.0UITests/MindSenseCoreScreensUITests"
ARTIFACT_ROOT="$ROOT_DIR/Artifacts/phase6-quality-gates/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$ARTIFACT_ROOT"

echo "Phase 6 Quality Gates"
echo "Artifact root: $ARTIFACT_ROOT"
echo

STATUS=0

run_step() {
  local name="$1"
  shift
  local log_path="$ARTIFACT_ROOT/${name}.log"

  echo "==> $name"
  set +e
  "$@" >"$log_path" 2>&1
  local code=$?
  set -e

  if [[ $code -ne 0 ]]; then
    echo "❌ $name failed (exit $code). See $log_path"
    STATUS=1
  else
    echo "✅ $name passed"
  fi
  echo
}

pick_device() {
  local list="$1"
  shift
  for candidate in "$@"; do
    if echo "$list" | rg -Fq "$candidate"; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

run_step "contrast-audit" swift "$ROOT_DIR/Scripts/contrast_audit.swift"

SIM_LIST_PATH="$ARTIFACT_ROOT/simctl-devices.txt"
set +e
xcrun simctl list devices available >"$SIM_LIST_PATH" 2>&1
SIM_STATUS=$?
set -e

if [[ $SIM_STATUS -ne 0 ]]; then
  echo "❌ Unable to enumerate simulator devices. See $SIM_LIST_PATH"
  STATUS=1
  exit $STATUS
fi

SIM_LIST="$(cat "$SIM_LIST_PATH")"
SMALL_DEVICE="$(pick_device "$SIM_LIST" \
  "iPhone SE (3rd generation)" \
  "iPhone SE (2nd generation)" \
  "iPhone 13 mini" \
  "iPhone 14" \
  "iPhone 16e" \
  "iPhone 17")" || true
LARGE_DEVICE="$(pick_device "$SIM_LIST" \
  "iPhone 17 Pro Max" \
  "iPhone 16 Pro Max" \
  "iPhone 15 Pro Max" \
  "iPhone 14 Pro Max")" || true

if [[ -z "${SMALL_DEVICE:-}" || -z "${LARGE_DEVICE:-}" ]]; then
  echo "❌ Could not resolve both small and large simulators from available list."
  echo "Small='$SMALL_DEVICE' Large='$LARGE_DEVICE'"
  echo "See $SIM_LIST_PATH"
  STATUS=1
  exit $STATUS
fi

echo "Resolved small device: $SMALL_DEVICE"
echo "Resolved large device: $LARGE_DEVICE"
echo

run_step "snapshots-small-light-dark" \
  bash "$ROOT_DIR/Scripts/capture_baselines.sh" "$SMALL_DEVICE" "$ARTIFACT_ROOT/snapshots-small.xcresult"

run_step "snapshots-large-light-dark" \
  bash "$ROOT_DIR/Scripts/capture_baselines.sh" "$LARGE_DEVICE" "$ARTIFACT_ROOT/snapshots-large.xcresult"

run_step "dynamic-type-accessibility" \
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$LARGE_DEVICE" \
    -resultBundlePath "$ARTIFACT_ROOT/dynamic-type.xcresult" \
    -only-testing:"$UITEST_TARGET/testAccessibilityDynamicTypeScaling" \
    test

run_step "interaction-latency-motion" \
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$LARGE_DEVICE" \
    -resultBundlePath "$ARTIFACT_ROOT/interaction-latency.xcresult" \
    -only-testing:"$UITEST_TARGET/testInteractionLatencyAndMotionSmoothnessBudget" \
    test

if [[ $STATUS -eq 0 ]]; then
  echo "Phase 6 quality gates passed."
else
  echo "Phase 6 quality gates failed. Review logs under $ARTIFACT_ROOT."
fi

exit $STATUS
