# MindSense Website

This folder contains the production marketing website for MindSense AI.

## Files

- `index.html`: main marketing page with product, audience, evidence, FAQ, and conversion sections
- `styles.css`: visual system, responsive layout, interaction states, and legal page styling
- `app.js`: nav state, audience switcher, loop simulator, surface explorer, counter and motion behavior
- `privacy.html`: privacy posture summary page
- `terms.html`: terms and usage boundaries summary page
- `assets/screenshots`: source PNG exports from UI tests
- `assets/screenshots/optimized`: responsive JPG variants used by `srcset`
- `assets/brand`: logo assets for web

## Local preview

From repository root:

```bash
cd Website
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Refresh screenshots

From repository root:

```bash
bash Scripts/export_marketing_screenshots.sh
```

Optional:

```bash
bash Scripts/export_marketing_screenshots.sh "iPhone 17" "Website/assets/screenshots"
```

## Notes

- Screenshots should stay sourced from UI automation, not manual edits.
- Website claims must remain as-built and aligned to shipped app behavior.
- If adding new sections, preserve reduced-motion and keyboard accessibility behavior.
