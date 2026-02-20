# Security Policy

## Supported versions

Security fixes are currently targeted at:

- `1.0.x` (current)

Older versions may not receive patches.

## Reporting a vulnerability

Please do not open public issues for suspected vulnerabilities.

Preferred process:

1. Open a private GitHub vulnerability report (Security Advisory) for this repository.
2. If private reporting is unavailable, contact the repository owner directly via GitHub profile contact details and request a private channel.

Include:

- Affected component or file
- Reproduction steps or proof of concept
- Impact and attack scenario
- Suggested mitigation (if known)

## Response expectations

- Initial triage target: within 5 business days
- Fix timeline: based on severity and exploitability
- Coordinated disclosure: after a fix is available

## Sensitive configuration guidance

- Never commit private keys, signing certificates, or backend secrets.
- Treat all auth/environment values as configuration, not source code constants.
- Prefer local scheme/environment configuration for development credentials.
- Rotate compromised credentials immediately.

## Scope notes for this repository

High-priority areas include:

- Magic-link auth request/verification flow
- URL/deep-link parsing and token handling
- Local persistence and session lifecycle
- External auth provider request handling

