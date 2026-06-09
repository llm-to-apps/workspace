ENV_FILE ?= .env
COMPOSE_FILE ?= docker-compose.yml
STACK_NAME ?= orchestra
DOCKER_COMPOSE ?= docker compose

.PHONY: up down build logs ps config ensure-swarm ensure-networks

up: build ensure-networks
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; fi
	@set -a; . ./$(ENV_FILE); set +a; \
	docker stack deploy --resolve-image never -c $(COMPOSE_FILE) "$${STACK_NAME:-$(STACK_NAME)}"

build:
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; fi
	@set -a; . ./$(ENV_FILE); set +a; \
	docker build -t "$${MANAGER_IMAGE:-orchestra-manager}:$${MANAGER_IMAGE_TAG:-local}" ./manager; \
	docker build -t "$${WEB_IMAGE:-orchestra-web}:$${WEB_IMAGE_TAG:-local}" ./web

ensure-swarm:
	@state="$$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || true)"; \
	if [ "$$state" != "active" ]; then docker swarm init >/dev/null; fi

ensure-networks: ensure-swarm
	@if [ ! -f "$(ENV_FILE)" ]; then cp .env.example "$(ENV_FILE)"; fi
	@set -a; . ./$(ENV_FILE); set +a; \
	for network in "$${DB_NETWORK_ID:-llagents_local_db}" "$${INGRESS_NETWORK_ID:-llagents_local_ingress}" "$${INTERNAL_NETWORK_ID:-llagents_local_internal}"; do \
		scope="$$(docker network inspect -f '{{.Scope}}' "$$network" 2>/dev/null || true)"; \
		if [ -z "$$scope" ]; then \
			docker network create --driver overlay --attachable "$$network" >/dev/null; \
		elif [ "$$scope" != "swarm" ]; then \
			containers="$$(docker network inspect -f '{{len .Containers}}' "$$network")"; \
			if [ "$$containers" != "0" ]; then \
				echo "Network $$network is $$scope-scope and still has containers; stop them before make up."; \
				exit 1; \
			fi; \
			docker network rm "$$network" >/dev/null; \
			docker network create --driver overlay --attachable "$$network" >/dev/null; \
		fi; \
	done

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
