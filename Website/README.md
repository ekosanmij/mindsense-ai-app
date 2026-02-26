# MindSense Website (As-Built)

This folder contains the production marketing website for MindSense AI v1.0.0.

## Files

- `index.html`: primary marketing page
- `styles.css`: visual system, responsive layout, legal-page styles
- `app.js`: interaction runtime (navigation state, counters, tab systems, reveal motion)
- `privacy.html`: privacy posture summary
- `terms.html`: terms and usage-boundary summary
- `assets/screenshots`: UI-test-exported PNG screenshots
- `assets/screenshots/optimized`: responsive JPG derivatives used in `srcset`
- `assets/brand`: website logo assets

## Local preview

From repo root:

```bash
cd Website
python3 -m http.server 4173
```

Open: `http://localhost:4173`

## Screenshot refresh workflow

Run from repo root:

```bash
bash Scripts/export_marketing_screenshots.sh
```

Optional overrides:

```bash
bash Scripts/export_marketing_screenshots.sh "iPhone 17" "Website/assets/screenshots"
```

What this does:

1. Runs `MindSenseCoreScreensUITests.testMarketingWebsiteScreenshotExport`.
2. Writes raw PNG files into `Website/assets/screenshots`.
3. Generates optimized JPEG variants in `Website/assets/screenshots/optimized`.

## Update workflow

1. Verify any claim against source code and `Docs/product/prd-as-built.md`.
2. Keep walkthrough entries in `Website/app.js` aligned with screenshot asset names.
3. Re-run screenshot export after UI changes that affect captured surfaces.
4. Validate keyboard navigation and reduced-motion behavior before shipping.

## Content guardrails

- Keep copy as-built and non-overclaiming.
- Preserve wellness/safety boundaries and crisis direction language.
- Do not present unimplemented integrations as shipped features.
