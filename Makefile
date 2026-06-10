ENV_FILE ?= .env
COMPOSE_FILE ?= docker-compose.yml
STACK_NAME ?= orchestra
DOCKER_COMPOSE ?= docker compose

.PHONY: up down build logs ps config ensure-swarm

up: build ensure-swarm
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; fi
	@set -a; . ./$(ENV_FILE); set +a; \
	stack_name="$${STACK_NAME:-$(STACK_NAME)}"; \
	docker stack deploy --prune --resolve-image never -c $(COMPOSE_FILE) "$$stack_name"; \
	docker service inspect "$${stack_name}_manager" >/dev/null 2>&1 && \
		docker service update --force "$${stack_name}_manager" >/dev/null

build:
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; fi
	@set -a; . ./$(ENV_FILE); set +a; \
	docker build -t "$${MANAGER_IMAGE:-orchestra-manager}:$${MANAGER_IMAGE_TAG:-local}" ./manager

ensure-swarm:
	@state="$$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || true)"; \
	if [ "$$state" != "active" ]; then docker swarm init >/dev/null; fi

down:
	@set -a; [ -f "$(ENV_FILE)" ] && . ./$(ENV_FILE); set +a; \
	docker stack rm "$${STACK_NAME:-$(STACK_NAME)}"

logs:
	@set -a; [ -f "$(ENV_FILE)" ] && . ./$(ENV_FILE); set +a; \
	for service in $$(docker stack services "$${STACK_NAME:-$(STACK_NAME)}" --format '{{.Name}}'); do \
		docker service logs -f "$$service" & \
	done; wait

ps:
	@set -a; [ -f "$(ENV_FILE)" ] && . ./$(ENV_FILE); set +a; \
	docker stack services "$${STACK_NAME:-$(STACK_NAME)}"

config:
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; fi
	$(DOCKER_COMPOSE) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) config
