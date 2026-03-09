#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found. Copy .env.example first."
  exit 1
fi

DEV_USER="$(grep -E '^DEV_USER=' "$ENV_FILE" | cut -d= -f2- | tr -d '[:space:]')"
DEV_USER="${DEV_USER:-dev}"
HOST_HOME="$(grep -E '^HOST_HOME=' "$ENV_FILE" | cut -d= -f2- | tr -d '[:space:]')"
HOST_HOME="${HOST_HOME:-./data}"

if ! id "${DEV_USER}" &>/dev/null; then
  useradd -m -u 1000 -s /bin/bash "${DEV_USER}"
  echo "✅ User '${DEV_USER}' (UID 1000) created"
else
  HOST_UID="$(id -u "${DEV_USER}")"
  if [ "$HOST_UID" != "1000" ]; then
    echo "⚠️  Warning: host user '${DEV_USER}' has UID ${HOST_UID}, but container expects UID 1000"
    echo "   Run: usermod -u 1000 ${DEV_USER}"
    exit 1
  fi
  echo "ℹ️  User '${DEV_USER}' (UID 1000) already exists"
fi

USER_DIR="${HOST_HOME}/${DEV_USER}"
mkdir -p "$USER_DIR"
chown -R "1000:1000" "$HOST_HOME"
chown -R "${DEV_USER}:${DEV_USER}" "$USER_DIR"
echo "✅ Done — ${USER_DIR} owned by ${DEV_USER}:${DEV_USER}"
