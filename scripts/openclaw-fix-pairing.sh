#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
HOST_HOME=$(grep -E '^HOST_HOME=' "$ROOT_DIR/.env" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
HOST_HOME="${HOST_HOME:-./data}"
# Resolve relative path against ROOT_DIR
case "$HOST_HOME" in
  /*) : ;;
  *)  HOST_HOME="$ROOT_DIR/${HOST_HOME#./}" ;;
esac
FILE="$HOST_HOME/.openclaw/config/devices/pending.json"

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE"
  exit 1
fi

# Replace "silent": false => "silent": true
if [ "$(uname)" = "Darwin" ]; then
  sed -i '' 's/"silent": false/"silent": true/g' "$FILE"
else
  sed -i 's/"silent": false/"silent": true/g' "$FILE"
fi

echo "🔨 Fixed: $FILE"
