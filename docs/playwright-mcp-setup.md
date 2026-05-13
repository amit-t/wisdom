# Playwright MCP setup (optional)

The URL-import flow (`wisdom import-url <url>`) tries `yt-dlp` first. When
that fails (private content, login wall, geo-block, format churn), the agent
can fall back to scraping the URL through a Playwright MCP server that uses
your already-logged-in Chrome profile.

This document is **optional**. Without an MCP set up, the URL flow falls
through to a manual-paste prompt — you'll be asked to paste the caption /
text yourself.

## One-time setup

1. Install a Playwright MCP server. The community-maintained options:
   - `@playwright/mcp` — official-flavored
   - `chrome-devtools-mcp` — CDP-based

2. Register it with the agent that hosts your wisdom sessions. For Claude
   Code:

   ```bash
   claude mcp add playwright \
     --command "npx -y @playwright/mcp" \
     --env "PLAYWRIGHT_USER_DATA_DIR=$HOME/Library/Application Support/Google/Chrome/Default"
   ```

   Adjust the user-data-dir path to point at the Chrome profile that has your
   Instagram / Twitter / etc. sessions.

3. Confirm registration:

   ```bash
   claude mcp list
   ```

## How the wisdom flow uses it

When `wisdom import-url` runs and yt-dlp returns no usable metadata, the CLI
writes a directive file at `.cache/imports/<hash>/agent-directive.md`. The
agent (when it picks up the extraction step) reads that directive and decides
whether to drive the MCP. The directive tells the agent which files to write
back to the cache (caption.txt, page-text.txt, comments.txt, thumb.jpg).

The agent is responsible for declining gracefully if no Playwright MCP is
registered.

## Troubleshooting

- **MCP not visible to agent** — restart the agent so it re-reads MCP config.
- **Cookies missing inside the MCP browser** — confirm the user-data-dir
  points at the profile you use day-to-day, not the default empty one.
- **Instagram still blocks** — sometimes IG flags even logged-in sessions
  briefly. Re-authenticate in real Chrome (the MCP uses the same cookies),
  wait a minute, retry.
