.PHONY: up down restart logs reset status shell build \
       datahub-ingest datahub-logs opa-test opa-logs

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

reset:
	docker compose down -v
	docker compose up -d

status:
	docker compose ps

shell:
	docker compose exec trino bash

build:
	docker compose build --no-cache

# DataHub
datahub-logs:
	docker compose logs -f datahub-gms datahub-frontend datahub-actions

datahub-ingest:
	pip install --quiet 'acryl-datahub[trino]' && \
	datahub ingest -c datahub/trino_recipe.yaml

# OPA
opa-test:
	docker compose exec opa /opa eval -d /policies 'data.trino.allow' \
		-i '{"context":{"identity":{"user":"admin"}},"action":{"operation":"ExecuteQuery"}}'

opa-logs:
	docker compose logs -f opa
