# MindSense Website (Next.js)

Multi-page showcase website built with Next.js App Router, TypeScript, and Tailwind CSS.

## Stack

- Next.js (App Router)
- TypeScript
- Tailwind CSS
- Content-driven JSON + Markdown

## Run Locally

From `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website`:

```bash
npm install
npm run dev
```

Then open:

`http://127.0.0.1:3000`

## Build And Start

```bash
npm run build
npm run start
```

## Project Structure

- `app/`
  App routes:
  - `/`
  - `/product`
  - `/how-it-works`
  - `/for-teams`
  - `/privacy`
  - `/updates`
  - `/updates/[slug]`
  - `/contact`
  - `/press`
- `components/`
  Reusable UI components (header, footer, forms, modal gallery, etc.)
- `content/site.json`
  Main copy/config source (titles, descriptions, links, CTA text, FAQ, roadmap)
- `content/updates/*.md`
  Update/changelog posts
- `public/screens/`
  Product screenshot placeholders (replace with real captures)
- `public/press/`
  Press kit files (logos + screenshots)
- `public/brand/`
  Brand assets and app icon

## Where To Change Copy

- Global/page copy and links:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/content/site.json`
- Update posts:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/content/updates/*.md`

## Where To Add Real Screenshots

Replace files in:

- `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/public/screens/`

If file names stay the same, pages update automatically.
Screenshot titles/captions used across product + press pages are in:

- `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/lib/screenshots.ts`

## Lead Forms (Waitlist + Contact)

Current behavior:

- Uses client-side validation
- Has success/error states
- Includes honeypot anti-spam field
- Logs submissions locally when no endpoint is configured

To connect forms:

1. Open `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/components/lead-form.tsx`
2. Set real endpoint URLs in:
   - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/content/site.json`
   - `formEndpoints.waitlist`
   - `formEndpoints.contact`
3. Endpoint should accept `POST application/json`

## SEO / Metadata

- Metadata helper: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/lib/metadata.ts`
- Per-page metadata text: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/content/site.json`
- Sitemap: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/app/sitemap.ts`
- Robots: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/app/robots.ts`

## Analytics Hook Placeholder

- Component: `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/components/analytics-placeholder.tsx`
- Enable/configure via:
  - `/Users/ekosanmi.j/Documents/MindSense-AI-v1.0.0/Website/content/site.json` → `analytics`
