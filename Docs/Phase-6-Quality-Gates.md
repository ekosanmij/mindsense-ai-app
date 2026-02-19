# MindSense Phase 6 Quality Gates

## 1) Premium UI Acceptance Checklist

Use this checklist per primary screen (`Launch`, `Intro/Auth`, `Onboarding`, `Today`, `Regulate`, `Data`, `Settings`, `Paywall`).

- Contrast:
  - Body text and controls meet WCAG AA (`>= 4.5:1` for normal text, `>= 3:1` for large display text).
  - Selected/CTA text remains readable in both light and dark modes.
- Hierarchy:
  - Visual flow is unambiguous: hero signal -> primary action -> supporting detail.
  - Primary CTA is consistently discoverable without hunting.
- Depth:
  - Surfaces use intentional tiering (`base`, `raised`, `glass`, `focus`) and elevation is not flat or noisy.
  - Accent lighting supports hierarchy, not decoration-only chrome.
- Rhythm:
  - Section spacing follows design rhythm tokens and avoids crowded stacks.
  - Dividers/chunking improve scanability for dense sections.
- Delight:
  - Motion is calm and purposeful (stagger + spring; no erratic jumps).
  - Micro-interactions provide subtle tactile/visual confirmation for key actions.

Gate rule:
- A screen is accepted only if all five categories pass.

## 2) Screenshot QA Matrix (Light/Dark + Small/Large)

Coverage matrix:
- Appearance: `light`, `dark`
- Device size: `small`, `large`
- Captures: `today`, `regulate`, `data`, `settings`

Runner:
- `bash Scripts/design_qa.sh`

Artifacts:
- `Artifacts/phase6-quality-gates/<timestamp>/snapshots-small.xcresult`
- `Artifacts/phase6-quality-gates/<timestamp>/snapshots-large.xcresult`
- Logs in same folder (`*.log`)

## 3) Accessibility Validation

### Contrast

Token-level contrast audit:
- `swift Scripts/contrast_audit.swift`

This checks critical premium pairings used by CTA/selected states and dashboard metrics in light and dark contexts.

### Dynamic Type

UI validation test:
- `MindSenseCoreScreensUITests.testAccessibilityDynamicTypeScaling`

Behavior:
- Launches at accessibility content size (`AXXXL`)
- Verifies key CTAs remain present/hittable
- Attaches snapshots for review

## 4) Interaction Latency + Motion Smoothness

UI performance budget test:
- `MindSenseCoreScreensUITests.testInteractionLatencyAndMotionSmoothnessBudget`

Budget targets:
- Simulator tab transition (max observed): `< 750ms`
- Simulator primary action to state-change confirmation: `< 750ms`

Note:
- These thresholds are for deterministic CI/simulator runs with profiling overhead.
- Device-level performance review should still target sub-second interactions for premium feel.

Output:
- Latency report attached in test results (`interaction_latency_report`)

## 5) UX Regression Checklist

- Content budget:
  - Above-the-fold text <= 75 words on `Today`, `Regulate`, and `Data`.
  - Maximum 1 hero block, 1 primary CTA, and 2 supporting cards before first scroll.
  - Validate with `bash Scripts/copy_budget_lint.sh` before release sign-off.
- Navigation:
  - No duplicate production entrypoints for the same destination.
  - No cyclical flows such as `Settings -> Community -> Profile -> Settings`.
- CTA prominence:
  - Primary CTA must be visible and tappable without first scroll on all core tabs.
  - Secondary actions must not visually outrank the primary CTA.
- Production scope:
  - `Community`, `KPI`, and demo controls are not visible in production builds.

## 6) Staged Shipping Plan

Release in this exact order:
1. Design tokens
2. Shell/components
3. Screen refresh
4. Motion polish

Promotion criteria per stage:
- Stage N cannot ship until stage N quality gates pass and screenshot diffs are reviewed.
- Any regression in contrast, CTA discoverability, or motion accessibility blocks promotion.
