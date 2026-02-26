# Changelog

All notable changes to this project should be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project currently tracks versions with semantic-style release tags.

## [1.0.0] - 2026-02-19

### Added

- Initial MindSense AI v1.0.0 app release.
- Core product surfaces: `Today`, `Regulate`, `Data`.
- Passwordless `Continue with Apple` auth UX.
- Local-first persistence and deterministic demo scenario engines.
- Unit and UI test targets with scenario-seeded launch overrides.
- Quality-gate scripts for contrast, snapshots, accessibility, and interaction latency.

## [Unreleased]

### Added

- Root repository `README.md` with setup, architecture, testing, and auth configuration guidance.
- `CONTRIBUTING.md` workflow for contributors.
- `SECURITY.md` vulnerability reporting policy.
- `Docs/engineering/architecture.md` runtime architecture reference.
- `Docs/engineering/testing.md` test and QA runbook.
- New marketing website at `Website/` with app-aligned styling, animated sections, and stakeholder/investor narratives.
- Marketing website implementation doc at `Docs/product/website-marketing-v3-as-built.md`.
- Deterministic screenshot export utility script: `Scripts/export_marketing_screenshots.sh`.
- UI test screenshot exporter `testMarketingWebsiteScreenshotExport()` for website asset refreshes.

### Changed

- Replaced magic-link auth implementation with `Continue with Apple` session flow.
- Updated Intro/Auth entry copy and layout to an Apple-first, lower-noise design.
- Updated documentation set to reflect Apple sign-in behavior and persistence keys.
- Updated `README.md` repository structure and documentation index to include the current website docs.
- Rebuilt `Website/index.html`, `Website/styles.css`, and `Website/app.js` as a high-spec v3 marketing experience with interactive product-tour, audience tracks, and deeper investor/stakeholder diligence sections.
- Added first-party trust pages: `Website/privacy.html` and `Website/terms.html`.
- Added responsive optimized screenshot variants under `Website/assets/screenshots/optimized`.
- Updated `Scripts/export_marketing_screenshots.sh` to auto-generate optimized website image variants.
- Replaced `Website/README.md` with v3 website implementation and maintenance guidance.

### Removed

- Outdated website blueprint doc: `Docs/product/website-implementation-blueprint.md`.
- Outdated website docs replaced: `Docs/product/marketing-website.md`, `Docs/product/marketing-website-audit.md`.
- Outdated website as-built doc: `Docs/product/website-marketing-as-built.md`.
