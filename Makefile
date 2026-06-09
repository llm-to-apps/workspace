ENV_FILE ?= .env
COMPOSE_FILE ?= docker-compose.yml
DOCKER_COMPOSE ?= docker compose

.PHONY: up down build logs ps config ensure-networks

up: ensure-networks
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; fi
	$(DOCKER_COMPOSE) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) up -d --build --remove-orphans

ensure-networks:
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; fi
	@set -a; . ./$(ENV_FILE); set +a; \
	for network in "$${DB_NETWORK_ID:-llagents_local_db}" "$${INGRESS_NETWORK_ID:-llagents_local_ingress}" "$${INTERNAL_NETWORK_ID:-llagents_local_internal}"; do \
		docker network inspect "$$network" >/dev/null 2>&1 || docker network create "$$network" >/dev/null; \
	done

down:
	$(DOCKER_COMPOSE) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down

build:
	$(DOCKER_COMPOSE) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) build

logs:
	$(DOCKER_COMPOSE) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs -f

ps:
	$(DOCKER_COMPOSE) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) ps

config:
	$(DOCKER_COMPOSE) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) config
