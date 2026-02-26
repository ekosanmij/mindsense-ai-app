# MindSense Marketing Website (`Website/`)

Static marketing site for the MindSense AI v1.0.0 repository. The site is intentionally written as an as-built product page and must stay aligned with implemented app behavior, tests, and docs.

## Files

- `index.html` - primary marketing page
- `styles.css` - shared styles for marketing and legal pages
- `app.js` - progressive enhancement (tabs, FAQ accordion, reveal animations, scroll UI)
- `privacy.html` - website privacy notice + app data posture summary
- `terms.html` - website use terms
- `assets/brand/` - logo and favicon assets
- `assets/screenshots/` - raw screenshots exported from UI-test attachments
- `assets/optimized/` - resized screenshots used by the website

## Local preview

From repo root:

```bash
python3 -m http.server 8080 --directory Website
```

Then open:

- `http://localhost:8080/`

## Update workflow (required order)

### 1) Re-verify product truth before editing copy

Use source + docs, not memory:

- `README.md`
- `Docs/product/prd-as-built.md`
- `Docs/engineering/architecture.md`
- `Docs/quality/quality-gates.md`
- `Docs/engineering/testing.md`
- Relevant Swift files (`TodayView`, `RegulateView`, `DataView`, `SettingsView`, model/persistence/auth files)

Guardrails:

- Do not claim cloud sync / multi-device backend as shipped.
- Do not claim real HealthKit ingestion as shipped (current build uses deterministic demo/local signal model).
- Do not claim StoreKit purchase flow as shipped.
- Preserve wellness/safety boundaries (no medical or emergency replacement claims).

### 2) Refresh screenshots if UI changed

Capture the UI-test snapshot flow on large and small devices (examples):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project MindSense-AI-v1.0.0.xcodeproj \
  -scheme MindSense-AI-v1.0.0 \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  -only-testing:MindSense-AI-v1.0.0UITests/MindSenseCoreScreensUITests/testCoreScreenSnapshots \
  -parallel-testing-enabled NO \
  test \
  -resultBundlePath Artifacts/website-snapshots-large-system-r1.xcresult
```

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project MindSense-AI-v1.0.0.xcodeproj \
  -scheme MindSense-AI-v1.0.0 \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -only-testing:MindSense-AI-v1.0.0UITests/MindSenseCoreScreensUITests/testCoreScreenSnapshots \
  -parallel-testing-enabled NO \
  test \
  -resultBundlePath Artifacts/website-snapshots-small-system-r1.xcresult
```

If simulator preflight is flaky:

```bash
xcrun simctl shutdown all
xcrun simctl erase "iPhone 17"
xcrun simctl erase "iPhone 17 Pro Max"
```

Export attachments from result bundles:

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcresulttool export attachments \
  --path Artifacts/website-snapshots-large-system-r1.xcresult \
  --output-path Artifacts/website-attachments-large-system-r1
```

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcresulttool export attachments \
  --path Artifacts/website-snapshots-small-system-r1.xcresult \
  --output-path Artifacts/website-attachments-small-system-r1
```

### 3) Copy screenshots into website asset folders (stable names)

Map attachments to these filenames:

- `Website/assets/screenshots/today-large.png`
- `Website/assets/screenshots/regulate-large.png`
- `Website/assets/screenshots/data-large.png`
- `Website/assets/screenshots/settings-large.png`
- `Website/assets/screenshots/today-small.png`
- `Website/assets/screenshots/regulate-small.png`
- `Website/assets/screenshots/data-small.png`
- `Website/assets/screenshots/settings-small.png`

### 4) Rebuild optimized images

Current optimized sizes used by the site:

- large: `451x980`
- small: `349x760`

Resize examples:

```bash
sips -Z 980 Website/assets/screenshots/*-large.png --out Website/assets/optimized
sips -Z 760 Website/assets/screenshots/*-small.png --out Website/assets/optimized
```

Verify dimensions:

```bash
for f in Website/assets/optimized/*.png; do
  echo "$f"
  sips -g pixelWidth -g pixelHeight "$f"
done
```

### 5) Update docs and changelog in same PR/commit

When website copy/screenshots change, also update as needed:

- `Docs/product/website-as-built.md`
- `README.md`
- `CHANGELOG.md`

## Validation checklist (before commit)

- Open `http://localhost:8080/` on desktop + mobile viewport.
- Keyboard test tabs and FAQ controls.
- Verify visible focus styles.
- Verify `prefers-reduced-motion` disables auto-rotation/reveal movement.
- Check all footer/legal/GitHub links.
- Confirm screenshots match current app UI test captures.
- Re-read claims against source/docs to avoid overclaiming.

## Related docs

- `Docs/product/website-as-built.md`
- `Docs/product/prd-as-built.md`
- `Docs/quality/quality-gates.md`
- `Docs/engineering/testing.md`

