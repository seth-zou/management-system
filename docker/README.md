# Docker Deployment

This directory contains files for containerized deployment of the OCA Management
System addon repository on Odoo 19.0.

## Files

| File | Description |
|---|---|
| `Dockerfile` | Builds an Odoo 19.0 image with all OCA management-system addons pre-installed |
| `docker-compose.yml` | Orchestration file defining Odoo + PostgreSQL services |
| `docker/odoo.conf` | Custom Odoo configuration (env-var interpolated at startup) |
| `docker/entrypoint-wrapper.sh` | Entrypoint script that resolves env vars, waits for DB, then launches Odoo |
| `docker/.env.example` | Sample environment variables — copy to `.env` and customize |

## Quick Start

```bash
# 1. (Optional) customize environment variables
cp docker/.env.example .env
# Edit .env — change ADMIN_PASSWD, DB_PASSWORD for production!

# 2. Build and start
docker compose up -d --build

# 3. Check logs
docker compose logs -f odoo

# 4. Open Odoo in browser
open http://localhost:8069
```

## First-Time Database Setup

When Odoo starts for the first time, navigate to `http://localhost:8069` and:

1. Enter the **Master Password** (default: `admin` — change via `ADMIN_PASSWD` in `.env`)
2. Create a new database
3. After database creation, install the management system modules you need

### Install all management-system modules via CLI

```bash
docker compose exec odoo odoo -d <your_db_name> \
  -i mgmtsystem,mgmtsystem_action,mgmtsystem_audit,mgmtsystem_kpi,mgmtsystem_manual,mgmtsystem_nonconformity,mgmtsystem_review,mgmtsystem_risk,mgmtsystem_quality,mgmtsystem_environment,mgmtsystem_health_safety,mgmtsystem_hazard,mgmtsystem_hazard_risk,mgmtsystem_information_security,mgmtsystem_security_event,mgmtsystem_survey,mgmtsystem_partner,mgmtsystem_nonconformity_hr,mgmtsystem_nonconformity_repair,mgmtsystem_info_security_manual,document_page_procedure,document_page_quality_manual,document_page_work_instruction,document_page_environmental_aspect,document_page_environment_manual,document_page_health_safety_manual \
  --stop-after-init
```

### Install a single module

```bash
docker compose exec odoo odoo -d <your_db_name> \
  -i mgmtsystem \
  --stop-after-init
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `ADMIN_PASSWD` | `admin` | Odoo master password (database management) |
| `DB_USER` | `odoo` | PostgreSQL username |
| `DB_PASSWORD` | `odoo` | PostgreSQL password |
| `DB_NAME` | `postgres` | PostgreSQL default database name |
| `ODOO_PORT` | `8069` | Host port mapped to Odoo HTTP |
| `ODOO_LONGPOLLING_PORT` | `8072` | Host port mapped to Odoo longpolling |

### Odoo Configuration

The `docker/odoo.conf` file is template-interpolated at container startup via
`entrypoint-wrapper.sh`. The following environment variables are injected:

| Env Var (compose) | odoo.conf placeholder | Default |
|---|---|---|
| `ADMIN_PASSWD` | `${ADMIN_PASSWD}` | `admin` |
| `HOST` | `${DB_HOST}` | `db` |
| — | `${DB_PORT}` | `5432` |
| `USER` | `${DB_USER}` | `odoo` |
| `PASSWORD` | `${DB_PASSWORD}` | `odoo` |

### Performance Tuning

Edit `docker/odoo.conf` to adjust:

- `workers` — number of HTTP worker processes (default: 4; set to `0` for
  thread mode)
- `max_cron_threads` — number of cron threads (default: 1)
- `limit_memory_soft` / `limit_memory_hard` — per-worker memory limits
- `limit_time_cpu` / `limit_time_real` — CPU and wall-clock time limits

## Data Volumes

| Volume | Container Path | Purpose |
|---|---|---|
| `odoo-db-data` | `/var/lib/postgresql/data` | PostgreSQL data files |
| `odoo-web-data` | `/var/lib/odoo` | Odoo file store, sessions, attachments |

### Backup

```bash
# Backup database
docker compose exec db pg_dump -U odoo <db_name> > backup.sql

# Backup file store
docker compose run --rm -v "$(pwd)/backup:/backup" odoo \
  tar czf /backup/filestore.tar.gz /var/lib/odoo
```

### Restore

```bash
# Restore database
cat backup.sql | docker compose exec -T db psql -U odoo <db_name>

# Restore file store
docker compose run --rm -v "$(pwd)/backup:/backup" odoo \
  tar xzf /backup/filestore.tar.gz -C /
```

## Production Notes

1. **Change default passwords** — Set strong `ADMIN_PASSWD` and `DB_PASSWORD` in `.env`
2. **Use TLS** — Put a reverse proxy (nginx, Traefik, Caddy) in front for HTTPS
3. **Resource limits** — Adjust `workers` and memory limits based on available resources
4. **Database backups** — Set up scheduled `pg_dump` or use a managed PostgreSQL service
5. **Email** — Configure an SMTP server via Odoo settings or add `smtp_*` options in `odoo.conf`
