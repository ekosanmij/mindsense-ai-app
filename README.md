# MindSense AI v1.0.0

MindSense AI is a local-first iOS SwiftUI app for nervous-system regulation. It gives users a current state snapshot (`Load`, `Readiness`, `Consistency`), recommends one next action, guides a short regulation protocol, then captures outcomes to improve recommendations over time.

This repository contains the iOS app, unit/UI tests, quality-gate scripts, and product/design documentation used to ship v1.0.0.

## Table of contents

1. [Project status](#project-status)
2. [Core product loop](#core-product-loop)
3. [Tech stack](#tech-stack)
4. [Repository structure](#repository-structure)
5. [Prerequisites](#prerequisites)
6. [Quick start (Xcode)](#quick-start-xcode)
7. [Build and test from CLI](#build-and-test-from-cli)
8. [Magic-link auth configuration](#magic-link-auth-configuration)
9. [UI test launch flags](#ui-test-launch-flags)
10. [Quality gates and scripts](#quality-gates-and-scripts)
11. [Architecture notes](#architecture-notes)
12. [Known limitations (current build)](#known-limitations-current-build)
13. [Troubleshooting](#troubleshooting)
14. [Documentation index](#documentation-index)
15. [Contributing](#contributing)
16. [Additional repository docs](#additional-repository-docs)

## Project status

- Version: `1.0.0`
- Targets:
  - `MindSense-AI-v1.0.0` (app)
  - `MindSense-AI-v1.0.0Tests` (unit tests)
  - `MindSense-AI-v1.0.0UITests` (UI tests)
- Deployment target: `iOS 26.2`
- Swift version: `5.0`
- Build configuration: `Debug`, `Release`

## Core product loop

MindSense v1.0.0 is built around a deterministic daily loop:

1. Understand state quickly (`Today`)
2. Run one guided protocol (`Regulate`)
3. Capture outcome and context
4. Track trends and experiments (`Data`)
5. Improve recommendation confidence through repeated use

Primary runtime tabs:

- `Today`
- `Regulate`
- `Data`

Also implemented in codebase (not wired to primary tab navigation by default):

- `Community`
- `QA Tools`
- `KPI Scorecard` (reachable from QA tools)

## Tech stack

- Language: `Swift`
- UI: `SwiftUI` (+ targeted UIKit appearance/haptics integrations)
- Platform: `iOS`
- State container: single `MindSenseStore` (`ObservableObject`)
- Persistence: `UserDefaults` + Codable models
- Auth UX: passwordless email magic-link flow
- Tests: `XCTest` (unit and UI)

## Repository structure

```text
MindSense-AI-v1.0.0/
├── MindSense-AI-v1.0.0/                  # App source
│   ├── Features/
│   │   ├── Entry/                         # Launch, intro, auth, onboarding
│   │   ├── Shell/                         # Today, Regulate, Data, Settings
│   │   └── Shared/
│   ├── DesignSystem/                      # Reusable UI components/tokens
│   ├── AppModel.swift                     # Main store + domain model types
│   ├── MindSensePersistenceService.swift  # Local persistence
│   ├── RecommendationEngine.swift         # Next-action logic
│   ├── MindSenseDeltaEngine.swift         # Deterministic metric deltas
│   └── DemoHealthSignalEngine.swift       # Simulated health signal model
├── MindSense-AI-v1.0.0Tests/              # Unit tests
├── MindSense-AI-v1.0.0UITests/            # UI tests + snapshot coverage
├── Scripts/                               # QA and asset generation scripts
└── Docs/                                  # PRD, design, brand, web blueprint
```

## Prerequisites

- macOS with Xcode supporting iOS 26.2 simulator runtimes
- Command line tools (`xcodebuild`, `xcrun`, `swift`)
- Recommended: at least one small and one large iPhone simulator installed
  - Example from scripts: `iPhone 17` and `iPhone 17 Pro Max`

## Quick start (Xcode)

1. Open `MindSense-AI-v1.0.0.xcodeproj` in Xcode.
2. Select scheme `MindSense-AI-v1.0.0`.
3. Choose an iOS Simulator device.
4. Run the app.

At first launch, routing is:

- `Launch -> Intro -> Auth -> Onboarding -> Main tabs`

For deterministic UI testing and demo-ready state, use launch arguments:

- `-uitest-reset`
- `-uitest-ready`

## Build and test from CLI

Run from repository root.

Build:

```bash
xcodebuild \
  -project MindSense-AI-v1.0.0.xcodeproj \
  -scheme MindSense-AI-v1.0.0 \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  build
```

Run all tests:

```bash
xcodebuild \
  -project MindSense-AI-v1.0.0.xcodeproj \
  -scheme MindSense-AI-v1.0.0 \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  test
```

Run unit tests only:

```bash
xcodebuild \
  -project MindSense-AI-v1.0.0.xcodeproj \
  -scheme MindSense-AI-v1.0.0 \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  -only-testing:MindSense-AI-v1.0.0Tests \
  test
```

Run UI tests only:

```bash
xcodebuild \
  -project MindSense-AI-v1.0.0.xcodeproj \
  -scheme MindSense-AI-v1.0.0 \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  -only-testing:MindSense-AI-v1.0.0UITests \
  test
```

## Magic-link auth configuration

MindSense uses a passwordless magic-link flow and can dispatch either to:

- A generic backend endpoint (`MINDSENSE_MAGIC_LINK_REQUEST_URL`), or
- Supabase OTP endpoint (derived from `MINDSENSE_MAGIC_LINK_API_BASE_URL` when provider includes "supabase")

Set environment variables in your Xcode scheme (`Product -> Scheme -> Edit Scheme -> Run -> Arguments`).

### Required for network dispatch

- `MINDSENSE_MAGIC_LINK_PROVIDER` (example: `Supabase`)
- `MINDSENSE_MAGIC_LINK_API_BASE_URL` or `MINDSENSE_MAGIC_LINK_REQUEST_URL`

If using Supabase direct OTP dispatch:

- `MINDSENSE_MAGIC_LINK_SUPABASE_ANON_KEY` (required)

### Optional routing and behavior

- `MINDSENSE_MAGIC_LINK_REDIRECT_SCHEME` (default: `mindsense`)
- `MINDSENSE_MAGIC_LINK_REDIRECT_HOST` (default: `auth`)
- `MINDSENSE_MAGIC_LINK_REDIRECT_PATH` (default: `/verify`)
- `MINDSENSE_MAGIC_LINK_UNIVERSAL_HOST` (optional)
- `MINDSENSE_MAGIC_LINK_TTL_MINUTES` (default: `15`, clamped `5...60`)
- `MINDSENSE_MAGIC_LINK_RESEND_COOLDOWN_SECONDS` (default: `20`, clamped `5...120`)
- `MINDSENSE_MAGIC_LINK_DEBUG_SHOW_LINK_PREVIEW` (debug helper)
- `MINDSENSE_MAGIC_LINK_DEBUG_AUTO_OPEN` (debug helper)

### Dispatch payload contract (non-Supabase mode)

POST JSON payload:

```json
{
  "email": "user@example.com",
  "intent": "signIn | createAccount",
  "token": "<generated-token>",
  "redirectURL": "mindsense://auth/verify?...",
  "requestedAt": "<ISO8601>",
  "expiresAt": "<ISO8601>"
}
```

## UI test launch flags

The UI test suite seeds deterministic app state through launch arguments:

- `-uitest-reset`
- `-uitest-ready`
- `-uitest-system | -uitest-light | -uitest-dark`
- `-uitest-enable-haptics 0|1`
- `-uitest-reduce-motion 0|1`

Dynamic type tests use environment key:

- `UIPreferredContentSizeCategoryName=UICTContentSizeCategoryAccessibilityXXXL`

Covered UI flows include:

- Core tab navigation (`Today`, `Regulate`, `Data`)
- Settings access path
- Deterministic `Today -> Regulate` outcome loop
- Experiment lifecycle in `Data`
- Snapshot matrix (light/dark)
- Dynamic type accessibility
- Interaction latency budget checks

## Quality gates and scripts

### Full phase-6 quality gates

```bash
bash Scripts/design_qa.sh
```

Runs:

- Contrast audit (`swift Scripts/contrast_audit.swift`)
- Snapshot capture on small and large simulators
- Dynamic type accessibility test
- Interaction latency and motion smoothness test

Artifacts are saved under timestamped directories in `Artifacts/phase6-quality-gates/`.

### Snapshot capture helper

```bash
bash Scripts/capture_baselines.sh "iPhone 17" "Artifacts/snapshots-small.xcresult"
```

### Copy budget lint

```bash
bash Scripts/copy_budget_lint.sh
```

Checks above-the-fold copy budgets for:

- `Today`
- `Regulate`
- `Data`

### App icon generation

```bash
swift Scripts/generate_app_icon.swift
```

Outputs icon/favicons into:

- `MindSense-AI-v1.0.0/Assets.xcassets/AppIcon.appiconset`
- `Docs/brand/logo/generated`

## Architecture notes

- `MindSenseStore` is the main source of truth for app state, domain logic, analytics, and routing signals.
- `AppStateResolver` owns launch-state transitions (`launching`, `signedOut`, `needsOnboarding`, `ready`).
- `MindSensePersistenceService` persists session, onboarding, experiments, regulate sessions, analytics, and demo model state.
- `MindSenseBootstrapService` seeds defaults and supports deterministic launch overrides for UI tests.
- `RecommendationEngine` picks a primary recommendation from scenario + metrics + recent signals.
- `MindSenseDeltaEngine` applies deterministic metric shifts for sessions/experiments.
- `DemoHealthSignalEngine` synthesizes health-quality/profile/timeline/episode data for local modeling.

Data is currently local-first and persisted in `UserDefaults` only.

## Known limitations (current build)

- No real HealthKit ingestion pipeline yet (simulated model signals are used).
- No cloud sync or multi-device account backend in-app.
- No StoreKit purchase/receipt flow in-app (paywall UX only).
- Community and QA surfaces exist in code but are not part of default tab navigation.

## Troubleshooting

- Build fails due to missing simulator:
  - Install iOS 26.2 simulator runtimes and retry with an available device name.
- Magic link request fails immediately:
  - Verify endpoint env vars (`MINDSENSE_MAGIC_LINK_API_BASE_URL` or `MINDSENSE_MAGIC_LINK_REQUEST_URL`).
- Supabase mode fails:
  - Ensure `MINDSENSE_MAGIC_LINK_SUPABASE_ANON_KEY` is set.
- Link verification fails:
  - Check redirect scheme/host/path and deep-link route match.
- UI tests are flaky due to stale local data:
  - Include `-uitest-reset -uitest-ready` launch args.

## Documentation index

- Product as-built PRD: `Docs/product/prd-as-built.md`
- Brand direction: `Docs/design/brand-direction.md`
- Design system: `Docs/design/design-system.md`
- Quality gates: `Docs/quality/quality-gates.md`
- Website blueprint: `Docs/product/website-implementation-blueprint.md`
- Logo system: `Docs/brand/logo/readme.md`
- Runtime architecture guide: `Docs/engineering/architecture.md`
- Testing and QA runbook: `Docs/engineering/testing.md`

## Contributing

1. Create a feature branch.
2. Keep changes scoped and testable.
3. Run relevant unit/UI tests and scripts before opening a PR.
4. Avoid committing local secrets and machine-specific files.

No license file is currently included in this repository. Add one if you plan to distribute publicly under a specific license.

## Additional repository docs

- Contributor guide: `CONTRIBUTING.md`
- Security policy: `SECURITY.md`
- Changelog: `CHANGELOG.md`
