#!/bin/sh
docker compose -f docker-compose-openclaw-cli.yml run --rm openclaw-cli onboard --no-install-daemon
