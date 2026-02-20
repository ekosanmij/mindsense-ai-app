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

### Changed

- Replaced magic-link auth implementation with `Continue with Apple` session flow.
- Updated Intro/Auth entry copy and layout to an Apple-first, lower-noise design.
- Updated documentation set to reflect Apple sign-in behavior and persistence keys.
