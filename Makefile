-include .env
DEV_SERVER_CONTAINER ?= dev-server
OPENCLAW_GATEWAY_CONTAINER ?= openclaw-gateway

.PHONY: help start stop restart build logs \
        update-password clear-known-hosts fix-data-permission \
        docker-builder-start docker-builder-stop \
        caddy-start caddy-stop \
        openclaw-setup openclaw-fix-pairing \
        openclaw-devices-list openclaw-devices-approve

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# --------------------
# Stack
# --------------------
start: ## Start all services
	docker compose up -d

stop: ## Stop and remove all containers
	docker compose down

restart: ## Restart all containers
	docker compose restart

build: ## Rebuild image
	docker compose down
	docker compose build --no-cache

logs: ## Follow container logs
	docker compose logs -f

# --------------------
# Maintenance
# --------------------
update-password: ## Update SSH + code-server password
	./scripts/update_password.sh

clear-known-hosts: ## Clear local SSH known_hosts entry for dev-server
	./scripts/clear_known_hosts.sh

fix-data-permission: ## Create dev user and fix ./data ownership
	sudo ./scripts/fix-data-permission.sh

# --------------------
# Docker Builder (DinD)
# --------------------
docker-builder-start: ## Start the Docker-in-Docker builder container
	./scripts/docker-builder-start.sh

docker-builder-stop: ## Stop the Docker-in-Docker builder container
	docker compose -f docker-compose-builder.yml down

# --------------------
# Caddy
# --------------------
caddy-start: ## Start the Caddy reverse proxy
	docker compose -f docker-compose-caddy.yml up -d

caddy-stop: ## Stop the Caddy reverse proxy
	docker compose -f docker-compose-caddy.yml down

# --------------------
# Openclaw
# --------------------
openclaw-setup: ## Onboard this machine to Openclaw
	docker compose run --rm openclaw-gateway node dist/index.js onboard --no-install-daemon

openclaw-devices-list: ## List connected Openclaw devices
	docker exec $(OPENCLAW_GATEWAY_CONTAINER) node dist/index.js devices list

openclaw-devices-approve: ## Approve a device request — usage: make openclaw-devices-approve requestId=<id>
	docker exec $(OPENCLAW_GATEWAY_CONTAINER) node dist/index.js devices approve $(requestId)

openclaw-cmd: ## Run an Openclaw CLI command — usage: make openclaw-cmd cmd="<command>"
	docker compose run --rm openclaw-gateway node dist/index.js $(cmd)