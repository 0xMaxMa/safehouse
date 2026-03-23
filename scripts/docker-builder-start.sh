#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Load env
if [ -f .env ]; then
  set -a
  # shellcheck source=.env
  source .env
  set +a
fi

# Ensure the shared devnet network exists (created by main docker-compose)
if ! docker network inspect dev_net &>/dev/null; then
  echo "Network 'dev_net' not found. Start the main stack first:"
  echo "  docker compose up -d"
  exit 1
fi

echo "Starting docker-builder..."
docker compose -f docker-compose-builder.yml up -d

echo ""
echo "docker-builder is running."
echo "From inside dev-server, DOCKER_HOST=tcp://docker-builder:2375 is already set."
echo ""
echo "Example usage inside dev-server:"
echo "  docker build -t my-app /home/\$DEV_USER/projects/my-project"
echo "  docker build -f /workspace/my-project/Dockerfile /workspace/my-project"
