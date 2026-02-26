# MindSense Marketing Website (As-Built)

Version: 4.0 (as-built)
Date: February 26, 2026
Primary source directory: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website`

## 1) Purpose

This document captures the implemented marketing website and its operating workflow.

Goals:

- Keep all public messaging aligned with implemented app behavior.
- Present a complete section-by-section product walkthrough with real screenshot exports.
- Preserve explicit trust/safety boundaries.
- Document the maintenance workflow so screenshots and copy stay synchronized with app source.

## 2) Architecture

Website stack:

- `index.html`: semantic information architecture and content model.
- `styles.css`: visual system tokens, layout, responsive behavior, and legal page styles.
- `app.js`: progressive enhancement for interactions and motion.
- `privacy.html` and `terms.html`: legal/support boundary pages.

Interaction runtime behavior:

- Works with JS disabled for core reading/navigation.
- Enhances with JS for:
  - sticky-nav section highlighting
  - progress bar
  - animated metrics
  - keyboard-accessible loop and walkthrough tab systems
  - audience track switching
  - reveal animations (GSAP/ScrollTrigger when present, observer fallback otherwise)

Accessibility behavior:

- Skip link present.
- Visible focus states for links/buttons/custom controls.
- Keyboard support for all interactive tab/step controls.
- Reduced-motion mode disables non-essential motion.

## 3) Information Architecture

Primary page flow in `index.html`:

1. Hero positioning + CTAs
2. Product overview and proof metrics
3. Core loop explainer (interactive)
4. Full app walkthrough (interactive screenshot-backed tabs)
5. Audience tracks:
   - prospective users
   - stakeholders
   - investors
6. Trust/safety/quality posture
7. FAQ
8. Contact/conversion section
9. Footer + legal routes

Legal pages:

- `privacy.html`
- `terms.html`

## 4) Interaction Model

Implemented interaction modules:

- Header:
  - responsive nav with mobile toggle
  - active-section link state
- Hero:
  - layered screenshot stage with pointer-parallax (disabled under reduced motion)
- Metrics:
  - on-scroll counter animation
- Core loop:
  - 4-step interactive panel
  - click + keyboard controls (`Arrow`, `Home`, `End`, `Enter`, `Space`)
  - optional timed autoplay when visible
- Walkthrough tabs:
  - 9 screen tabs
  - data-driven content map in `app.js`
  - keyboard roving behavior
- Audience tracks:
  - tab switcher with keyboard support
- Motion:
  - GSAP/ScrollTrigger reveal choreography
  - IntersectionObserver fallback

## 5) Screenshot Mapping

All walkthrough visuals map to exported files from
`MindSenseCoreScreensUITests.testMarketingWebsiteScreenshotExport`.

Raw PNG assets (`Website/assets/screenshots`):

- `intro.png`
- `onboarding.png`
- `today.png`
- `regulate_select.png`
- `regulate_run.png`
- `data_trends.png`
- `data_experiments.png`
- `data_history.png`
- `settings.png`

Optimized variants (`Website/assets/screenshots/optimized`):

- `*-660.jpg`
- `*-990.jpg`

## 6) Copy Guardrails

All website copy must remain:

- As-built and source-verifiable.
- Explicit about wellness boundaries (not emergency/diagnostic care).
- Explicit about current integration gaps (no overclaims).

Current explicit scope notes on website include:

- Local-first storage posture.
- Sign in with Apple auth path.
- Core runtime tabs (`Today`, `Regulate`, `Data`).
- Latent modules not in primary production tab navigation (`Community`, `QA Tools`, `KPI Scorecard`).
- Non-shipped integrations (cloud sync, full HealthKit ingestion, full StoreKit billing wiring).

## 7) Maintenance Workflow

### Local preview

```bash
cd Website
python3 -m http.server 4173
```

### Refresh screenshots

```bash
bash Scripts/export_marketing_screenshots.sh
```

Optional override:

```bash
bash Scripts/export_marketing_screenshots.sh "iPhone 17" "Website/assets/screenshots"
```

### Update checklist

1. Validate claims against source code + `Docs/product/prd-as-built.md`.
2. Update `tourData`/interaction copy in `Website/app.js` with any UI or behavior changes.
3. Re-export screenshots when captured surfaces change.
4. Verify:
   - keyboard interaction behavior
   - reduced-motion fallback
   - responsive layout across desktop/mobile
5. Update root docs/changelog for production changes.
