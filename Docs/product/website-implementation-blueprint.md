# MindSense Showcase Website: Component Inventory and Wireframe Blueprint

Date: February 19, 2026
Source alignment:
- `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Docs/product/prd-as-built.md`
- `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Docs/design/brand-direction.md`
- `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Docs/design/design-system.md`
- `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Docs/quality/quality-gates.md`

## 1) Build assumptions

- Framework: Next.js (App Router) + TypeScript.
- Styling: CSS variables + utility classes or CSS modules.
- Content: structured JSON or MDX in repo (can be replaced by CMS later).
- Analytics: event naming aligned with app (`screen_view`, `primary_cta_tapped`, etc.).
- Accessibility target: WCAG AA.

## 2) Suggested app structure

```text
app/
  (marketing)/
    page.tsx                        # Home
    product/page.tsx
    product/today/page.tsx
    product/regulate/page.tsx
    product/data/page.tsx
    protocols/page.tsx
    how-it-works/page.tsx
    privacy/page.tsx
    pricing/page.tsx
    faq/page.tsx
    support/page.tsx
    updates/page.tsx
    legal/privacy-policy/page.tsx
    legal/terms/page.tsx
components/
  shell/
  sections/
  cards/
  charts/
  nav/
  forms/
  trust/
  motion/
content/
  protocols/*.json
  faqs/*.json
  pages/*.mdx
  trust/*.json
lib/
  analytics.ts
  content.ts
  seo.ts
  a11y.ts
styles/
  tokens.css
  globals.css
```

## 3) Design tokens (website source of truth)

Implement the app-matching surface model and semantic color usage.

```css
:root {
  --bg-base: #eff0f2;
  --surface-raised: #f7f8fa;
  --surface-muted: #e9ecf2;
  --surface-glass: rgba(255, 255, 255, 0.64);
  --surface-focus: #f6f9fc;
  --border-subtle: #dadde3;
  --text-primary: #0b0b0c;
  --text-secondary: #5b616b;
  --primary: #176e9b;
  --primary-hover: #0f5d85;
  --focus-ring: #7cc9dd;
  --readiness: #1f8b4c;
  --load: #b36a1e;
  --consistency: #1d6fb2;
  --radius-card-lg: 24px;
  --radius-card-md: 16px;
  --radius-pill: 999px;
  --space-section-y: 88px;
  --space-section-y-mobile: 56px;
}

[data-theme="dark"] {
  --bg-base: #0b0f14;
  --surface-raised: #151a21;
  --surface-muted: #11161d;
  --surface-glass: rgba(21, 26, 33, 0.72);
  --surface-focus: #1f2830;
  --border-subtle: #27303b;
  --text-primary: #ffffff;
  --text-secondary: #b4bbc6;
  --primary: #92d5e9;
  --primary-hover: #7cc9dd;
  --focus-ring: #92d5e9;
  --readiness: #70e0b2;
  --load: #ecb860;
  --consistency: #78d5f7;
}
```

## 4) Component inventory (implementation ready)

All components below include required states, props, and responsive rules.

### 4.1 Shell components

#### `SiteHeader`
- Purpose: sticky global nav with glass surface.
- Props:
  - `items: NavItem[]`
  - `primaryCta: CTA`
  - `secondaryCta?: CTA`
  - `themeModeEnabled?: boolean`
  - `showBottomAnchorNav?: boolean`
- States:
  - `default | scrolled | menuOpen`
- Responsive:
  - Desktop: inline nav.
  - Mobile: hamburger + collapsible drawer.
  - If `showBottomAnchorNav` and page is long-form (`home`, `product`), show `BottomAnchorPillNav`.
- Events:
  - `secondary_action_tapped` for nav link clicks.
  - `primary_cta_tapped` for primary header CTA.

#### `BottomAnchorPillNav`
- Purpose: mobile anchor nav for Today / Regulate / Data sections.
- Props:
  - `anchors: {id: string; label: "Today" | "Regulate" | "Data"}[]`
  - `activeId: string`
- States: `visible | hiddenOnScrollDown`.
- A11y:
  - `<nav aria-label="Section navigation">`.
  - Keyboard focusable chip buttons.

#### `SiteFooter`
- Purpose: trust/legal/disclaimer close.
- Props:
  - `groups: FooterLinkGroup[]`
  - `showCrisisDisclaimer: boolean`
- Required content:
  - Safety resources link.
  - Non-emergency disclaimer line.

### 4.2 Core layout primitives

#### `PageContainer`
- Props: `maxWidth?: 1120 | 1200`, `withGutter?: boolean`.
- Responsive: 12-col desktop, 4-col mobile.

#### `SectionBlock`
- Props:
  - `id?: string`
  - `surface?: "base" | "raised" | "glass" | "focus"`
  - `eyebrow?: string`
  - `title: string`
  - `subtitle?: string`
- Variants: default, full-bleed, dense.

#### `SurfaceCard`
- Props:
  - `tone?: "standard" | "focus" | "accent" | "warning"`
  - `radius?: "lg" | "md"`
  - `padding?: "sm" | "md" | "lg"`
  - `interactive?: boolean`
- States:
  - `default | hover | active | selected | disabled`.

### 4.3 Navigation and action components

#### `PrimaryButton`
- Props:
  - `label: string`
  - `href?: string`
  - `onClick?: () => void`
  - `size?: "md" | "lg"`
  - `fullWidth?: boolean`
- Size rules:
  - min height 48 desktop, 46 mobile.

#### `SecondaryButton`
- Same API as `PrimaryButton`, muted surface style.

#### `PillChip`
- Props:
  - `label: string`
  - `state: "default" | "selected" | "disabled"`
  - `onClick?: () => void`
- Use cases:
  - Step chips.
  - Duration/metadata chips.
  - Filter chips.

#### `SegmentedControl<T>`
- Props:
  - `options: T[]`
  - `value: T`
  - `onChange: (v: T) => void`
  - `getLabel: (v: T) => string`
- Keyboard:
  - Arrow keys cycle.
  - Enter/Space select.

### 4.4 Hero and product-loop modules

#### `HeroStateCard`
- Purpose: homepage H1.
- Props:
  - `tagline: string`
  - `headline: string`
  - `subhead: string`
  - `primaryCta: CTA`
  - `secondaryCta: CTA`
  - `media: DeviceMedia`
  - `whyState: WhyStateContent`
- States:
  - `mediaPlaying | mediaPaused`
  - `whyCollapsed | whyExpanded | whyModalOpen`
- Required interaction:
  - Inline disclosure or modal for `Why this state`.

#### `LoopTriadCardGrid`
- Purpose: H2 Today / Regulate / Data.
- Props:
  - `items: LoopCardItem[]` (exactly 3).
- Responsive:
  - 3 columns desktop, 1 column mobile.

#### `NextBestActionPanel`
- Purpose: H3 proof of "one mapped action".
- Props:
  - `presetName: string`
  - `durationMinutes: number`
  - `reason: string`
  - `expectedEffect: string`
  - `cta: CTA`
- Content rule:
  - Never render multiple action options in this panel.

#### `ProtocolPreviewGrid`
- Purpose: H4 protocol preview.
- Props:
  - `protocols: ProtocolSummary[]` (3 on home).
  - `browseCta: CTA`.

#### `DataWorkspacePreview`
- Purpose: H5 segmented Trends / Experiments / History preview.
- Props:
  - `tabs: ("Trends" | "Experiments" | "History")[]`
  - `activeTab: ...`
  - `onTabChange: ...`
  - `trendPreview: TrendPreviewData`
  - `experimentPreview: ExperimentPreviewData`
  - `historyPreview: HistoryPreviewData`
- Interaction:
  - Desktop: hover scrub in trend preview.
  - Mobile: tap marker.
  - Reduced motion: static fallback.

#### `TrustTileStrip`
- Purpose: H6 trust and safety strip.
- Props:
  - `tiles: TrustTile[]` (3-4 items).
  - `safetyLink: CTA`.

### 4.5 Page-specific modules

#### `TodayCommandDeckShowcase`
- Props:
  - `stateLabel: string`
  - `sourceLine: string`
  - `deltaMetrics: DeltaMetric[]`
  - `interpretation: string`
  - `referenceLine: string`
  - `whyState: WhyStateContent`
  - `nextAction: NextBestAction`
  - `timeline: TimelinePreview`
  - `contextCapture: ContextCapturePreview`
- Optional slots:
  - `drivers`, `statusSnapshot`, `quickCheckIn`.

#### `RegulateThreeStepFlow`
- Props:
  - `steps: ["Select", "Run", "Record"]`
  - `currentStep?: 1 | 2 | 3`
  - `protocols: ProtocolSummary[]`
  - `sessionPreview: SessionPreview`
  - `impactFields: ImpactFieldDef[]`
- States:
  - `idle`, `runningSession`, `awaitingRecord`.
- Special behavior:
  - Demo mode may hide global nav while "Run" demo is active.

#### `DataModeShowcase`
- Props:
  - `mode: "Trends" | "Experiments" | "History"`
  - `onModeChange`
  - `trendModule: TrendModuleData`
  - `experimentsModule: ExperimentsModuleData`
  - `historyModule: HistoryModuleData`

#### `TrendChartModule`
- Props:
  - `points: TrendPoint[]`
  - `window: "7D" | "14D" | "30D"`
  - `onWindowChange`
  - `selectedPoint?: TrendPoint`
  - `onPointSelect`
  - `confidencePercent: number`
  - `coveragePercent: number`
- States:
  - `loading`, `ready`, `empty`.
- A11y:
  - Text summary for selected point.

#### `ExperimentsLifecycleModule`
- Props:
  - `items: ExperimentCardData[]`
  - `selectedId?: string`
  - `onSelect`
  - `primaryAction: Start | LogDay | Complete`
- Lifecycle:
  - `planned -> active -> completed`.

#### `HistoryWeeklySummaryModule`
- Props:
  - `wins: string[]`
  - `risks: string[]`
  - `nextBestAction: string`
  - `whatWorking: WhatWorkingSummary`
  - `timelineItems: HistoryEvent[]`.

#### `ProtocolLibraryGrid`
- Props:
  - `filters: ProtocolFilterState`
  - `onFilterChange`
  - `protocols: Protocol[]`
  - `onOpenDetail`
- Includes:
  - scenario/goal/duration chips.
  - protocol detail drawer/modal.

#### `HowItWorksLoopDiagram`
- Props:
  - `nodes: LoopNode[]`
  - `confidenceBands: ConfidenceBand[]`
  - `sampleModes: SampleMode[]`.

#### `PrivacyDataCategoriesTable`
- Props:
  - `categories: DataCategory[]`
  - `postureStatement: string`
  - `nonEmergencyStatement: string`
  - `policyLinks`.

#### `PricingPlanCards`
- Props:
  - `plans: PricingPlan[]`
  - `trial: TrialTerms`
  - `ctaPrimary: CTA`
  - `ctaSecondary?: CTA`.

#### `FaqAccordion`
- Props:
  - `items: FAQItem[]`
  - `allowMultipleOpen?: boolean`.
- Required entries:
  - Readiness/Load/Consistency.
  - Confidence.
  - Privacy.
  - Medical advice boundary.
  - Crisis handling.

#### `SupportContactForm`
- Props:
  - `actionUrl: string`
  - `fields: ("name" | "email" | "message")[]`
  - `showDataControlsLinks: boolean`.

### 4.6 Motion wrappers

#### `RevealOnScroll`
- Props:
  - `delayMs?: number`
  - `distanceY?: number` default 8
  - `durationMs?: number` default 180
- Reduced motion:
  - Disable translate/fade, keep immediate render.

#### `ModalSurface`
- Props:
  - `open: boolean`
  - `onClose`
  - `title`
  - `children`
- Keyboard:
  - Escape closes.
  - Focus trap required.

## 5) Types and prop contracts (TypeScript)

```ts
export type CTA = {
  label: string;
  href?: string;
  eventAction: string;
  eventMeta?: Record<string, string>;
};

export type NavItem = { label: string; href: string; eventAction: string };

export type ProtocolSummary = {
  id: string;
  slug: string;
  title: string; // Calm now | Focus prep | Sleep downshift
  durationMin: number;
  intendedMoment: string;
  expectedEffect: string;
};

export type Protocol = ProtocolSummary & {
  scenarioTags: string[];
  goalTags: string[];
  steps: string[];
  whenToUse: string;
  whatToTrack?: string[];
  evidenceNote?: string;
};

export type WhyStateContent = {
  confidenceLabel: "Strong" | "Moderate" | "Emerging";
  confidencePercent: number;
  coveragePercent: number;
  explanation: string;
};

export type DeltaMetric = {
  key: "load" | "readiness" | "consistency";
  label: string;
  delta: number;
  direction: "up" | "down" | "flat";
};

export type TrendPoint = {
  ts: string;
  readiness: number;
  load: number;
  consistency?: number;
};

export type ExperimentStatus = "planned" | "active" | "completed";

export type ExperimentCardData = {
  id: string;
  title: string;
  focus: "readiness" | "load" | "consistency";
  status: ExperimentStatus;
  hypothesis: string;
  durationDays: number;
  checkInDaysCompleted: number;
  adherencePercent?: number;
  estimate?: string;
  rationale?: string;
  nextStep?: string;
  resultSummary?: string;
};

export type FAQItem = {
  id: string;
  question: string;
  answer: string;
  category: "product" | "privacy" | "safety" | "pricing" | "support";
  order: number;
};
```

## 6) Content model and file schemas

### 6.1 Protocol library schema (`content/protocols/*.json`)

```json
{
  "id": "focus_prep",
  "slug": "focus-prep",
  "title": "Focus prep",
  "durationMin": 5,
  "intendedMoment": "Before deep work",
  "expectedEffect": "Lower activation noise and improve entry into focus.",
  "scenarioTags": ["balanced_day", "high_stress_day"],
  "goalTags": ["focus", "stability"],
  "whenToUse": "Use before cognitively demanding blocks when switching context.",
  "steps": [
    "Set a single work target.",
    "Follow guided breathing cadence.",
    "Begin task when timer ends."
  ],
  "whatToTrack": ["Perceived activation", "Task start latency"],
  "status": "active",
  "version": 1
}
```

### 6.2 FAQ schema (`content/faqs/*.json`)

```json
{
  "id": "confidence-explainer",
  "question": "How does confidence work?",
  "answer": "Confidence reflects coverage and recency of your inputs. Labels are Strong, Moderate, or Emerging.",
  "category": "product",
  "order": 20
}
```

### 6.3 Trust tile schema (`content/trust/tiles.json`)

```json
[
  {
    "id": "local-first",
    "title": "Local-first posture",
    "body": "Core state and session data are handled locally in the audited build.",
    "linkLabel": "Learn about privacy",
    "linkHref": "/privacy"
  }
]
```

### 6.4 Page module schema (`content/pages/home.json`)

```json
{
  "slug": "home",
  "modules": [
    { "id": "hero_state_card", "enabled": true },
    { "id": "loop_triad", "enabled": true },
    { "id": "next_best_action", "enabled": true },
    { "id": "protocol_preview", "enabled": true },
    { "id": "data_workspace_preview", "enabled": true },
    { "id": "trust_strip", "enabled": true },
    { "id": "final_cta", "enabled": true }
  ]
}
```

## 7) Page wireframe outlines

Module IDs are stable keys for design, QA, and analytics mapping.

### 7.1 Home (`/`)

Desktop module order:
1. `home_h1_hero_state_card`
2. `home_h2_loop_triad`
3. `home_h3_next_best_action`
4. `home_h4_protocol_preview`
5. `home_h5_data_workspace_preview`
6. `home_h6_trust_strip`
7. `home_h7_final_cta`

Mobile order:
1. `home_h1_hero_state_card` (stack media below copy)
2. `home_h2_loop_triad` (single column)
3. `home_h3_next_best_action`
4. `home_h5_data_workspace_preview`
5. `home_h4_protocol_preview`
6. `home_h6_trust_strip`
7. `home_h7_final_cta`

### 7.2 Product (`/product`)

Desktop:
1. `product_hero_overview`
2. `product_today_section_card`
3. `product_regulate_section_card`
4. `product_data_section_card`
5. `product_crosslink_cta`

Mobile:
1. `product_hero_overview`
2. `product_today_section_card`
3. `product_regulate_section_card`
4. `product_data_section_card`
5. `product_crosslink_cta`

### 7.3 Today (`/product/today`)

1. `today_hero_command_deck`
2. `today_best_action_explainer`
3. `today_timeline_preview`
4. `today_context_capture_note`
5. `today_get_app_cta`

### 7.4 Regulate (`/product/regulate`)

1. `regulate_hero_flow_intro`
2. `regulate_stepper_3step`
3. `regulate_protocol_cards`
4. `regulate_timer_demo`
5. `regulate_record_impact_explainer`
6. `regulate_pricing_expectation_note`

### 7.5 Data (`/product/data`)

1. `data_hero_workspace_intro`
2. `data_segmented_modes`
3. `data_trends_module`
4. `data_experiments_module`
5. `data_history_module`
6. `data_what_working_block`

### 7.6 Protocols (`/protocols`)

1. `protocols_hero`
2. `protocols_filter_chip_bar`
3. `protocols_grid`
4. `protocols_detail_drawer`
5. `protocols_get_app_cta`

### 7.7 How it works (`/how-it-works`)

1. `how_loop_diagram`
2. `how_confidence_explainer`
3. `how_sample_modes`
4. `how_return_to_today_cta`

### 7.8 Privacy (`/privacy`)

1. `privacy_posture_statement`
2. `privacy_data_categories`
3. `privacy_boundaries_non_emergency`
4. `privacy_export_delete_guidance`
5. `privacy_policy_links`

### 7.9 Pricing (`/pricing`)

1. `pricing_hero`
2. `pricing_plan_cards`
3. `pricing_trial_terms`
4. `pricing_faq_shortlist`
5. `pricing_primary_cta`

### 7.10 FAQ (`/faq`) and Support (`/support`)

FAQ:
1. `faq_search_or_category_chips`
2. `faq_accordion`
3. `faq_safety_strip`

Support:
1. `support_contact_form`
2. `support_troubleshooting_links`
3. `support_data_controls`

## 8) Interaction contracts

### 8.1 Tour stepper behavior

- Control: `Today | Regulate | Data`.
- Input methods: click/tap, keyboard arrows, swipe on mobile.
- On change:
  - update panel.
  - set `aria-selected`.
  - fire `navigation_tab_changed` with `tab`.

### 8.2 Trend chart behavior

- Desktop:
  - hover or drag to scrub marker.
- Mobile:
  - tap to place marker.
- Reduced motion:
  - no animated marker interpolation.
  - static chart image with text readout.
- Events:
  - `chart_interaction` with `window`, `mode`, `input_type`.

### 8.3 Modal/disclosure behavior

- `Why this state` opens inline disclosure by default.
- On compact viewports it can open modal.
- Must not route to a new page.

## 9) Analytics contract

Reuse app event names:

```ts
type WebEventName =
  | "screen_view"
  | "primary_cta_tapped"
  | "secondary_action_tapped"
  | "navigation_tab_changed"
  | "chart_interaction"
  | "paywall_presented"
  | "paywall_dismissed";
```

Required payload keys:
- `surface`: `"home" | "product" | "today" | "regulate" | "data" | "protocols" | "privacy" | "pricing" | "faq" | "support"`
- `action`: stable snake_case action id
- `timestamp`: ISO string

Payload rules:
- No sensitive free text in analytics.
- Do not send contact-form message body content.

## 10) Accessibility requirements by component

- All interactive chips/segments are keyboard reachable.
- Focus ring uses `--focus-ring`, 2px min.
- Color is never sole signal:
  - trend direction includes icon/text.
  - selected states include border/weight.
- Charts include text summary region and ARIA label.
- `prefers-reduced-motion` disables reveal and chart animation.

## 11) QA and acceptance checklist for web build

### 11.1 Visual and interaction

- Surfaces follow `base/raised/glass/focus` rules.
- Hero hierarchy is clear above fold:
  - signal headline
  - one primary action
  - supporting detail
- Light and dark both pass contrast and CTA clarity.

### 11.2 Performance

- Lighthouse targets:
  - LCP < 2.5s
  - CLS < 0.1
- Hero video:
  - provide poster
  - lazy-load lower sections
  - responsive source sets

### 11.3 Content QA

- CTA labels are consistent across pages.
- Protocol names/durations match content schema values.
- Safety disclaimer present in footer and relevant pages.

## 12) Implementation sequence

1. Build tokens + primitives (`SurfaceCard`, buttons, chips, segmented control).
2. Build shell (`SiteHeader`, `BottomAnchorPillNav`, `SiteFooter`).
3. Implement Home modules H1-H7.
4. Implement Product/Today/Regulate/Data pages.
5. Implement Protocols + How it works + Privacy + Pricing + FAQ + Support.
6. Wire analytics and accessibility checks.
7. Run visual regression in light/dark and mobile/desktop.

