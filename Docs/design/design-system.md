# MindSense Phase 2 Design System v2

Last updated: 2026-02-26

## Palette Direction
- Dual accents:
  - Cool signal: `signalCool`, `signalCoolStrong`, `signalCoolSoft`
  - Warm glow: `glowWarm`, `glowWarmStrong`, `glowWarmSoft`
- Compatibility aliases retained:
  - `accent`, `accentStrong`, `accentSoft`, `accentMuted`

## Gradient Tokens
- `MindSenseGradients.hero`
- `MindSenseGradients.surface`
- `MindSenseGradients.cta(tint:)`
- `MindSenseGradients.chartFill(color:)`

## Surface Tiers
- `MindSenseSurfaceLevel.base`
- `MindSenseSurfaceLevel.raised`
- `MindSenseSurfaceLevel.glass`
- `MindSenseSurfaceLevel.focus`

## Elevation Tokens
- Rich dual-shadow model:
  - ambient: `ambientColor`, `ambientRadius`, `ambientY`
  - directional: `directionalColor`, `directionalRadius`, `directionalX`, `directionalY`
- Levels: `none`, `base`, `raised`, `focus`

## Radius System
- `MindSenseRadius.tight`
- `MindSenseRadius.medium`
- `MindSenseRadius.large`
- `MindSenseRadius.pill`
- Existing aliases still supported: `chip`, `tile`, `card`

## Stroke and Shine Tokens
- `strokeSubtle`
- `strokeStrong`
- `strokeEdge`
- `strokeFocus`
- `shineTop`
- `shineEdge`

## Typography and Numeric Treatment
- Premium hierarchy:
  - serif-led headlines: `display`, `hero`
  - clean UI/body hierarchy: `title`, `titleCompact`, `bodyStrong`, `body`, `caption`, `micro`
- Data/metric typography:
  - `metric`, `metricDisplay`, `metricBody`, `metricCaption`
- Current redesign decision:
  - Explicit DS typography role migration tickets (`DS-01`, `DS-02`) are deferred for now and tracked as skipped in the redesign TODO register.

## Component Usage Rules
- `MindSenseCommandDeck`:
  - Use at most once per screen.
  - Place as the first module and pair with one primary CTA path.
- `MindSenseSegmentedControl`:
  - Default to full-width segments for primary navigation clusters.
  - For compact hero selectors (for example `Trends / Experiments / History`), use `fillAvailableWidth: false` and `containerInset: 0` to avoid oversized header regions.
  - Keep labels short and unambiguous; prefer fallback scrolling only when labels cannot fit at default type size.
- `MindSenseSectionHeader`:
  - Use no more than 3 times on core tabs (`Today`, `Regulate`, `Data`, `Settings`).
  - Prefer concise subtitle copy over stacked explanatory paragraphs.
- `DisclosureGroup`:
  - Reserve for optional deep detail only.
  - Do not place required instructions or primary actions inside disclosures.
