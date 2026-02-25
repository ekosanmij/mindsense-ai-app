# MindSense Mobile UI/UX Redesign: Exhaustive Feedback-to-TODO Register

Date: 2026-02-25  
Source document: `/Users/ekosanmi.j/Downloads/MindSense AI Mobile App UI_UX Redesign Analysis.docx`

## Scope

This document translates every concrete feedback item in the redesign analysis into implementation-ready TODOs with:

- explicit action
- code targets
- definition of done
- validation checks

This is intentionally exhaustive and more granular than `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Docs/design/mobile-ui-ux-redesign-implementation-backlog.md`.

Completed items have been removed from this file on purpose.  
Feedback IDs remain non-contiguous to preserve traceability to the original analysis.

## Status Legend

- `[ ]` not started
- `[~]` in progress/partial
- `[x]` completed

---

## A) Cross-Cutting Feedback Translation

### C-01 Hierarchy overload across core screens
- Status: `[~]`
- Source feedback: Equal visual weight across too many modules; scanning cost too high.
- Actionable TODO:
  1. Enforce top-of-screen hierarchy pattern on `Today`, `Regulate`, and `Data`: `headline -> one primary CTA -> compact evidence -> details`.
  2. Introduce per-screen "max top-level modules visible" rule (target: 3 before first scroll).
  3. Remove or collapse non-critical modules from first viewport.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`
- Definition of done:
  - Each screen has exactly one dominant CTA in first viewport.
  - Secondary modules are collapsed/condensed by default.
- Validation:
  - Manual scan test: user can identify state + next action in under 30 seconds.

### C-02 Repeated "More/Less" disclosure noise
- Status: `[x]`
- Source feedback: Repeated "More/Less" controls create an interaction maze.
- Actionable TODO:
  1. Replace generic disclosure labels with context labels (`Details`, `How this is calculated`, `Why this matters`).
  2. Enforce one disclosure control per module.
  3. Remove nested disclosure stacks in glossary/definitions.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`
- Definition of done:
  - No user-facing generic `More`/`Less` in core shell screens.
  - Glossary uses ToC-style navigation or one topic-per-page drill-in.
- Validation:
  - `rg -n "\"More\"|\"Less\"" ...` only returns permitted/internal occurrences.

### C-03 Navigation vs sticky action conflicts
- Status: `[x]`
- Source feedback: Sticky action areas compete with bottom navigation.
- Actionable TODO:
  1. Audit all `safeAreaInset(edge: .bottom)` call sites against tab bar overlay clearance.
  2. Standardize bottom dock offset using shared layout helper only.
  3. Verify no overlap in tab minimized and expanded states.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/MainShellView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`
- Definition of done:
  - Sticky CTA never overlaps tab bar hit region on supported devices.
- Validation:
  - Screenshot QA on compact and large phones; verify no occlusion.

### C-04 Target size and contrast baseline gaps
- Status: `[x]`
- Source feedback: Small controls and subtle non-text contrast risk accessibility issues.
- Actionable TODO:
  1. Enforce minimum 44x44 pt touch targets for interactive controls.
  2. Add contrast audit pass for non-text boundaries and chart indicators.
  3. Add Dynamic Type clipping checks for all primary journeys.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/*.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Scripts/contrast_audit.swift`
- Definition of done:
  - All new/updated controls meet min target size.
  - Contrast pass has no unresolved critical failures.
- Validation:
  - Dynamic Type walkthrough (Large/XL/AX sizes).

### C-05 Banner/tone intrusiveness in calm flows
- Status: `[x]`
- Source feedback: Tall SUCCESS/SYSTEM banners disrupt calm UX and overload top area.
- Actionable TODO:
  1. Replace persistent state banners with inline status lines where possible.
  2. Restrict full banners to blocking events and one-time transitions.
  3. Add severity-to-presentation mapping (inline vs banner vs sheet).
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/FeedbackComponents.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/AppModel.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
- Definition of done:
  - No persistent setup-style banners remain in the normal daily loop.

---

## B) Screen-by-Screen Feedback Translation (All Numbered Callouts)

## B1) Intro

### F-02 "What you get" slab too heavy
- Status: `[x]`
- Actionable TODO:
  1. Convert long slab into tighter three-row summary with shorter copy.
  2. Keep CTA above fold on small devices.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Entry/IntroView.swift`
- Definition of done:
  - CTA remains visible without deep scroll on compact-height devices.

### F-03 Intro vertical density dilutes primary action
- Status: `[x]`
- Actionable TODO:
  1. Reduce vertical spacing between intro hero, value rows, and sign-in CTA.
  2. Ensure visual focus path ends at Sign in with Apple.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Entry/IntroView.swift`
- Definition of done:
  - First viewport clearly emphasizes sign-in action.

## B2) Onboarding (First Check-in)

### F-04 QA-style milestone banner reads non-user-facing
- Status: `[x]`
- Actionable TODO:
  1. Remove instrumentation-style banner copy from onboarding.
  2. Replace with small inline confirmation under relevant step.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Entry/OnboardingView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Entry/InlineStatusView.swift`
- Definition of done:
  - No SUCCESS/Milestone style copy appears in onboarding.

### F-05 Contradictory progress model (step count vs %)
- Status: `[x]`
- Actionable TODO:
  1. Keep one primary progress model.
  2. Remove secondary competing metric from header area.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Entry/OnboardingView.swift`
- Definition of done:
  - Onboarding shows one clear progress indicator only.

### F-06 Slider + selected pill redundancy
- Status: `[x]`
- Actionable TODO:
  1. Remove redundant selected-value chip or demote to tiny helper text.
  2. Keep slider as primary input affordance.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Entry/OnboardingView.swift`
- Definition of done:
  - Current value is clear without duplicate heavy indicator.

### F-07 "Baseline started" tile competes with completion
- Status: `[x]`
- Actionable TODO:
  1. Convert "Baseline started" to inline one-line confirmation.
  2. Keep confirmation adjacent to action the user just took.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Entry/OnboardingView.swift`
- Definition of done:
  - No standalone confirmation tile competes with CTA.

### F-08 CTA competition from extra copy/status blocks
- Status: `[x]`
- Actionable TODO:
  1. Reduce pre-CTA copy block count.
  2. Keep CTA pinned as most visually dominant element in step card.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Entry/OnboardingView.swift`
- Definition of done:
  - Eye-tracking order: step text -> control -> CTA.

## B3) Today Top (State + Do this next)

### F-09 Persistent setup-success banner on Today
- Status: `[x]`
- Actionable TODO:
  1. Remove setup-complete banner after first-time completion.
  2. Replace with lightweight inline status only when needed.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
- Definition of done:
  - Normal returning-user Today has no setup-success banner.

### F-10 Source/update/diagnostics line truncation and priority conflict
- Status: `[x]`
- Actionable TODO:
  1. Move source/update metadata to secondary row or Details sheet.
  2. Prevent truncation of critical metadata labels.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
- Definition of done:
  - Metadata is readable and clearly secondary.

### F-11 Secondary mode switch interrupts one-next-action model
- Status: `[x]`
- Actionable TODO:
  1. Reframe Focus/Recovery/Sleep as secondary filter (not equal-primary action).
  2. Add explanatory label showing what the filter changes.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
- Definition of done:
  - User understands primary action independent of filter changes.

### F-12 KPI cards are over-dense
- Status: `[x]`
- Actionable TODO:
  1. Keep only metric value + short label in hero.
  2. Move threshold bands and metric definitions to Details sheet.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/TrustAndStateComponents.swift`
- Definition of done:
  - Metric row remains readable at large Dynamic Type sizes.

### F-13 "Why this state" not truly collapsed
- Status: `[x]`
- Actionable TODO:
  1. Collapse by default with one disclosure row.
  2. Expand into structured details section, not mixed bullets in primary card.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
- Definition of done:
  - Initial state is concise; expansion is intentional.

## B4) Today Timeline

### F-14 Small timeline pills and semantics ambiguity
- Status: `[x]`
- Actionable TODO:
  1. Increase tap area for timeline pills and legend items to 44x44 hit region.
  2. Add non-color cues (labels/icons) for state differentiation.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
- Definition of done:
  - Timeline controls are usable without relying on color-only semantics.

### F-15 Episode cards contain too many actions
- Status: `[x]`
- Actionable TODO:
  1. Make card itself the primary navigation tap target.
  2. Keep only one inline action when context is missing.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
- Definition of done:
  - Episode list row has max one inline CTA.

### F-16 Repetitive duplicated card action structure
- Status: `[x]`
- Actionable TODO:
  1. Use a shared condensed episode row component with uniform hierarchy.
  2. Remove duplicate repeated tertiary action clusters.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`

### F-17 Redundant details entry points
- Status: `[x]`
- Actionable TODO:
  1. Keep one details route from timeline module.
  2. Remove duplicate "View timeline details" if row tap already opens details.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`

### F-18 Attribution inbox is separate workflow layer
- Status: `[x]`
- Actionable TODO:
  1. Integrate attribution-needed state into episode rows via badge.
  2. Keep inbox as filter/view, not separate competing module.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`

## B5) Episode Detail Sheet

### F-19 "Why we think this" affordance ambiguity
- Status: `[x]`
- Actionable TODO:
  1. Style as explicit row disclosure with chevron and state.
  2. Avoid link-like blue text if behavior is in-card expansion.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`

### F-21 "Edit later" undersized and separated
- Status: `[x]`
- Actionable TODO:
  1. Move into same action group as attribution controls.
  2. Increase touch target to 44x44 minimum.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`

### F-22 Multiple start-entry points risk context drift
- Status: `[x]`
- Actionable TODO:
  1. Define one canonical `Start` entry per context.
  2. Ensure start action always carries source metadata for analytics.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`

### F-23 "Copy prompt" hierarchy too strong
- Status: `[x]`
- Actionable TODO:
  1. Demote to tertiary text action and de-emphasize placement.
  2. Keep as optional utility after primary behavior.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`

## B6) Regulate Select

### F-24 Stepper visual weight competes with content
- Status: `[x]`
- Actionable TODO:
  1. Reduce stepper height/contrast and demote to support element.
  2. Keep primary focus on protocol list.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`

### F-25 Generic "More" on select card duplicates list details
- Status: `[x]`
- Actionable TODO:
  1. Remove generic "More" button on select card.
  2. Route to explicit `Details` only from protocol items.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`

### F-26 No-active-session status card too prominent
- Status: `[x]`
- Actionable TODO:
  1. Convert "No active session" into compact inline status line.
  2. Reserve large cards for actionable content only.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`

### F-27 Protocol text truncation harms trust
- Status: `[x]`
- Actionable TODO:
  1. Enforce minimum 2-line description with consistent line limits.
  2. Add details drill-in for overflow.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`

### F-28 Floating nav icon leaks into content layer
- Status: `[x]`
- Actionable TODO:
  1. Remove floating nav-like controls from content stack.
  2. Keep navigation actions in nav bar/tab bar only.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/MainShellView.swift`

## B7) Regulate Run

### F-29 Tall SYSTEM feedback banner distracts from timer
- Status: `[x]`
- Actionable TODO:
  1. Replace tall run-time banners with compact inline status chip.
  2. Allow detailed logs in secondary disclosure only.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/FeedbackComponents.swift`

### F-30 Load/readiness/flow block can be condensed
- Status: `[x]`
- Actionable TODO:
  1. Compress run meta block into one line or optional details expansion.
  2. Keep timer + next step as highest priority.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`

### F-31 Timer ring non-text contrast risk
- Status: `[x]`
- Actionable TODO:
  1. Validate ring/track contrast against background at 3:1 minimum for UI graphics.
  2. Add fallback high-contrast style for low-contrast themes.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`

### F-32 Step schedule radios are too small
- Status: `[x]`
- Actionable TODO:
  1. Increase interactive area for step schedule controls to 44x44.
  2. Add spacing between adjacent controls.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`

### F-33 Session detail cards too dense during execution
- Status: `[x]`
- Actionable TODO:
  1. Introduce two-mode run view: `Focus` (default) and `Details`.
  2. Move explanatory cards behind details disclosure.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`

## B8) Data Experiments

### F-34 Workspace tab truncation (`Experime...`)
- Status: `[x]`
- Actionable TODO:
  1. Rename tabs to shorter labels (target: `Trends`, `Experiments`, `History`).
  2. Add segmented control layout fallback for long labels.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`

### F-35 Too many filter layers
- Status: `[x]`
- Actionable TODO:
  1. Merge overlapping filter sets.
  2. Move advanced filters to one collapsed row/sheet.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`

### F-36 Meta-pill overload makes card feel like dashboard
- Status: `[x]`
- Actionable TODO:
  1. Limit visible meta pills to top 2 high-value tags.
  2. Move lower-priority metadata to details.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`

### F-37 Duplicate "More" on estimate/rationale
- Status: `[x]`
- Actionable TODO:
  1. Remove duplicate disclosure controls in experiment detail.
  2. Keep one explicit disclosure label for rationale.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`

### F-38 Sticky CTA overlap risk with bottom nav
- Status: `[x]`
- Actionable TODO:
  1. Reserve bottom inset above tab bar for experiment dock.
  2. Disable sticky dock when insufficient available viewport height.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/MainShellView.swift`

## B9) Data Trends

### F-39 Missing clear axis/units framing
- Status: `[x]`
- Actionable TODO:
  1. Add explicit x/y labels and unit labels in visible chart frame.
  2. Ensure selected-point readout includes units.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`

### F-40 Filter pills read as control panel, not narrative
- Status: `[x]`
- Actionable TODO:
  1. Move filters behind collapsible row by default.
  2. Display insight summary before filter controls.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`

### F-41 Export action too visually prominent
- Status: `[x]`
- Actionable TODO:
  1. Demote export to tertiary action in toolbar/secondary area.
  2. Keep insight narrative visually primary.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`

### F-42 Coverage warning has multiple competing actions
- Status: `[x]`
- Actionable TODO:
  1. Keep one primary remediation action in coverage warning.
  2. Move secondary/help actions behind details.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`

### F-43 Floating icon layering confusion (again)
- Status: `[x]`
- Actionable TODO:
  1. Remove decorative floating affordances that look tappable.
  2. Keep action/navigation controls in predictable bars.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`

## B10) Settings

### F-44 Floating back affordance is nonstandard for iOS
- Status: `[x]`
- Actionable TODO:
  1. Use standard navigation back affordance only.
  2. Remove floating circular back from Settings contexts.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/SettingsView.swift`

### F-45 Meeting/call signals needs clearer permission context
- Status: `[x]`
- Actionable TODO:
  1. Add explanatory copy on data used/excluded and permission state.
  2. Add inline current authorization state indicator.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/SettingsView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`

### F-47 Dense toggle styling reduces scannability
- Status: `[x]`
- Actionable TODO:
  1. Increase row spacing and visual grouping for toggle clusters.
  2. Separate critical trust/data settings from general preference toggles.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/SettingsView.swift`

### F-48 Appearance + reduce motion grouping needs stronger semantics
- Status: `[x]`
- Actionable TODO:
  1. Group appearance and motion settings in one clearly labeled section.
  2. Confirm app-level motion setting behavior harmonizes with system Reduce Motion.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/SettingsView.swift`

## B11) Definitions / Terms Sheets

### F-49 "Less" lacks collapse context
- Status: `[x]`
- Actionable TODO:
  1. Replace `Less` with contextual labels (`Hide confidence details`, etc.).
  2. Ensure label describes exact section scope.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`

### F-50 Stacked expanders create reading maze
- Status: `[x]`
- Actionable TODO:
  1. Replace stacked inline disclosures with ToC and dedicated detail views.
  2. Keep one level of expansion maximum.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`

### F-51 Repeated expanders increase cognitive load
- Status: `[x]`
- Actionable TODO:
  1. Convert repeated sections into linked detail pages.
  2. Add "return to glossary" breadcrumb/heading consistency.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`

### F-52 Dense sheet layout impairs scanability
- Status: `[x]`
- Actionable TODO:
  1. Increase section spacing and heading clarity.
  2. Cap paragraph length/line width for readability.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`

### F-53 Ambiguous disclosure semantics across terms
- Status: `[x]`
- Actionable TODO:
  1. Standardize one disclosure pattern and vocabulary for all term sheets.
  2. Enforce shared disclosure component usage.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`

---

## C) Design System Excerpt -> Explicit TODOs (Including Typography Scale)

## C1) Typography Scale

### DS-01 Add explicit type token definitions (Display/Title/Body/BodySmall/Caption)
- Status: `[ ]`
- Source detail: Type.Display 34, Type.Title 22-28, Body 17, BodySmall 15, Caption 13.
- Actionable TODO:
  1. Add/verify token constants for each type role in design system.
  2. Map token roles to SwiftUI text styles that scale with Dynamic Type.
  3. Add line-limit guidance per role (for example Display max 2 lines).
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`
- Definition of done:
  - Typography tokens are centralized and used by shell screens.
  - No hardcoded ad hoc font sizes in updated modules.

### DS-02 Apply type hierarchy to primary screens
- Status: `[ ]`
- Actionable TODO:
  1. Today headline uses Display role.
  2. Section titles use Title role.
  3. Secondary metadata uses BodySmall/Caption only.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/RegulateView.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/DataView.swift`
- Definition of done:
  - Text hierarchy is visually obvious and consistent.

## C2) Color Palette

### DS-03 Add/verify palette tokens and usage constraints
- Status: `[x]`
- Source detail:
  - Primary `#1B6F57`
  - PrimaryTint `#EDF3F2`
  - AccentLoad `#95551F`
  - BG `#F7F8FA`
  - Card `#F3F4F6`
  - TextPrimary `#111111`
  - TextSecondary `#4B5563`
  - Border `#D1D5DB`
- Actionable TODO:
  1. Ensure token parity in `MindSensePalette`.
  2. Replace one-off color literals in shell screens with tokens.
  3. Add notes/guards for contrast-sensitive usage.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/*.swift`
- Definition of done:
  - Updated screens use tokenized colors only.

### DS-04 Contrast validation for text and non-text token pairs
- Status: `[x]`
- Actionable TODO:
  1. Run contrast audit for text on BG/Card, and border/UI graphics.
  2. Adjust token shades or usage thresholds where failing.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Scripts/contrast_audit.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`

## C3) Spacing System

### DS-05 Enforce 4pt spacing scale and layout constants
- Status: `[~]`
- Source detail: 4/8/12/16/20/24/32/40/48, horizontal margins 16/20, card padding 16, inter-section 24-32.
- Actionable TODO:
  1. Add explicit spacing scale constants where missing.
  2. Replace per-screen magic numbers with spacing tokens.
  3. Enforce card padding and inter-section spacing defaults.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/*.swift`
- Definition of done:
  - Updated screens have no spacing literals outside tokens except deliberate exceptions.

## C4) Component States

### DS-06 Primary button spec implementation
- Status: `[x]`
- Source detail: min height 52, radius 20-24, pressed darken ~8-10%, disabled palette, loading spinner.
- Actionable TODO:
  1. Ensure `MindSenseButtonStyle(.primary)` enforces 52 min height and state visuals.
  2. Add explicit loading variant preserving width.
  3. Add optional haptic on press for key actions.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`
- Definition of done:
  - Primary button state matrix (enabled/pressed/disabled/loading) implemented and reused.

### DS-07 Secondary button outline/tinted spec
- Status: `[x]`
- Source detail: 1.5pt border primary, primary text, transparent/tinted fill.
- Actionable TODO:
  1. Align secondary hierarchy visuals to outlined/tinted spec.
  2. Ensure consistent use for non-primary flows only.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/*.swift`

### DS-08 Disclosure spec ("Show details")
- Status: `[x]`
- Source detail: one disclosure per module; replace repeated More/Less.
- Actionable TODO:
  1. Keep `MindSenseSummaryDisclosureText` as standard pattern.
  2. Migrate remaining `MindSenseSummaryMoreText` usages.
  3. Add lint/script check for disallowed generic disclosure copy.
- Code targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/DesignSystem/SurfaceComponents.swift`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/*.swift`

---

## D) Prioritized Recommendation R1-R15 -> Precise Deliverables

### R1 Refocus Today on one decision + one action
- Status: `[x]`
- Deliverables:
  1. Hero stack: headline, one CTA, three metric chips, one details entry.
  2. Responsive metric layout: 3-up at default, vertical stack at larger type sizes.
- Targets:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/MindSense-AI-v1.0.0/Features/Shell/TodayView.swift`

### R2 Replace repeated More/Less with single disclosure system
- Status: `[x]`
- Deliverables:
  1. Complete migration from `MindSenseSummaryMoreText`.
  2. Explicit labels (`Details`, `How this is calculated`).

### R3 Standardize navigation + safe-area behavior
- Status: `[x]`
- Deliverables:
  1. Sticky docks respect tab bar overlay clearance in all states.
  2. No navigation-action control layering ambiguity.

### R4 Enforce CTA hierarchy rules
- Status: `[x]`
- Deliverables:
  1. Max one primary CTA per screen section.
  2. Episode lists avoid multiple primary-grade actions.

### R5 Reduce card nesting
- Status: `[~]`
- Deliverables:
  1. Replace nested cards with section headers + dividers.
  2. Use 16-24 spacing and 1pt dividers internally.

### R6 Fix truncation and label quality
- Status: `[x]`
- Deliverables:
  1. Data mode labels fit without ellipsis at default size.
  2. Minimum horizontal label padding respected.

### R7 Touch target hardening
- Status: `[x]`
- Deliverables:
  1. 44x44 hit areas for info icons, pills, chevrons, compact controls.
  2. Minimum 8pt control separation.

### R8 Clarify attribution feedback language
- Status: `[x]`
- Deliverables:
  1. `Not accurate` copy shipped.
  2. Add optional `Unsure` option and selected-state clarity.

### R9 Regulate run focus mode
- Status: `[x]`
- Deliverables:
  1. Focus mode default (timer + next step only).
  2. Details behind disclosure.

### R10 Data workspace insight-led structure
- Status: `[x]`
- Deliverables:
  1. Insight first, controls second.
  2. Contextual primary action only when recommended.

### R11 Chart accessibility and clarity
- Status: `[x]`
- Deliverables:
  1. Axis labels/units in visible context.
  2. Text summary for screen readers and quick scanning.

### R12 Settings trust-critical ordering
- Status: `[x]`
- Deliverables:
  1. Real privacy URL shipped.
  2. Elevate trust-critical settings (privacy/export/data).

### R13 Avoid surprising heavy system UI launches
- Status: `[x]`
- Deliverables:
  1. Confirmation step before event editor.
  2. Clear intent copy ("Add to calendar").

### R14 Accessibility baseline checks
- Status: `[x]`
- Deliverables:
  1. Contrast, non-text contrast, Dynamic Type, VoiceOver checks completed.
  2. Reduce Motion behavior validated.

### R15 Tokenize components and states
- Status: `[~]`
- Deliverables:
  1. Shared source of truth for spacing/type/radius/state.
  2. Eliminate duplicated style literals in shell screens.

---

## E) QA Checklist Required Before Marking Redesign Done

- [x] Intro + onboarding copy and progress consistency audit
- [x] Today hero one-CTA hierarchy audit
- [x] Timeline single-action row interaction audit
- [x] Regulate focus mode interaction audit
- [x] Data tab label fit audit (no truncation at default type)
- [x] Sticky CTA/tab bar overlap audit across device sizes
- [x] Contrast/non-text contrast pass
- [x] Dynamic Type clipping pass
- [x] VoiceOver labels/hints pass
- [x] Reduce Motion behavior pass
