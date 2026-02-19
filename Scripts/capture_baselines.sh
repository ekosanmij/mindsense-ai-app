#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/MindSense-AI-v1.0.0.xcodeproj"
SCHEME="MindSense-AI-v1.0.0"
TEST_TARGET="MindSense-AI-v1.0.0UITests/MindSenseCoreScreensUITests/testCoreScreenSnapshotsAcrossAppearances"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <device-name> <result-bundle-path>"
  exit 2
fi

DEVICE_NAME="$1"
RESULT_BUNDLE="$2"

echo "Capturing snapshot matrix on device: $DEVICE_NAME"
echo "Result bundle: $RESULT_BUNDLE"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -resultBundlePath "$RESULT_BUNDLE" \
  -only-testing:"$TEST_TARGET" \
  test
