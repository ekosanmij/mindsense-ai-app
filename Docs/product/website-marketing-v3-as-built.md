# MindSense Marketing Website v3 (As Built)

Version: 3.0
Date: February 26, 2026

## Purpose

This document captures the implemented marketing website in `Website/` after the full v3 rebuild.

Core goals:

- Explain the product end-to-end using as-built app behavior.
- Walk through each main app section with exported screenshots.
- Provide dedicated tracks for users, stakeholders, and investors.
- Keep copy anchored to implemented scope and known limitations.

## Source of truth

- Root: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website`
- Main page: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/index.html`
- Styles: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/styles.css`
- Behaviors: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/app.js`
- Legal pages:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/privacy.html`
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/terms.html`

## Information architecture

1. Hero and value framing
2. Proof indicator strip
3. Core loop walkthrough (interactive)
4. Comprehensive section tour (interactive, screenshot-backed)
5. Audience tracks (users, stakeholders, investors)
6. Trust, safety, and technical posture
7. Milestone roadmap
8. FAQ
9. Contact conversion grid
10. Footer + legal routes

## Screenshot mapping

Website tour maps to automated export assets from UI tests:

- `intro`
- `onboarding`
- `today`
- `regulate_select`
- `regulate_run`
- `data_trends`
- `data_experiments`
- `data_history`
- `settings`

Image locations:

- PNG source exports: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/assets/screenshots`
- Responsive JPG variants: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/assets/screenshots/optimized`

## Motion and interaction model

Implemented interactions:

- Sticky header and active-section nav state.
- Scroll progress indicator.
- Animated proof counters (with reduced-motion fallback).
- Interactive core-loop explorer.
- Interactive product tour tab system with keyboard support.
- Audience track switcher (users/stakeholders/investors).
- Roadmap stage spotlight cycling.
- GSAP + ScrollTrigger reveal choreography (fallback to observer/class toggles).

Accessibility rules:

- Reduced-motion preferences disable auto-animated behavior.
- Keyboard support for loop, section-tour tabs, and audience tabs.
- Skip link and visible focus treatments preserved.

## Messaging guardrails

Website copy must remain:

- As-built and non-overclaiming.
- Explicit about wellness-not-emergency boundaries.
- Explicit about current local-first posture and known integration gaps.
- Explicit that latent modules (`Community`, `QA Tools`, `KPI scorecard`) are not in primary production navigation.

## Local preview

```bash
cd Website
python3 -m http.server 4173
```

Open: `http://localhost:4173`

## Screenshot refresh workflow

```bash
bash Scripts/export_marketing_screenshots.sh
```

Optional device/output override:

```bash
bash Scripts/export_marketing_screenshots.sh "iPhone 17" "Website/assets/screenshots"
```

## Update checklist

When updating website copy or structure:

1. Verify all claims against `Docs/product/prd-as-built.md` and source code.
2. Keep product-tour data map in `Website/app.js` aligned with screenshot assets.
3. Re-run screenshot export if app UI changed.
4. Confirm reduced-motion behavior and keyboard navigation still pass.
