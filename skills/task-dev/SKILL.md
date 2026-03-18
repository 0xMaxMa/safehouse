---
name: task-dev
description: Develop, fix bugs, or add features to a project via SSH + tmux + Claude Code on a remote dev server. Use when asked to fix a bug, implement a feature, or make code changes on a dev server. Triggers on phrases like "fix bug", "implement", "develop", "deploy", or when the user wants code changes made on a remote server.
---

# Task Dev — SSH + tmux + Claude Code Workflow

## Prerequisites (resolve before starting)

**Collect missing info before proceeding:**

1. **Project name** — If not specified, ask: "What is the project name?" then save to memory
2. **Session name** — If not specified, infer from task context (e.g. `fixbug-dot-color`, `feat-privacy-page`). Tell the user: "Working in tmux session: `<name>`". **Do NOT save to memory** — session name is task-specific, create a new one each time
3. **Dev server hostname** — Check memory first. If not found, ask: "What is the dev server hostname? e.g. xxx.dev-server" then save to memory after successful connection

## Step 1 — Plan & Confirm

Restate the task clearly in bullet points. Ask the user to confirm or correct before proceeding.

Example:
> What will be done:
> - Fix dot color logic in `app/(dashboard)/page.tsx`
> - Condition: Strength + no activity + day has passed → 🔴
>
> Is this correct?

**Do not proceed until user confirms.**

## Step 2 — SSH & tmux

```bash
# Connect
ssh -i /home/node/.ssh/id_ed25519 -p 22 dev@<dev-server>

# tmux: attach existing or create new
tmux attach -t <session-name> 2>/dev/null || tmux new-session -d -s <session-name>
```

If SSH fails, ask the user for the correct hostname. Save successful hostname to memory.

## Step 3 — Launch Claude Code

```bash
tmux send-keys -t <session-name> 'cd ~/projects/<project> && claude --dangerously-skip-permissions' C-m
```

Wait ~12s for Claude Code to load, then verify it's ready by capturing pane output.

**Auto-accept strategy:**
- `--dangerously-skip-permissions` handles file edits automatically
- For bash command prompts that still appear: open a new tmux window (`tmux new-window -t <session-name> -n shell`) and run commands directly there — do NOT loop-approve in Claude Code

## Step 4 — Send Task to Claude Code

Send the confirmed plan from Step 1 as a single prompt. Include:
- What files to change
- Exact logic/behavior required
- "Write unit tests, wire function into component, run tests, fix until passing"

```bash
tmux send-keys -t <session-name> '<full task prompt>' C-m
```

Monitor progress by polling every 30–60s:
```bash
ssh ... "tmux capture-pane -t <session-name> -p -S -20"
```

If Claude Code gets stuck waiting for approval, use the shell window to run commands directly.

## Step 5 — Build & Test

After Claude Code finishes, run in the shell window:

```bash
# Check what test/build commands are available
cat package.json | grep -A5 '"scripts"'
cat Makefile 2>/dev/null | grep -E '^[a-z].*:' | head -20

# Run build first
npx next build 2>&1 | tail -5
# → must have NO "Type error" (Dynamic server warnings are OK)

# Run tests
npx jest --no-coverage 2>&1 | tail -15
# → must be 100% pass
```

**If build fails → fix before deploying. Do not skip.**

## Step 6 — Visual Verification (UI changes only)

If the task involves UI changes:

```bash
# Window 1: dev server
npm run dev  # note port (3000 or 3001 if occupied)

# Window 2: tunnel
cloudflared tunnel --url http://localhost:<port>
# → outputs URL: https://<random>.trycloudflare.com
```

**Report the tunnel URL to the user and wait for visual confirmation before deploying.**

Alternatively, use `web_fetch` or logic simulation (Python script with real API data) to verify behavior programmatically.

## Step 7 — Deploy (optional)

Ask the user: "Would you like to deploy as well?"

If yes:
```bash
# In shell window
make deploy 2>&1 | tail -10
```

Verify:
- digest hash changed from previous deploy
- webhook accepted: `{"status":"accepted"}`
- Report: "Deploy successful — digest `sha256:xxxxxxxx` | `https://<production-url>`"

## Memory

Save to memory after first successful run:
- Dev server hostname
- Project name → path mapping (e.g. `running-coach` → `~/projects/running-coach`)
- Deploy URL

**Do NOT save session name** — infer fresh from task context each time.

## Common Issues

| Problem | Fix |
|---------|-----|
| SSH connection refused | Ask user for correct hostname/port |
| Claude Code keeps asking approval | Open `tmux new-window` shell, run commands directly |
| Build fails: Type error | Fix type mismatch before deploying |
| Tests fail after code change | Fix root cause, don't skip tests |
| Tunnel not available | Use Python logic simulation with real API data instead |
