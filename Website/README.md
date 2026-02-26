# MindSense Website

This directory contains the production marketing site for MindSense AI v1.0.0.

## Files

- `index.html`: primary marketing experience and conversion flow
- `styles.css`: visual system, responsive layout, animation states, and legal page styling
- `app.js`: interaction runtime (navigation state, counters, tour system, audience tracks, motion)
- `privacy.html`: privacy posture summary page
- `terms.html`: terms and usage-boundary summary page
- `assets/screenshots`: UI-test screenshot exports (source PNGs)
- `assets/screenshots/optimized`: responsive JPG variants consumed by website `srcset`
- `assets/brand`: website logo assets

## Local preview

From repository root:

```bash
cd Website
python3 -m http.server 4173
```

Open `http://localhost:4173`.

## Refresh screenshots

From repository root:

```bash
bash Scripts/export_marketing_screenshots.sh
```

Optional override:

```bash
bash Scripts/export_marketing_screenshots.sh "iPhone 17" "Website/assets/screenshots"
```

## Content guardrails

- Keep messaging aligned to implemented app behavior.
- Avoid roadmap claims framed as shipped features.
- Preserve wellness/safety boundaries and crisis direction language.
- Maintain reduced-motion and keyboard accessibility behavior when adding interactions.
