.PHONY: help start stop restart build logs \
        update-password clear-known-hosts \
        docker-builder-start openclaw-setup openclaw-fix-pairing

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# --------------------
# Stack
# --------------------
start: ## Start all services
	docker-compose up -d

stop: ## Stop and remove all containers
	docker-compose down

restart: ## Restart all containers
	docker-compose restart

build: ## Rebuild image
	docker-compose down
	docker-compose build --no-cache

logs: ## Follow container logs
	docker-compose logs -f

# --------------------
# Maintenance
# --------------------
update-password: ## Update SSH + code-server password
	./scripts/update_password.sh

clear-known-hosts: ## Clear local SSH known_hosts entry for dev-server
	./scripts/clear_known_hosts.sh

# --------------------
# Docker Builder (DinD)
# --------------------
docker-builder-start: ## Start the Docker-in-Docker builder container
	./scripts/docker-builder-start.sh

docker-builder-stop: ## Stop the Docker-in-Docker builder container
	docker compose -f docker-compose-builder.yml down

# --------------------
# Openclaw
# --------------------
openclaw-setup: ## Onboard this machine to Openclaw
	./scripts/openclaw-setup.sh

openclaw-fix-pairing: ## Fix Openclaw silent pairing (pending.json)
	./scripts/openclaw-fix-pairing.sh
