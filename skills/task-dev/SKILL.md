---
name: task-dev
description: Implement a planning document end-to-end — branch, code, tests, PR. Use when the user asks to implement a planning-xxx.md file.
user-invocable: true
---

# /task-dev — Implement a planning document

Reference: `planning-xxx-xxx.md` as specified by the user.

Follow these steps in order. Report progress at each step before continuing.

---

## Step 1 — Prepare branch

- If there is already a working branch, **ask the user first**: reuse it or create a new one?
- Otherwise create a new branch from latest `main`:

```bash
git checkout main
git pull origin main
git checkout -b <branch-name>    # e.g. feat/xxx, fix/xxx
```

---

## Step 2 — Implement

Work through the planning doc in order. Spawn sub-agents for independent tasks when helpful. Report when each step completes before moving on.

---

## Step 3 — Tests must pass 100%

- Write unit tests in `tests/unit/` covering every test case in the planning doc.
- Run `npm test` — all suites must pass, zero failures.
- If a test fails: fix it. **Never** skip or comment out failing tests.

---

## Step 4 — Stop for review

Pause and ask the user to confirm before opening a PR.

If the task involves UI changes, spin up a preview so the user can verify visually:

```bash
# Terminal 1 — dev server (kill any existing dev server first to reuse the same port)
npm run dev

# Terminal 2 — public tunnel
cloudflared tunnel --url http://localhost:<port>
```

Verify the tunnel is working by curling the public URL — confirm you get actual HTML from the app, not a Cloudflare error page. Only then report the URL to the user and wait for their go-ahead.

---

## Step 5 — Open PR to main

```bash
git add <files>
git commit -m "<english commit message>"
git push -u origin <branch-name>
gh pr create --title "..." --body "..."
```

### Strict rules

- Commit message, PR title, and PR body: **English only**.
- **Never** include "by Claude Code" or "Co-Authored-By: Claude" in commits or PRs.
- **Never** use Thai anywhere — not in comments, code, tests, commit messages, PR titles, or descriptions.
- **Never** embed real secrets in code, tests, or comments — no chat IDs, API keys, usernames, session IDs, or tokens. Use placeholder/fake values only.
