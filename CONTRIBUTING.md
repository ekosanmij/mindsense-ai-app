# Contributing to MindSense AI

Thanks for contributing. This project is an iOS SwiftUI app with deterministic domain logic, local-first persistence, and quality gates around UX, accessibility, and interaction performance.

## Ground rules

- Keep changes scoped and reviewable.
- Preserve deterministic behavior used by unit/UI tests.
- Prefer small PRs with clear intent.
- Update docs when behavior, scripts, or configuration changes.

## Prerequisites

- Xcode with iOS 26.2 simulator runtime
- CLI tools: `xcodebuild`, `xcrun`, `swift`
- Repository cloned locally

## Branching and commits

- Create a feature branch from your default branch.
- Use concise commit messages in imperative form.
- Avoid mixing unrelated refactors with feature/bug-fix changes.

Example:

```bash
git checkout -b feat/magic-link-error-handling
```

## Development workflow

1. Read current behavior in:
   - `README.md`
   - `Docs/engineering/architecture.md`
   - `Docs/engineering/testing.md`
2. Implement changes.
3. Run relevant tests locally.
4. Run quality scripts when UI/visual behavior is affected.
5. Open a pull request with a focused summary.

## Required checks before PR

Run at minimum:

```bash
xcodebuild \
  -project MindSense-AI-v1.0.0.xcodeproj \
  -scheme MindSense-AI-v1.0.0 \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  -only-testing:MindSense-AI-v1.0.0Tests \
  test
```

If your change touches UI flow, routing, onboarding/auth, animations, layout, or copy:

```bash
xcodebuild \
  -project MindSense-AI-v1.0.0.xcodeproj \
  -scheme MindSense-AI-v1.0.0 \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
  -only-testing:MindSense-AI-v1.0.0UITests \
  test
```

If your change impacts design system or user-facing visual output:

```bash
bash Scripts/design_qa.sh
```

## Code and architecture expectations

- Keep domain logic testable and deterministic.
- Prefer explicit state transitions over hidden side effects.
- Keep `MindSenseStore` mutations coherent and observable.
- Persist state only through `MindSensePersistenceService`.
- For launch-state routing changes, update `AppStateResolverTests`.
- For recommendation/delta logic changes, update corresponding unit tests.

## Security and secrets

- Never commit private keys, certificates, or production secrets.
- Do not hardcode credentials in source files.
- Use Xcode scheme environment variables for local auth configuration.
- Review `SECURITY.md` for vulnerability handling.

## Pull request checklist

- [ ] Change scope is clear and minimal.
- [ ] Tests added/updated where behavior changed.
- [ ] Relevant unit/UI tests pass locally.
- [ ] Quality-gate scripts run if UI was affected.
- [ ] Docs updated (`README.md`, `Docs/*`) if behavior/config changed.
- [ ] No secrets or machine-specific artifacts were committed.

