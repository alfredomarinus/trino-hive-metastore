# Trino + Hive Metastore

A Docker Compose stack running **Trino** as a distributed SQL query engine, connected to three **Hive Metastore** instances (bronze / silver / gold medallion layers) backed by **MySQL**, with **MinIO** for S3-compatible object storage, **OPA** for policy-based access control and **DataHub** for metadata management.

## Architecture

| Service | Description |
|---------|-------------|
| **trino** | Distributed SQL query engine with HTTPS + password auth (ports `8080`, `8443`) |
| **hive-metastore-bronze** | Metadata service for the bronze layer (port `9083`) |
| **hive-metastore-silver** | Metadata service for the silver layer (port `9084`) |
| **hive-metastore-gold** | Metadata service for the gold layer (port `9085`) |
| **mysql** | Relational database storing Hive Metastore schemas (port `3306`) |
| **minio** | S3-compatible object storage (ports `9000` API, `9001` Console) |
| **minio-init** | One-shot container that creates `bronze`, `silver` and `gold` buckets |
| **opa** | Open Policy Agent for Trino access control (port `8181`) |
| **datahub-frontend** | DataHub web UI (port `9002`) |
| **datahub-gms** | DataHub metadata service (port `8082`) |
| **datahub-actions** | DataHub event-driven actions framework |
| **datahub-elasticsearch** | Search index for DataHub (port `9200`) |
| **datahub-broker** | Kafka broker for DataHub events (port `9092`) |
| **datahub-schema-registry** | Confluent Schema Registry for DataHub (port `8083`) |
| **datahub-zookeeper** | ZooKeeper for Kafka coordination (port `2181`) |
| **datahub-mysql** | Dedicated MySQL instance for DataHub (port `53306`) |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) ≥ 24.0
- [Docker Compose](https://docs.docker.com/compose/install/) ≥ 2.20

## Quick Start

```bash
# 1. Clone the repository and navigate to it
git clone <repo-url> && cd trino-hive-metastore

# 2. Copy the example env file and edit as needed
cp .env.example .env

# 3. Generate TLS keystore for Trino HTTPS (self-signed, for development)
openssl req -x509 -newkey rsa:2048 -keyout trino/key.pem -out trino/cert.pem \
  -days 365 -nodes -subj "/CN=trino"
cat trino/key.pem trino/cert.pem > trino/keystore.pem

# 4. Create a password file for Trino (requires htpasswd from apache2-utils)
htpasswd -B -C 10 -c trino/password.db admin
htpasswd -B -C 10 trino/password.db datahub

# 5. Build and start all services
make build && make up

# 6. Check the logs to ensure everything started properly
make logs
```

## Common Operations

```bash
make up              # Start core services (Trino, Hive, MinIO, OPA)
make down            # Stop all running services
make restart         # Restart all running services
make logs            # Follow all service logs
make reset           # Stop everything, remove volumes, and restart fresh
make status          # Show running containers
make shell           # Open a bash shell in the Trino container
make build           # Rebuild images (e.g. after Dockerfile changes)
```

### DataHub

DataHub services are behind a Compose profile and not started by default. Use the `datahub-` targets to manage them.

```bash
make datahub-up      # Start DataHub services
make datahub-down    # Stop DataHub services
make datahub-logs    # Follow DataHub service logs (gms, frontend, actions)
make datahub-ingest  # Run Trino metadata ingestion into DataHub
```

### OPA

```bash
make opa-test        # Test OPA policy evaluation against a sample request
make opa-logs        # Follow OPA logs
```

## Service URLs

| Service            | URL                      | Default Credentials         |
|--------------------|--------------------------|-----------------------------|
| Trino UI (HTTPS)   | https://localhost:8443   | `admin` / (password you set in step 4) |
| Trino UI (HTTP)    | http://localhost:8080    | Unauthenticated (dev only)  |
| MinIO Console      | http://localhost:9001    | `minioadmin` / `minioadmin` |
| DataHub            | http://localhost:9002    | `datahub` / `datahub`       |
| OPA                | http://localhost:8181    | —                           |

## Project Structure

```
.
├── datahub/
│   └── trino_recipe.yaml              # DataHub ingestion recipe for Trino
├── hive-metastore/
│   ├── conf/
│   │   └── hive-site.xml.template     # Hive config template (envsubst at startup)
│   └── Dockerfile                     # Custom Hive Metastore image
├── mysql/
│   └── init.sql                       # Creates bronze/silver/gold databases and grants
├── opa/
│   └── policies/
│       └── trino.rego                 # OPA access-control policy for Trino
├── trino/
│   ├── catalog/
│   │   ├── bronze.properties          # Trino catalog → hive-metastore-bronze
│   │   ├── silver.properties          # Trino catalog → hive-metastore-silver
│   │   └── gold.properties            # Trino catalog → hive-metastore-gold
│   ├── access-control.properties      # OPA access-control connector config
│   ├── config.properties              # Trino coordinator configuration
│   ├── jvm.config                     # JVM settings for Trino
│   ├── log.properties                 # Trino logging configuration
│   ├── node.properties                # Trino node configuration
│   ├── password-authenticator.properties  # Password auth config
│   ├── keystore.pem                   # TLS keystore (git-ignored)
│   └── password.db                    # Password file (git-ignored)
├── docker-compose.yaml
├── Makefile                           # Common operations
├── .env                               # Environment variables (git-ignored)
├── .env.example                       # Template for .env
└── README.md
```

## Configuration

All secrets and configurable values are in `.env` (git-ignored). See `.env.example` for defaults.

### Core

| Variable | Purpose |
|----------|---------|
| `MINIO_ROOT_USER` | MinIO admin username |
| `MINIO_ROOT_PASSWORD` | MinIO admin password |
| `MINIO_BROWSER_REDIRECT_URL` | MinIO Console redirect URL |
| `MINIO_API_PORT` | Port mapping for MinIO S3 API |
| `MINIO_CONSOLE_PORT` | Port mapping for MinIO Web Console |
| `MYSQL_ROOT_PASSWORD` | MySQL root password |
| `MYSQL_USER` | MySQL user for the Hive Metastore |
| `MYSQL_PASSWORD` | MySQL password for the Hive Metastore |
| `S3_REGION` | AWS/S3 region for Trino native S3 connector |
| `TRINO_SHARED_SECRET` | Shared secret for Trino internal communication |
| `TRINO_ADMIN_PASSWORD` | Trino admin password (used by DataHub ingestion) |
| `TZ` | Timezone for all services |
| `OPA_PORT` | Port mapping for OPA (default `8181`) |

### DataHub

| Variable | Purpose |
|----------|---------|
| `DATAHUB_VERSION` | DataHub image tag (default `v0.15.0`) |
| `DATAHUB_CONFLUENT_VERSION` | Confluent platform version (default `7.9.2`) |
| `DATAHUB_MYSQL_PASSWORD` | Password for DataHub's MySQL instance |
| `DATAHUB_GMS_PORT` | Port for DataHub GMS API (default `8082`) |
| `DATAHUB_FRONTEND_PORT` | Port for DataHub UI (default `9002`) |
| `DATAHUB_KAFKA_PORT` | Port for Kafka broker (default `9092`) |
| `DATAHUB_ZK_PORT` | Port for ZooKeeper (default `2181`) |
| `DATAHUB_ELASTIC_PORT` | Port for Elasticsearch (default `9200`) |
| `DATAHUB_SCHEMA_REGISTRY_PORT` | Port for Schema Registry (default `8083`) |
| `DATAHUB_MYSQL_PORT` | Port for DataHub MySQL (default `53306`) |
| `DATAHUB_SECRET` | DataHub frontend play secret |
| `DATAHUB_SYSTEM_CLIENT_SECRET` | DataHub system client secret |
| `DATAHUB_TELEMETRY_ENABLED` | Enable DataHub telemetry (default `false`) |
| `DATAHUB_TOKEN_SERVICE_SIGNING_KEY` | Signing key for DataHub tokens |
| `DATAHUB_TOKEN_SERVICE_SALT` | Salt for DataHub token service |
