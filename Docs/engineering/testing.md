# MindSense Testing and QA Runbook

This runbook covers unit tests, UI tests, and quality-gate scripts for MindSense AI v1.0.0.

## 1) Test suites

### Unit tests (`MindSense-AI-v1.0.0Tests`)

Primary coverage:

- App launch state routing (`AppStateResolverTests`)
- Recommendation logic (`RecommendationEngineTests`)
- Metric delta logic (`MindSenseDeltaEngineTests`)
- Health-signal model refresh behavior (`DemoHealthSignalEngineTests`)
- Apple sign-in session and identity fallback handling (`AppleSignInSessionFlowTests`)
- Apple session persistence key behavior (`AppleSessionPersistenceTests`)

### UI tests (`MindSense-AI-v1.0.0UITests`)

Primary coverage:

- Core navigation and CTA reachability
- Deterministic Today -> Regulate completion loop
- Data experiment lifecycle
- Snapshot matrix across light/dark
- Dynamic type scaling at accessibility sizes
- Interaction latency budget checks

## 2) Prerequisites

- Xcode with iOS 26.2 simulator runtimes installed
- At least one large iPhone simulator (for default commands):
  - `iPhone 17 Pro Max`

## 3) CLI test commands

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

## 4) UI-test deterministic launch hooks

Launch arguments used by UI tests:

- `-uitest-reset`
- `-uitest-ready`
- `-uitest-system | -uitest-light | -uitest-dark`
- `-uitest-enable-haptics 0|1`
- `-uitest-reduce-motion 0|1`

Dynamic type environment key:

- `UIPreferredContentSizeCategoryName`

Accessibility test uses:

- `UICTContentSizeCategoryAccessibilityXXXL`

## 5) Quality-gate scripts

### Full premium quality gates

```bash
bash Scripts/design_qa.sh
```

This orchestrates:

- Contrast audit (`swift Scripts/contrast_audit.swift`)
- Snapshot capture on small and large devices
- Accessibility dynamic-type test
- Interaction latency and motion smoothness budget test

Artifacts:

- `Artifacts/phase6-quality-gates/<timestamp>/`

### Snapshot helper

```bash
bash Scripts/capture_baselines.sh "iPhone 17" "Artifacts/snapshots-small.xcresult"
```

### Copy budget lint

```bash
bash Scripts/copy_budget_lint.sh
```

## 6) Result bundles and attachments

UI test snapshots and text reports are stored in `.xcresult` bundles produced by `xcodebuild`.

To inspect from Xcode:

1. Open the `.xcresult` bundle.
2. Navigate to test attachments.
3. Review snapshots and latency report attachments.

## 7) Debugging failures

If tests fail:

- Confirm simulator/device name exists in `xcrun simctl list devices available`.
- Re-run with `-uitest-reset` to clear stale app state.
- Verify Apple Sign In capability/signing settings if auth screens behave unexpectedly.
- Check script logs under `Artifacts/phase6-quality-gates/<timestamp>/`.

## 8) Suggested CI sequence

1. Build app target.
2. Run unit tests.
3. Run targeted UI suite.
4. Run `Scripts/design_qa.sh` for UI-sensitive changes.
