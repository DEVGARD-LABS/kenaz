#!/usr/bin/env python3
"""Update the 'Most used' download stats in AUDITS.md from npm and PyPI APIs.

Replaces content between <!-- stats-start --> and <!-- stats-end --> markers.
Safe to run repeatedly — only writes the file if numbers change.
"""

import json
import os
import re
import ssl
import sys
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).parent.parent
AUDITS = ROOT / "AUDITS.md"

# (display_name, npm_package, verdict, note)
NPM_PACKAGES = [
    ("playwright",         "@playwright/mcp",                             "⚠️ REVIEW",         "Unpinned `@latest` — pin version before use"),
    ("firebase",           "firebase-tools",                              "⚠️ REVIEW",         "General CLI, not MCP-only — unpinned + `-y` flag ⚠️ inflated"),
    ("context7",           "@upstash/context7-mcp",                       "⚠️ REVIEW",         "Unpinned `@latest` + external API by design"),
    ("filesystem",         "@modelcontextprotocol/server-filesystem",     "✅ SAFE_WITH_CODE", "Run `npm audit fix` (minimatch CVE)"),
    ("sequential-thinking","@modelcontextprotocol/server-sequential-thinking","✅ SAFE_WITH_CODE","Purely in-memory, zero network"),
    ("supabase",           "@supabase/mcp-server-supabase",               "✅ SAFE_WITH_CODE", "Pin to `@0.8.1`"),
    ("memory",             "@modelcontextprotocol/server-memory",         "✅ SAFE_WITH_CODE", "Local JSONL graph, zero network"),
    ("sentry",             "@sentry/mcp-server",                          "⚠️ REVIEW",         "`sendDefaultPii:true` ships tool context to `sentry.io`"),
    ("notion",             "@notionhq/notion-mcp-server",                 "✅ SAFE_WITH_CODE", "Pin to `@2.2.1`"),
    ("next-devtools-mcp",  "next-devtools-mcp",                           "⚠️ REVIEW",         "PA-023 CRITICAL: `\"FORGET ALL PRIOR KNOWLEDGE\"` in tool description"),
    ("slack",              "@modelcontextprotocol/server-slack",          "⚠️ REVIEW",         "npm/source version gap — cannot audit what executes"),
    ("stripe",             "@stripe/mcp",                                 "✅ SAFE_WITH_CODE", "All calls proxied to `mcp.stripe.com` — use restricted keys"),
]

# (display_name, pypi_package, verdict, note)
PYPI_PACKAGES = [
    ("git (PyPI)",   "mcp-server-git",   "✅ SAFE_WITH_CODE", "uv.lock + SHA256; flag-injection defense"),
    ("fetch (PyPI)", "mcp-server-fetch", "✅ SAFE_WITH_CODE", "PA-015 note: override phrasing in description"),
]

HTTP_REMOTE = "github · figma · cloudflare · linear · gitlab · asana · greptile"

DISCLAIMER = (
    "> `firebase-tools` downloads reflect the full Firebase CLI, not MCP-specific usage. "
    "`@playwright/mcp` is likely inflated by CI pipelines. "
    "HTTP remote MCPs have no download metric."
)


def fmt(n: int) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{round(n / 1_000)}K"
    return str(n)


def _ssl_ctx() -> ssl.SSLContext:
    ctx = ssl.create_default_context()
    for path in ("/etc/ssl/cert.pem", "/etc/ssl/certs/ca-certificates.crt"):
        if os.path.exists(path):
            try:
                ctx.load_verify_locations(cafile=path)
            except ssl.SSLError:
                pass
            break
    return ctx


_CTX = _ssl_ctx()


def fetch_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": "kenaz-stats/1.0"})
    with urllib.request.urlopen(req, context=_CTX, timeout=15) as r:
        return json.loads(r.read())


def npm_downloads(pkg: str) -> int:
    url = f"https://api.npmjs.org/downloads/point/last-month/{pkg}"
    try:
        return fetch_json(url)["downloads"]
    except Exception as e:
        print(f"  WARN npm {pkg}: {e}", file=sys.stderr)
        return 0


def pypi_downloads(pkg: str) -> int:
    url = f"https://pypistats.org/api/packages/{pkg}/recent"
    try:
        return fetch_json(url)["data"]["last_month"]
    except Exception as e:
        print(f"  WARN pypi {pkg}: {e}", file=sys.stderr)
        return 0


def build_table(rows: list) -> str:
    lines = [
        "| # | Plugin | Downloads/mo | Verdict | Quick take |",
        "|---|---|---|---|---|",
    ]
    for i, (name, dl_fmt, verdict, note) in enumerate(rows, 1):
        lines.append(f"| {i} | {name} | {dl_fmt} | {verdict} | {note} |")
    return "\n".join(lines)


def main() -> int:
    today = date.today().isoformat()

    print("Fetching npm download stats...")
    npm_rows: list[tuple] = []
    for name, pkg, verdict, note in NPM_PACKAGES:
        dl = npm_downloads(pkg)
        print(f"  {pkg}: {dl:,}")
        npm_rows.append((name, dl, verdict, note))

    print("Fetching PyPI download stats...")
    pypi_rows: list[tuple] = []
    for name, pkg, verdict, note in PYPI_PACKAGES:
        dl = pypi_downloads(pkg)
        print(f"  {pkg}: {dl:,}")
        pypi_rows.append((name, dl, verdict, note))

    all_rows = sorted(npm_rows + pypi_rows, key=lambda x: x[1], reverse=True)

    # Skip zero-download entries (API failures) to avoid polluting the table
    valid = [(name, dl, verdict, note) for name, dl, verdict, note in all_rows if dl > 0]
    if len(valid) < len(all_rows):
        failed = len(all_rows) - len(valid)
        print(f"  WARNING: {failed} package(s) returned 0 — possibly API errors, excluded from table", file=sys.stderr)

    formatted = [(name, fmt(dl), verdict, note) for name, dl, verdict, note in valid]
    table = build_table(formatted)

    new_block = (
        f"<!-- stats-start -->\n"
        f"Ranked by npm + PyPI downloads, last 30 days — snapshot **{today}**. "
        f"Re-run `/kenaz <plugin>` to get an updated verdict for any entry.\n\n"
        f"{DISCLAIMER}\n\n"
        f"{table}\n\n"
        f"**HTTP remote MCPs** (no npm metric, zero local code): {HTTP_REMOTE}\n"
        f"<!-- stats-end -->"
    )

    content = AUDITS.read_text(encoding="utf-8")
    pattern = re.compile(r"<!-- stats-start -->.*?<!-- stats-end -->", re.DOTALL)

    if not pattern.search(content):
        print("ERROR: markers <!-- stats-start --> / <!-- stats-end --> not found in AUDITS.md", file=sys.stderr)
        return 1

    new_content = pattern.sub(new_block, content)

    if new_content == content:
        print("No changes — stats are identical to current file.")
        return 0

    AUDITS.write_text(new_content, encoding="utf-8")
    print(f"AUDITS.md updated with stats from {today}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
