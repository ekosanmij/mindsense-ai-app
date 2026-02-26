# MindSense Marketing Website

This folder contains the production-style marketing site for MindSense AI.

## What is included

- `index.html`: single-page marketing narrative with conversion, FAQ, and contact paths
- `privacy.html` / `terms.html`: first-party trust/legal summary pages linked from footer
- `styles.css`: app-aligned visual tokens, responsive layout, focus and reduced-motion behavior
- `app.js`: interactive surface explorer, keyboard tabs, nav state, counters, motion hooks
- `assets/screenshots/*.png`: real UI screenshots exported from deterministic UI tests
- `assets/screenshots/optimized/*.jpg`: responsive compressed variants used by website image `srcset`
- `assets/brand/*.svg`: official logo assets

## Run locally

From repository root:

```bash
cd Website
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Refresh screenshots

Run from repository root:

```bash
bash Scripts/export_marketing_screenshots.sh
```

Optional arguments:

```bash
bash Scripts/export_marketing_screenshots.sh "iPhone 17" "Website/assets/screenshots"
```

The script now refreshes both:

- source PNGs in `Website/assets/screenshots`
- optimized JPG variants in `Website/assets/screenshots/optimized`

## Deployment

Because this site is static HTML/CSS/JS, it can be deployed to any static host (GitHub Pages, Vercel static, Netlify, S3+CloudFront).
