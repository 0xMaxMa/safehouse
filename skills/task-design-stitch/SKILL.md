---
name: task-design-stitch
description: Design UI screens and mockups using Google Stitch AI design tool, then export HTML for use in Next.js or any frontend project. Use when asked to design a UI, create mockups, generate screens, edit existing designs, or export HTML from Stitch. Triggers on phrases like "design UI", "create mockup", "generate screen", "design in Stitch", "use Stitch", or when the user wants a visual dashboard/interface designed before implementation.
---

# task-design-stitch

Design UI screens via Google Stitch SDK, export HTML/screenshots, and wire into frontend projects.

## Prerequisites

- `STITCH_API_KEY` — obtain from https://stitch.withgoogle.com (Google Labs account)
- SDK is pre-installed in this skill's directory — no extra setup needed

## Workflow

### Step 1 — Collect Info

Check memory for `STITCH_API_KEY`. If not found, ask user.
Confirm screens to generate with bullet list before starting.

### Step 2 — Setup

SDK is already installed in the skill dir. Use the script directly via absolute path:

```bash
SKILL_DIR="$(dirname "$(dirname "$(find ~ -maxdepth 8 -path '*/task-design-stitch/scripts/stitch.mjs' 2>/dev/null | head -1)")")"
STITCH_API_KEY=<key> node $SKILL_DIR/scripts/stitch.mjs <command> [args]
```

No need to copy the script or install anything per-project.

### Step 3 — Create Project

```bash
STITCH_API_KEY=<key> node $SKILL_DIR/scripts/stitch.mjs create-project "My App Dashboard"
# → { projectId, title, url }
```

Save `projectId` for all subsequent calls.

### Step 4 — Generate Screens

```bash
STITCH_API_KEY=<key> node $SKILL_DIR/scripts/stitch.mjs generate <projectId> "<prompt>" "<screen-name>"
# → { screenId, htmlUrl, imageUrl, viewUrl }
```

> Note: `screen-name` is a local label in output only — not sent to the Stitch API.

**Prompt writing tips:**
- Start with theme: "Dark-themed..." or "Light, minimal..."
- Describe layout top-to-bottom: navbar → stat cards → main content
- Specify colors explicitly: "bg #0f0f0f, accent #00ff88"
- Name components: "Pool Table with columns: ID, Version, Fee, Liquidity"
- Keep prompt under 300 words — Stitch handles the rest

### Step 5 — Download Output

```bash
# Download HTML (self-contained, inline CSS/JS)
STITCH_API_KEY=<key> node $SKILL_DIR/scripts/stitch.mjs download-html "<htmlUrl>" "output/screen.html"

# Download screenshot (JPG)
curl -sL "<imageUrl>" -o output/screen.jpg
```

### Step 6 — Edit / Iterate

```bash
STITCH_API_KEY=<key> node $SKILL_DIR/scripts/stitch.mjs edit <projectId> <screenId> "<edit prompt>"
# → { screenId (new), htmlUrl, imageUrl }
```

Note: edit creates a new screen version (new screenId).

### Step 7 — Export to Next.js

```bash
# List all screens to get IDs
STITCH_API_KEY=<key> node $SKILL_DIR/scripts/stitch.mjs list-screens <projectId>

# Download each screen's HTML
STITCH_API_KEY=<key> node $SKILL_DIR/scripts/stitch.mjs get-screen <projectId> <screenId>
# then download-html with the returned htmlUrl
```

HTML is self-contained — options:
- **Static preview:** serve as-is with `npx serve`
- **Next.js integration:** extract component structure from HTML, rewrite as React components with Tailwind
- **iframe embed:** embed HTML in Next.js page as iframe for quick preview

## Commands Reference

| Command | Args | Output |
|---|---|---|
| `create-project` | `"title"` | `{projectId, url}` |
| `list-projects` | — | `[{projectId, title, url}]` |
| `list-screens` | `projectId` | `[{screenId, name}]` |
| `generate` | `projectId "prompt" "name"` | `{screenId, htmlUrl, imageUrl}` |
| `generate-variants` | `projectId screenId` | `{screenId, htmlUrl, imageUrl}` |
| `edit` | `projectId screenId "prompt"` | `{screenId, htmlUrl, imageUrl}` |
| `get-screen` | `projectId screenId` | `{htmlUrl, imageUrl}` |
| `download-html` | `htmlUrl [output.html]` | saves file |

## Important Notes

- ⚠️ **SDK Bug:** `stitch.project().generate()` fails — always use `callTool` directly via `stitch.mjs`. See `references/sdk-notes.md` for details.
- ❌ **No delete API** — delete projects via UI at https://stitch.withgoogle.com
- 🔒 **Projects are PRIVATE** — only API key owner can view at `https://stitch.withgoogle.com/project/<id>`
- 📸 **Screenshots expire** — download images promptly after generation
- 💾 **Save to memory:** `STITCH_API_KEY`, project name → projectId mapping

## Troubleshooting

| Error | Fix |
|---|---|
| `Cannot read properties of undefined (reading 'screens')` | SDK bug — use `stitch.mjs` script, not `stitch.project().generate()` |
| `No design.screens in response` | Prompt too short/vague — add more layout detail |
| Project not visible in browser | Must be logged in with the Google account that owns the API key |
| `SIGTERM` on long generate | Increase timeout — Stitch can take 60–120s per screen |

## References

- SDK internals + response structures: `references/sdk-notes.md`
