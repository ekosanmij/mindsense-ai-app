#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/MindSense-AI-v1.0.0.xcodeproj"
SCHEME="MindSense-AI-v1.0.0"
TEST_TARGET="MindSense-AI-v1.0.0UITests/MindSenseCoreScreensUITests/testMarketingWebsiteScreenshotExport"

DEVICE_NAME="${1:-iPhone 17}"
OUTPUT_DIR="${2:-$ROOT_DIR/Website/assets/screenshots}"
WORK_DIR="$ROOT_DIR/.tmp/marketing-screenshots/raw"
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

mkdir -p "$WORK_DIR"
rm -f "$WORK_DIR"/*.png 2>/dev/null || true

echo "Running screenshot export test on: $DEVICE_NAME"

echo "Temporary output: $WORK_DIR"

DEVELOPER_DIR="$DEVELOPER_DIR" \
  xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -only-testing:"$TEST_TARGET" \
  test

mkdir -p "$OUTPUT_DIR"
cp "$WORK_DIR"/*.png "$OUTPUT_DIR"/

echo "Copied screenshots to: $OUTPUT_DIR"

OPTIMIZED_DIR="$OUTPUT_DIR/optimized"
mkdir -p "$OPTIMIZED_DIR"
find "$OPTIMIZED_DIR" -type f -name "*.jpg" -delete

for source in "$OUTPUT_DIR"/*.png; do
  [ -e "$source" ] || continue
  base_name="$(basename "$source" .png)"
  sips -s format jpeg -s formatOptions 76 -Z 990 "$source" --out "$OPTIMIZED_DIR/${base_name}-990.jpg" >/dev/null
  sips -s format jpeg -s formatOptions 72 -Z 660 "$source" --out "$OPTIMIZED_DIR/${base_name}-660.jpg" >/dev/null
done

echo "Generated optimized variants in: $OPTIMIZED_DIR"
