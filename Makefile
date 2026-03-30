.PHONY: up down restart logs reset status shell build clean \
       datahub-up datahub-down datahub-logs \
       opa-test opa-logs

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

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf logs/*

# DataHub
datahub-up:
	docker compose --profile datahub up -d

datahub-down:
	docker compose --profile datahub down

datahub-logs:
	docker compose logs -f datahub-gms datahub-frontend datahub-actions

# OPA
opa-test:
	docker compose exec opa /opa eval -d /policies 'data.trino.allow' \
		-i '{"context":{"identity":{"user":"admin"}},"action":{"operation":"ExecuteQuery"}}'

opa-logs:
	docker compose logs -f opa
