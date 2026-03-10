#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. Copy .env.example first."
  exit 1
fi

# Prompt for new password (hidden input)
read -rsp "New password: " NEW_PASSWORD
echo
read -rsp "Confirm password: " CONFIRM_PASSWORD
echo

if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
  echo "Error: Passwords do not match."
  exit 1
fi

if [ -z "$NEW_PASSWORD" ]; then
  echo "Error: Password cannot be empty."
  exit 1
fi

# Update DEV_USER_PASSWORD in .env (pure bash to safely handle special chars)
{
  while IFS= read -r line; do
    if [[ "$line" == DEV_USER_PASSWORD=* ]]; then
      printf 'DEV_USER_PASSWORD=%s\n' "${NEW_PASSWORD}"
    else
      printf '%s\n' "$line"
    fi
  done < "$ENV_FILE"
} > "${ENV_FILE}.tmp" && mv "${ENV_FILE}.tmp" "$ENV_FILE"

echo "Password updated in $ENV_FILE."
echo ""

# Load DEV_USER
DEV_USER=$(grep -E '^DEV_USER=' "$ENV_FILE" | cut -d= -f2 | tr -d '[:space:]')
DEV_USER="${DEV_USER:-dev}"

# Restart container so CODE_SERVER_PASSWORD env var picks up new value from .env
# start.sh will also run chpasswd on startup, so SSH password is synced automatically
echo "Restarting dev-server..."
docker compose up -d dev-server

echo ""
echo "✅ Done. Password updated."
echo "Please use the new password for SSH and code-server access."
