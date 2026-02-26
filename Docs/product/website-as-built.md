# MindSense Website (As Built)

Last updated: 2026-02-26

## 1) Purpose and scope

This document describes the static marketing website shipped in `Website/` for the MindSense AI v1.0.0 repository.

Scope of this document:

- Information architecture (IA) and content boundaries
- Static-site implementation architecture (`index.html`, `styles.css`, `app.js`, legal pages)
- Interaction model and accessibility behavior
- Screenshot asset mapping from UI-test artifacts to website assets
- Maintenance workflow for keeping website claims aligned with implemented product behavior

Non-scope:

- App runtime architecture (covered in `Docs/engineering/architecture.md`)
- Product requirements/history (covered in `Docs/product/prd-as-built.md`)
- UI quality-gate definitions (covered in `Docs/quality/quality-gates.md`)

Notes:

- No prior website documentation existed in this repository before this as-built doc (checked on 2026-02-26).
- This website intentionally describes the shipped/repo state only and avoids roadmap promises.

## 2) Source-of-truth inputs used for website claims

Website copy and claims were derived from the following repository sources before implementation:

- Root docs:
  - `README.md`
  - `Docs/product/prd-as-built.md`
  - `Docs/engineering/architecture.md`
  - `Docs/design/design-system.md`
  - `Docs/design/brand-direction.md`
  - `Docs/quality/quality-gates.md`
  - `Docs/engineering/testing.md`
- App source (selected product-truth surfaces):
  - `MindSense-AI-v1.0.0/AppModel.swift`
  - `MindSense-AI-v1.0.0/AppStateResolver.swift`
  - `MindSense-AI-v1.0.0/MindSensePersistenceService.swift`
  - `MindSense-AI-v1.0.0/RecommendationEngine.swift`
  - `MindSense-AI-v1.0.0/DemoHealthSignalEngine.swift`
  - `MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
  - `MindSense-AI-v1.0.0/Features/Shell/DataView.swift`
  - `MindSense-AI-v1.0.0/Features/Shell/SettingsView.swift`
- UI tests and screenshot tooling:
  - `MindSense-AI-v1.0.0UITests/MindSenseCoreScreensUITests.swift`
  - `Scripts/capture_baselines.sh`
  - `Scripts/design_qa.sh`

## 3) Website implementation architecture

### 3.1 File layout

```text
Website/
├── index.html                 # Primary marketing page
├── styles.css                 # Shared styling (marketing + legal pages)
├── app.js                     # Progressive enhancement interactions
├── privacy.html               # Website privacy notice + app data posture summary
├── terms.html                 # Website use terms
├── README.md                  # Local preview and maintenance workflow
└── assets/
    ├── brand/                 # Logo lockups + favicons
    ├── screenshots/           # Source PNGs exported from UI-test attachments
    └── optimized/             # Web-resized PNGs used by pages
```

### 3.2 Rendering model

- Static HTML/CSS/JS only (no framework/build step required).
- `styles.css` is shared by `index.html`, `privacy.html`, and `terms.html`.
- `app.js` progressively enhances `index.html` only (no blocking dependency for core reading/navigation).
- Website uses optimized PNGs for page rendering and keeps source screenshots in `assets/screenshots/` for traceability.

### 3.3 Performance choices

- Hero screenshot loads eagerly; below-the-fold screenshots use `loading="lazy"` and `decoding="async"`.
- Screenshot dimensions are declared (`451x980`, `349x760`) to reduce layout shift.
- Optimized images are resized from UI-test exports before use on the page.
- No external JS libraries are used.

## 4) Information architecture (IA)

The website is intentionally structured to support product evaluation, stakeholder diligence, and investor review while staying within as-built boundaries.

### 4.1 Primary page (`Website/index.html`)

1. Hero
- Product positioning (local-first iOS app for nervous-system regulation)
- CTAs to walkthrough and GitHub/docs
- Wellness boundary note (non-medical / non-emergency)
- At-a-glance proof strip (auth, storage, core tabs, test coverage)
- Interactive screenshot preview rail (`Today`, `Regulate`, `Data`, `Settings`)

2. Product overview + proof metrics
- What ships in v1.0.0
- Intentional scope boundaries (no cloud sync, no real HealthKit ingestion, no StoreKit flow)
- As-built proof metrics (tab count, onboarding steps, presets, QA matrix count, latency budget)

3. Core loop
- Understand state → Regulate → Outcome capture → Data review → Repeat
- Clarifies what improves over time vs what remains explicit/bounded

4. App walkthrough (section-by-section)
- `Today`: state snapshot, drivers, confidence/coverage, check-in/context, timeline details
- `Regulate`: preset protocol goals, progress/completion, outcome submission
- `Data`: `Trends`, `Experiments`, `History`, evidence for repeated use
- `Settings`: privacy/data controls, permission/remediation, metadata boundary, safety/support
- Each panel uses real UI-test screenshots (large + small capture variants)

5. Audience-specific sections
- Prospective users
- Stakeholders (product/clinical ops/design/QA)
- Investors

6. Trust / safety / quality posture
- Wellness boundaries
- Local-first data posture
- Permission/metadata transparency
- QA/accessibility quality gates

7. FAQ
- Answers grounded to the repo state (date-stamped)

8. Contact / conversion
- GitHub repo, issues, as-built PRD, website as-built doc

9. Footer
- Legal links (`privacy.html`, `terms.html`) and GitHub link

### 4.2 Legal pages

- `privacy.html`: static-site privacy notice + app data posture summary (as built)
- `terms.html`: website use terms and non-medical / no-emergency disclaimers

## 5) Interaction model (`Website/app.js`)

All interactive behaviors are progressively enhanced and degrade to readable static content.

### 5.1 Header / navigation

- Sticky header with scroll-state styling
- Mobile navigation toggle (disclosure button, `aria-expanded` updates)
- Scroll progress bar indicating reading progress through the page
- Back-to-top button shown after scroll threshold

### 5.2 Hero screenshot preview

- Tab-like button rail controls the active hero screenshot (`Today`, `Regulate`, `Data`, `Settings`)
- Keyboard navigation support (`Arrow` keys, `Home`, `End`)
- Auto-rotation timer (disabled when `prefers-reduced-motion` is active)
- Auto-rotation pauses on hover/focus and resumes after interaction

### 5.3 Walkthrough tab panels

- `role="tablist"` / `role="tab"` / `role="tabpanel"` semantics
- Mouse and keyboard tab switching
- Hidden inactive panels to reduce focus noise

### 5.4 FAQ accordion

- Button-triggered sections with `aria-expanded` and `aria-controls`
- Single-open behavior (opening one closes others)

### 5.5 Reveal + metric counters

- `IntersectionObserver`-based reveal animations for sections/cards
- Count-up animation for proof metrics
- Both degrade gracefully when JS APIs are unavailable

## 6) Accessibility and UX considerations

Implemented in the website:

- Semantic landmarks (`header`, `main`, `section`, `footer`, `nav`, `article`)
- Skip link to main content
- Visible focus states (`:focus-visible`)
- Keyboard-operable tabs and FAQ controls
- Reduced-motion support via CSS `prefers-reduced-motion` and JS auto-rotation disable
- Responsive layout across desktop/tablet/mobile
- High-contrast color palette aligned to MindSense brand tones (`#56D3FF`, dark navy base)

## 7) Screenshot asset mapping (UI-test exports → website assets)

### 7.1 Snapshot source runs used for this website refresh (2026-02-26)

UI-test result bundles captured:

- `Artifacts/website-snapshots-large-system-r1.xcresult`
- `Artifacts/website-snapshots-small-system-r1.xcresult`

Attachment exports produced via `xcresulttool`:

- `Artifacts/website-attachments-large-system-r1/`
- `Artifacts/website-attachments-small-system-r1/`

Exported attachment names (both sizes):

- `today.png`
- `regulate.png`
- `data.png`
- `settings.png`

### 7.2 Website file mapping

| Website optimized asset | Website source screenshot | Exported attachment source | App surface |
|---|---|---|---|
| `Website/assets/optimized/today-large.png` | `Website/assets/screenshots/today-large.png` | `Artifacts/website-attachments-large-system-r1/today.png` | `Today` |
| `Website/assets/optimized/regulate-large.png` | `Website/assets/screenshots/regulate-large.png` | `Artifacts/website-attachments-large-system-r1/regulate.png` | `Regulate` |
| `Website/assets/optimized/data-large.png` | `Website/assets/screenshots/data-large.png` | `Artifacts/website-attachments-large-system-r1/data.png` | `Data` |
| `Website/assets/optimized/settings-large.png` | `Website/assets/screenshots/settings-large.png` | `Artifacts/website-attachments-large-system-r1/settings.png` | `Settings` |
| `Website/assets/optimized/today-small.png` | `Website/assets/screenshots/today-small.png` | `Artifacts/website-attachments-small-system-r1/today.png` | `Today` |
| `Website/assets/optimized/regulate-small.png` | `Website/assets/screenshots/regulate-small.png` | `Artifacts/website-attachments-small-system-r1/regulate.png` | `Regulate` |
| `Website/assets/optimized/data-small.png` | `Website/assets/screenshots/data-small.png` | `Artifacts/website-attachments-small-system-r1/data.png` | `Data` |
| `Website/assets/optimized/settings-small.png` | `Website/assets/screenshots/settings-small.png` | `Artifacts/website-attachments-small-system-r1/settings.png` | `Settings` |

### 7.3 Resize profile currently used

- Large images resized to `451x980`
- Small images resized to `349x760`

(These dimensions match the current optimized assets used by the site.)

## 8) Maintenance workflow (content + screenshots)

### 8.1 Re-verify product truth before copy changes

Before editing website claims:

1. Re-read `README.md` and `Docs/product/prd-as-built.md`.
2. Confirm feature state in relevant Swift files (especially `TodayView`, `RegulateView`, `DataView`, `SettingsView`).
3. Re-check `Docs/quality/quality-gates.md` and `Docs/engineering/testing.md` before citing QA metrics.
4. Update the website date references if the refresh date changes.

### 8.2 Refresh screenshots (UI-test workflow)

Run from repo root. Example commands (use installed simulator names):

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

If simulator launches are flaky, try:

```bash
xcrun simctl shutdown all
xcrun simctl erase "iPhone 17"
xcrun simctl erase "iPhone 17 Pro Max"
```

Export attachments from the `.xcresult` bundles (tool path may vary by Xcode install):

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

### 8.3 Copy and optimize assets

Copy exported files into website source screenshot folders with stable names, then resize to optimized assets.

Example resize commands used for current site:

```bash
sips -Z 980 Website/assets/screenshots/*-large.png --out Website/assets/optimized
sips -Z 760 Website/assets/screenshots/*-small.png --out Website/assets/optimized
```

Verify dimensions after resize:

```bash
for f in Website/assets/optimized/*.png; do
  echo "$f"
  sips -g pixelWidth -g pixelHeight "$f"
done
```

### 8.4 Update website copy/docs in the same change set

When screenshots or claims change, update together:

- `Website/index.html`
- `Website/privacy.html` and `Website/terms.html` (if scope/privacy posture changes)
- `Website/README.md`
- `Docs/product/website-as-built.md`
- `README.md` and `CHANGELOG.md` (if repository-visible behavior/docs changed)

## 9) Content guardrails (must preserve)

- Do not claim unimplemented integrations as shipped (for example: cloud sync, real HealthKit ingestion, StoreKit purchases).
- Keep wellness/safety boundaries explicit; do not imply clinical diagnosis/treatment claims.
- Distinguish app behavior from website behavior (especially privacy/analytics statements).
- Use exact dates when describing the as-built snapshot if the user asks for "current" behavior.

