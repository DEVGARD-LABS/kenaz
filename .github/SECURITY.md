# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅ Yes     |
| < 1.0   | ❌ No      |

## Reporting a vulnerability

**Do not open a public issue for security vulnerabilities.**

Email `security@aurvang.com` with:

1. A clear description of the vulnerability
2. Steps to reproduce
3. Affected versions
4. If possible, a suggested fix or workaround

You will receive an acknowledgment within 48 hours and a resolution timeline within 7 days.

## Scope

This policy covers:
- The Kenaz plugin itself (`agents/kenaz.md`, `commands/kenaz.md`)
- Detection rules (`rules/`)
- Scripts (`scripts/`)

## False positives and rule improvements

False positives or missed detections are not security vulnerabilities — please open a regular GitHub issue with the label `false-positive` or `missed-detection`.

## Responsible disclosure

We follow a 90-day coordinated disclosure policy. If a fix cannot be shipped within 90 days, we will communicate publicly why.
