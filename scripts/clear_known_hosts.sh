#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Load SSH_PORT from .env
SSH_PORT=$(grep -E '^SSH_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
SSH_PORT="${SSH_PORT:-2222}"

echo "Clearing SSH known_hosts for port ${SSH_PORT}..."
ssh-keygen -R "[127.0.0.1]:${SSH_PORT}" 2>/dev/null || true
ssh-keygen -R "[localhost]:${SSH_PORT}" 2>/dev/null || true

echo "🔨 Done. Reconnect via SSH to accept the new host key."
