# MindSense Marketing Website

This folder contains the production-style marketing site for MindSense AI.

## What is included

- `index.html`: single-page marketing narrative (users + investors + stakeholders)
- `styles.css`: app-aligned visual tokens, surfaces, responsive layout
- `app.js`: interactive surface explorer, metric counters, motion hooks
- `assets/screenshots/*.png`: real UI screenshots exported from deterministic UI tests
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

## Deployment

Because this site is static HTML/CSS/JS, it can be deployed to any static host (GitHub Pages, Vercel static, Netlify, S3+CloudFront).
