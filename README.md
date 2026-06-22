# htdev.space Deployment Stack

Production deployment bundle for the `htdev.space` infrastructure. This repository brings together the Docker Compose files, Nginx ingress templates, monitoring services, and bootstrap script used to provision and run the stack on a Debian-based VPS.

This is designed as a reusable deployment platform, not a single-project repo. EventBox and Elearning are the first workloads currently deployed here, and the same pattern can be extended to host additional applications and services over time.

## What’s in here

- `eventbox/` - runtime for the Eventbox application stack
- `elearning/` - runtime for the Elearning application stack
- `ingress/` - Nginx reverse proxy and TLS termination
- `monitor/` - Grafana, Prometheus, Node Exporter, and Portainer
- `configs/` - local-only configuration and secret examples
- `kickoff.sh` - Debian bootstrap script for installing Docker and basic utilities

## Architecture

```text
Internet
  |
  v
Nginx ingress (80/443)
  |---------------------> eventboxserver.${DOMAIN}
  |---------------------> eventboxsocket.${DOMAIN}
  |---------------------> elearningserver.${DOMAIN}
  |---------------------> elearningsocket.${DOMAIN}
  |---------------------> elearningfile.${DOMAIN}
  |---------------------> grafana.${DOMAIN}
  |---------------------> portainer.${DOMAIN}
  |
  +--> shared Docker network (`web-network`)
        |
        +--> current app stacks
        +--> Grafana
        +--> Portainer
        +--> internal services on isolated networks

Internal-only services:
- PostgreSQL
- Redis
- Prometheus
- Node Exporter
- sentiment-service
- Elasticsearch
- SeaweedFS
```

## Repository Layout

```text
.
├── configs/
│   ├── eventbox/
│   │   ├── .env.example
│   │   ├── application.properties
│   │   ├── certs/
│   │   └── service-account-key.json
│   ├── elearning/
│   │   ├── .env.example
│   │   ├── application.properties.example
│   │   ├── jitsi.pk.example
│   │   ├── service-account-key.json.example
│   │   └── certs/
│   ├── ingress/
│   │   ├── .env.example
│   │   └── certs/
│   └── monitor/
│       └── .env.example
├── eventbox/
│   └── docker-compose.yml
├── elearning/
│   └── docker-compose.yml
├── ingress/
│   ├── docker-compose.yml
│   └── templates/
├── monitor/
│   ├── prom/
│   │   ├── docker-compose.yml
│   │   └── prometheus.yml
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   └── node-exporter-overview.json
│   │   └── provisioning/
│   │       ├── alerting/
│   │       │   ├── contact-points.yml
│   │       │   ├── cpu-usage-alert.yml
│   │       │   └── notification-policies.yml
│   │       ├── dashboards/
│   │       │   └── dashboards.yml
│   │       └── datasources/
│   │           └── prometheus.yml
│   └── portainer/
│       └── docker-compose.yml
└── kickoff.sh
```

## Prerequisites

- Debian-based Linux VPS
- Docker Engine and Docker Compose plugin
- A domain name pointing to the server
- TLS certificates placed in `configs/ingress/certs/`
- Eventbox runtime config in `configs/eventbox/`
- Elearning runtime config in `configs/elearning/`
- A Docker network named `web-network`

## Bootstrap the Host

The `kickoff.sh` script installs Docker, common utilities, and enables the Docker service on Debian.

```bash
chmod +x kickoff.sh
./kickoff.sh
```

Notes:

- The script uses `sudo` and expects a Debian family system.
- After running it, log out and back in so your user is added to the `docker` group.

## Configure Local Secrets

The Compose files reference local config files that are intentionally not committed.
If you want to scaffold the missing local files in one shot, run `scripts/bootstrap-local-config.sh`.

### Eventbox

Create the following files from the examples:

- `configs/eventbox/.env.eventbox` from `configs/eventbox/.env.example`
- `configs/eventbox/application.properties`
- `configs/eventbox/service-account-key.json`
- `configs/eventbox/certs/`

### Elearning

Create the following files from the examples:

- `configs/elearning/.env.elearning` from `configs/elearning/.env.example`
- `configs/elearning/application.properties` from `configs/elearning/application.properties.example`
- `configs/elearning/service-account-key.json` from `configs/elearning/service-account-key.json.example`
- `configs/elearning/jitsi.pk` from `configs/elearning/jitsi.pk.example`
- `configs/elearning/certs/`

### Ingress

- `configs/ingress/.env.nginx` from `configs/ingress/.env.example`
- `configs/ingress/certs/fullchain.pem`
- `configs/ingress/certs/privkey.pem`

### Monitoring

- `configs/monitor/.env.grafana` from `configs/monitor/.env.example`
- Grafana provisioning files under `configs/monitor/grafana/`

## Environment Variables

### `configs/eventbox/.env.eventbox`

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=change-me
POSTGRES_DB=postgres
```

These values are used by the Postgres container in `eventbox/docker-compose.yml`.

### `configs/elearning/.env.elearning`

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=change-me
POSTGRES_DB=postgres
```

These values are used by the Postgres container in `elearning/docker-compose.yml`, along with the shared Redis and Elasticsearch services in the same stack.

### `configs/ingress/.env.nginx`

```env
DOMAIN=example.com
```

This domain is injected into the Nginx templates to generate the public hostnames.

### `configs/monitor/.env.grafana`

```env
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=change-me
GF_SERVER_ROOT_URL=https://grafana.example.com
GF_SERVER_SERVE_FROM_SUB_PATH=false
GRAFANA_TELEGRAM_BOT_TOKEN=change-me
GRAFANA_TELEGRAM_CHAT_ID=change-me
GRAFANA_SMTP_ENABLED=true
GRAFANA_SMTP_HOST=smtp.example.com:587
GRAFANA_SMTP_USER=change-me
GRAFANA_SMTP_PASSWORD=change-me
GRAFANA_SMTP_FROM_ADDRESS=grafana@example.com
GRAFANA_SMTP_FROM_NAME=Grafana
GRAFANA_SMTP_SKIP_VERIFY=false
GRAFANA_SMTP_STARTTLS_POLICY=MandatoryStartTLS
GRAFANA_EMAIL_ADDRESSES=ops@example.com
```

## Networking

The stack expects an external Docker network named `web-network`.

```bash
docker network create web-network
```

Attach any additional public-facing services to this network if you want them to be routable through the shared ingress layer.

## Run the Stack

Start each Compose project from its own directory:

```bash
docker compose -f eventbox/docker-compose.yml up -d
docker compose -f elearning/docker-compose.yml up -d
docker compose -f monitor/prom/docker-compose.yml up -d
docker compose -f monitor/portainer/docker-compose.yml up -d
docker compose -f ingress/docker-compose.yml up -d
```

You can also bring up individual stacks independently while iterating on config.

## Public Endpoints

Once DNS and TLS are in place, the ingress layer exposes:

- `https://eventboxserver.${DOMAIN}`
- `https://eventboxsocket.${DOMAIN}`
- `https://elearningserver.${DOMAIN}`
- `https://elearningsocket.${DOMAIN}`
- `https://elearningfile.${DOMAIN}`
- `https://grafana.${DOMAIN}`
- `https://portainer.${DOMAIN}`

The templates also answer on the `www.` subdomains for each host.

## Monitoring

- Prometheus scrapes `node-exporter:9100`
- Grafana stores data in a named Docker volume
- Grafana is provisioned with a default Prometheus datasource
- Grafana is provisioned with a default Node Exporter dashboard
- Grafana is provisioned with a CPU usage alert that routes to Telegram
- Portainer is mounted directly to the Docker socket for cluster management
- Each service in the stack includes a Docker healthcheck, and `eventbox-server` is considered healthy when `GET /public/api/v1/configs/client-config` returns `200`
- `elearning-server` is considered healthy when `GET /swagger-ui/index.html` returns `200`
- `seaweedfs-volume` is considered healthy when `GET http://127.0.0.1:8082/status` returns `200`

## Extending The Stack

To add another application or service later, follow the same pattern used by EventBox:

- create a new Compose file in its own directory
- attach public-facing containers to the shared `web-network`
- keep databases, queues, and other backend-only services on an isolated internal network
- add a new Nginx template under `ingress/templates/` if the service needs a public hostname
- add matching example env files under `configs/`

This keeps each workload isolated while still sharing the same ingress and monitoring layer.

## Notes

- The Eventbox stack pulls prebuilt images from Docker Hub.
- The Elearning stack pulls prebuilt images from Docker Hub and exposes `elearningserver`, `elearningsocket`, and `elearningfile` through ingress.
- `eventbox-server` runs with `application.properties` mounted from the host.
- `sentiment-service` includes a health check that expects `http://127.0.0.1:8000/health`.
- Sensitive files and generated certificates are excluded from version control through `.gitignore`.

## Security Considerations

- Replace the sample passwords and IDs before exposing the stack publicly.
- Use real TLS certificates, not self-signed certs, for public deployments.
- Treat `service-account-key.json` as a secret and keep it outside git.
- Restrict access to Portainer and Grafana if they should not be internet-facing.
