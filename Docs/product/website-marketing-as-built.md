# MindSense Marketing Website (As Built)

Version: 2.0
Date: February 26, 2026

## Purpose

This document captures the current implementation of the MindSense marketing website in `Website/`.

Goals of the current site:

- Explain the product loop clearly for prospective users.
- Provide section-level evidence for investors and stakeholders.
- Show real product screenshots for each main app section.
- Keep claims aligned to shipped behavior in the iOS app.

## Source Of Truth

- Website root: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website`
- Main page: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/index.html`
- Styles: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/styles.css`
- Behaviors: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/app.js`

## Information Architecture

The page is intentionally sequenced for comprehension and conversion:

1. Hero with audience switcher (`Users`, `Stakeholders`, `Investors`)
2. Positioning section (problem/solution framing)
3. Workflow simulator (state -> regulate -> impact -> learn)
4. Interactive main-surface explorer (tabbed)
5. Full screenshot gallery by app section
6. Audience paths for users, stakeholders, and investors
7. Product evidence section (QA/tests/docs posture)
8. FAQ and safety boundaries
9. Contact conversion section
10. Footer with trust links and support channels

## Screenshot Coverage

All screenshots map to app surfaces generated via UI test export:

- `intro`
- `onboarding`
- `today`
- `regulate_select`
- `regulate_run`
- `data_trends`
- `data_experiments`
- `data_history`
- `settings`

Image sources:

- PNG source set: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/assets/screenshots`
- Optimized responsive variants: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/assets/screenshots/optimized`

## Interactions Implemented

- Mobile nav menu with ARIA state and keyboard close behavior.
- Active-section nav highlighting via `IntersectionObserver`.
- Persona switcher updates headline/CTA/tags and visual accent direction.
- Loop simulator with manual and optional auto-advance.
- Keyboard-accessible surface tabs with dynamic panel updates.
- Animated metric counters with reduced-motion fallback.
- Scroll reveal and hero floating motion (GSAP + ScrollTrigger with graceful fallback).

## Audience Messaging Guardrails

Website copy must remain as-built and non-overclaiming:

- Do not imply medical diagnosis or emergency-care replacement.
- Do not claim cloud sync or backend capabilities that are not shipped.
- Keep investor/stakeholder claims tied to shipped QA/testing/product artifacts.
- Keep legal/safety boundaries explicit.

## Legal Pages

- Privacy summary: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/privacy.html`
- Terms summary: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/terms.html`

These pages are operational summaries and should stay aligned with current product posture.

## Local Run

From repository root:

```bash
cd Website
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Screenshot Refresh

From repository root:

```bash
bash Scripts/export_marketing_screenshots.sh
```

Optional device/output arguments:

```bash
bash Scripts/export_marketing_screenshots.sh "iPhone 17" "Website/assets/screenshots"
```

## Related Product Docs

- PRD as-built: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Docs/product/prd-as-built.md`
- Architecture: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Docs/engineering/architecture.md`
- Quality gates: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Docs/quality/quality-gates.md`
