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

HOST_HOME="$(grep -E '^HOST_HOME=' "$ENV_FILE" | cut -d= -f2- | tr -d '[:space:]')"
HOST_HOME="${HOST_HOME:-./data}"

chown -R 1000:1000 "$HOST_HOME"
echo "✅ Done — $HOST_HOME owned by 1000:1000"
