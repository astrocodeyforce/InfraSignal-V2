# InfraSignal — Architecture Guide

**Last Updated:** 2026-05-27  
**Version:** 2.6  
**Live URL:** https://infrasignal.org  
**Server:** Linux VPS (origin behind Cloudflare) — 2 vCPU, 8 GB RAM, 96 GB disk (x86_64)

> See also: [`SYSTEM-MAP.md`](SYSTEM-MAP.md) for a visual map of containers,
> networks, request flow, and where-to-edit-what cheat-sheet.

---

## Current Production State (as of 2026-05-26)

### What is live right now

| Aspect | Value |
| --- | --- |
| URL | `https://infrasignal.org` (HTTP 200) |
| Hostname filter | Only `infrasignal.org` + `www.infrasignal.org`. All other Host headers → 444. |
| Compose project | `docker` (not `infrasignal-v2` — that one is legacy, stopped) |
| Compose file | `docker/docker-compose-prod.yml` |
| Source mount | `/opt/infrasignal-v2 → /var/www/fixmystreet` (live bind mount; deploys are "git pull on the box") |
| Branch the prod checkout sits on | `dev` (113+ commits ahead of `main` at the time of tagging) |
| Rollback marker | git tag `prod-2026-05-03` on commit `39b493ae` |

### Intended workflow

```
local dev work  →  staging.infrasignal.org  →  infrasignal.org (prod)
   (/opt/infrasignal-dev)   (compose project staging)   (compose project docker)
```

- Dev is a separate checkout (`/opt/infrasignal-dev`) with its own
  postgres and memcached as of 2026-05-26 — see "Development
  environment" below.
- Staging is its own compose project, runs on `0.0.0.0:8080` (public
  demo link **http://REDACTED-IP:8080/** as of 2026-05-29), has its
  own DB and memcached, fully isolated network, and its own source
  tree at `/opt/infrasignal-staging`.
- Prod runs whatever's currently checked out at `/opt/infrasignal-v2`
  on whatever branch it's on. The `bin/deploy` script enforces a
  clean working tree before `git pull` and defaults to `dev` branch.

#### Promotion is MANUAL (by design — never automatic)

The three environments are deliberately decoupled. Changes flow one
direction, and only when a human pushes them:

```
1. make + verify change on dev        (/opt/infrasignal-dev, :3001)
2. git commit + push to origin/dev
3. promote CODE to staging (manual rsync):
     sudo rsync -a --delete --exclude='.git/' --exclude='local/' \
       --exclude='web/photo/' /opt/infrasignal-dev/ /opt/infrasignal-staging/
4. (optional) promote DATA with bin/refresh-db or bin/seed-demo-photos.sh
5. only after staging looks right → promote to prod
```

- There is **no** live link or auto-sync between environments. Each has
  its own source tree and its own database.
- There are no `staging`/`production` git branches: all work lands on
  `dev`; environments are deployed/promoted from there.

### Recent changes to the deploy script

- `BRANCH` default changed from `main` (which is 2 months stale) to
  `dev`. Override with `DEPLOY_BRANCH=main ./bin/deploy ...`.
- `--full` and `--migrate` now call `require_clean_tree()` and abort
  on uncommitted changes (with a `git status --short` of what to fix).
- `--quick` and `--rollback` skip the clean-tree check (those are
  valid in emergencies).

### Legacy `infrasignal-v2` compose project

Four containers (`infrasignal-v2-nginx-1`, `-fixmystreet-1`, `-postgres-1`,
`-memcached-1`) — original FixMyStreet bring-up before the prod stack
was refactored into compose project `docker`. They were in a
`Restarting (127)` loop because their image referenced a missing
`bin/cron-wrapper`. Stopped on 2026-05-26 and `--restart=no` set.
Volumes (`infrasignal-v2_postgres-data`) and network preserved. The
DB inside was verified empty before stopping.

### CI-built image: where it lives and how to deploy it

GitHub Actions builds and pushes an image to
`ghcr.io/astrocodeyforce/infrasignal-v2` on every push to `main`,
`dev`, or `staging`. Tags applied:

| Tag | Created from |
| --- | --- |
| `ghcr.io/astrocodeyforce/infrasignal-v2:dev` | every push to `dev` |
| `ghcr.io/astrocodeyforce/infrasignal-v2:<sha7>` | every push to any tracked branch |
| `ghcr.io/astrocodeyforce/infrasignal-v2:latest` | every push to `main` |

`docker/docker-compose-prod-image.yml` is a **draft** compose file
that pulls one of those images instead of bind-mounting the source.
Not active yet. Activate (once staging has validated a tag):

```
IMAGE_TAG=<sha-or-dev> sudo docker compose -p docker \
    -f docker/docker-compose-prod-image.yml --env-file docker/.env up -d
```

### Staging environment

Compose project `staging`, file `docker/docker-compose-staging.yml`.
Four services on isolated `staging_default` network:

| Service | Notes |
| --- | --- |
| `staging-nginx-1` | `nginx:1.27.2`, ports `0.0.0.0:8080:80` (public demo link `http://REDACTED-IP:8080/`), uses `conf/nginx.conf-docker` (NOT prod) |
| `staging-fixmystreet-1` | Built from `Dockerfile-development`. Mounts whole source tree AND overrides `conf/general.yml` with `conf/general.yml-staging.runtime` |
| `staging-db-1` | Postgres 13.11. Its own volume `staging_staging-pgdata`. Uses `fms` role + `infrasignal` database (created at bootstrap) |
| `staging-memcached-1` | `memcached -m 64 -c 512` |

The runtime config (`conf/general.yml-staging.runtime`) is generated
from `conf/general.yml-staging` (template) by substituting
`POSTGRES_PASSWORD` from `docker/.env`. The runtime file is
gitignored. Use `sudo bin/staging-deploy --regen` to refresh it.

Access via SSH tunnel (no public hostname yet):

```
ssh -L 8080:127.0.0.1:8080 root@REDACTED-HOST
# then visit http://localhost:8080 in your browser
```

**Known follow-up:** `bin/update-schema --commit` on a fresh staging
DB only loaded the base schema (v0093). The custom
`db/schema_0094-priority-zones.sql` had to be applied manually. Future
bootstraps should sweep numbered SQL above the base version.

### Development environment (`/opt/infrasignal-dev`)

The dev checkout is a **second copy of the repo** at
`/opt/infrasignal-dev` that runs its own app + nginx on `:3001` (HTTP
only) and is the day-to-day editor target. Compose project
`infrasignal-dev`, file `/opt/infrasignal-dev/docker/docker-compose-local.yml`.

**As of 2026-05-26, dev is fully DB-isolated.** It no longer shares
production's postgres / memcached. Two new services were added to
dev's compose:

| Service | Image / build | Alias on docker_default | Backing volume |
| --- | --- | --- | --- |
| `dev-db` | `postgres:13.11` with `en_GB.UTF-8` baked in | `dev-postgres.svc` | `infrasignal-dev_dev-pgdata` |
| `dev-memcached` | `memcached:1.6.32` | `dev-memcached.svc` | n/a (in-memory) |

`/opt/infrasignal-dev/conf/general.yml` was switched from `postgres.svc`
to `dev-postgres.svc` and from `memcached.svc` to `dev-memcached.svc`.
The pre-isolation file is preserved at
`/opt/infrasignal-dev/conf/general.yml.pre-isolation-2026-05-26.bak`.

Why this mattered: before isolation, dev connected as the postgres
**superuser** with the prod superuser password, against the prod
database. Any test in dev (sign-ins, report creation, schema poking)
mutated production data. Dev is now a clean empty DB; data flows
prod → dev only on demand (planned `bin/refresh-db` script — not yet
built).

To bootstrap a fresh dev DB if it ever needs reloading:

```
cd /opt/infrasignal-dev
sudo docker compose -p infrasignal-dev -f docker/docker-compose-local.yml up -d dev-db dev-memcached
sudo docker exec infrasignal-dev-dev-db-1 psql -U postgres -c "CREATE DATABASE infrasignal;"
sudo docker compose -p infrasignal-dev -f docker/docker-compose-local.yml run --rm dev-fixmystreet bin/update-schema --commit
sudo docker restart infrasignal-dev-dev-fixmystreet-1
```

Dev still attaches to the `docker_default` bridge so the hand-started
`dev-nginx-proxy` container can reach `dev-fixmystreet.svc`. The dev
DB and dev memcached share that bridge but expose **different**
aliases than prod, so resolution never crosses streams.

### Things that are still pending (deliberately not done yet)

- Switching prod off the live `../:/var/www/fixmystreet` bind mount in
  favour of the CI-built image. The variant compose file
  (`docker/docker-compose-prod-image.yml`) is in place; flip when
  staging has validated an image tag end-to-end.
- Exposing staging via a public hostname + SSL cert.
- Adding a public `staging` server_name to the prod nginx (currently
  locked to `infrasignal.org` and `www.infrasignal.org`).
- A `bin/refresh-db` script for PII-scrubbed one-way prod → staging
  and prod → dev seeding.

---

## System Overview

InfraSignal is a civic infrastructure reporting platform built on [FixMyStreet Platform](https://fixmystreet.org/) v6.0 (AGPL v3). It runs as a set of Docker containers on a single Linux server, fronted by Cloudflare for DNS, SSL termination, and DDoS protection.

```
Internet → Cloudflare (DNS + SSL) → Origin Server
                                        ├── nginx (reverse proxy, ports 80/443)
                                        ├── fixmystreet (Perl/Starman app, port 9000)
                                        ├── db (PostgreSQL 13.11 + PostGIS)
                                        └── memcached (session/query cache)
```

---

## Technology Stack

| Layer | Technology | Details |
|-------|-----------|---------|
| **Backend** | Perl / Catalyst / PSGI | Starman multi-worker server (10 workers, preload-app) |
| **Database** | PostgreSQL 13.11 + PostGIS | 512 MB shared_buffers, 200 max_connections |
| **Templates** | Template Toolkit | Cobrand override system (`templates/web/infrasignal/`) |
| **Frontend** | jQuery, OpenLayers | Map-based report submission |
| **Reverse Proxy** | Nginx 1.27.2 | Rate limiting, connection limiting, security headers |
| **Caching** | Memcached 1.6.32 | 128 MB, 1024 connections |
| **Containerisation** | Docker Compose | Separate dev and prod compose files |
| **SSL/CDN** | Cloudflare | Full (Strict) SSL, origin certificates |
| **CAPTCHA** | Cloudflare Turnstile | Server-side validation on all forms |
| **Email** | SendGrid SMTP | STARTTLS, verified sender: `noreply@infrasignal.org` |
| **Image Moderation** | SightEngine API | Nudity, weapons, violence, gore, drugs, AI detection |
| **Text Moderation** | OpenAI API | Profanity, PII, toxic/sexual/violent content |
| **Auth** | Google OIDC | Social sign-in via OAuth 2.0 |

---

## Container Topology

### Production (`docker/docker-compose-prod.yml`)

4 services only — minimal, hardened, resource-limited:

| Service | Image | Resource Limit | Health Check | Restart |
|---------|-------|---------------|--------------|---------|
| **nginx** | nginx:latest | 256 MB / 0.5 CPU | `curl -f http://localhost:80/` | always |
| **fixmystreet** | custom build | 3 GB / 2 CPU | `curl -f http://localhost:9000/` | always |
| **db** | custom (PostgreSQL 13.11) | 2 GB / 1 CPU | `pg_isready -U postgres` | always |
| **memcached** | memcached:latest | 256 MB / 0.25 CPU | `echo stats \| busybox nc 127.0.0.1 11211` | always |

All services log to `json-file` with 10 MB max size, 3 rotated files.

### Development (`docker/docker-compose-dev.yml`)

7 services — includes dev tools:

| Service | Purpose |
|---------|---------|
| nginx | Same as prod |
| fixmystreet | Same as prod (source-mounted for live reload) |
| db | Same as prod |
| memcached | Same as prod |
| **mailhog** | Local email catcher (dev only) |
| **css_watcher** | SCSS auto-compile on file change (dev only) |
| **setup** | One-shot DB migration + asset build (dev only) |

> **CRITICAL:** The dev compose file must NEVER serve production traffic.

---

## Directory Structure (Key Paths)

```
/opt/infrasignal-v2/                  ← Project root
├── docker/
│   ├── docker-compose-prod.yml       ← PRODUCTION compose (4 services)
│   ├── docker-compose-dev.yml        ← DEVELOPMENT compose (7 services)
│   ├── .env                          ← Secrets (gitignored)
│   ├── start-server                  ← Starman launch script
│   └── setup                         ← First-run DB init script
├── bin/
│   ├── deploy                        ← Production deployment script
│   ├── backup-db                     ← Automated DB backup
│   ├── healthcheck                   ← 9-point health check
│   ├── send-reports                  ← Send pending reports to authorities
│   ├── send-alerts                   ← Send email alerts to subscribers
│   ├── send-comments                 ← Send comment notifications
│   └── classify-reports              ← OSM priority zone classification
├── conf/
│   ├── nginx.conf-prod               ← Production nginx config (rate limiting, security headers)
│   ├── nginx.conf-dev                ← Development nginx config
│   └── general.yml                   ← App config (gitignored, contains API keys)
├── perllib/FixMyStreet/
│   ├── Cobrand/Infrasignal.pm        ← Main cobrand module
│   ├── App/Controller/               ← Catalyst controllers
│   └── DB/Result/                    ← DBIC result classes
├── templates/web/infrasignal/        ← Template overrides
├── web/cobrands/infrasignal/         ← CSS/SCSS + static assets
├── locale/                           ← Translation files (EN, TR, ES, RU)
└── PROJECT PLAN/                     ← Local-only docs (gitignored)
```

---

## Git Branching Strategy

```
main              ← Production branch. Always deployable. bin/deploy pulls from here.
  └── dev         ← Active development. Day-to-day work and testing.
       └── feature/xyz  ← Short-lived feature branches. Merge into dev, then delete.
```

| Branch | Purpose | Deploy? |
|--------|---------|---------|
| `main` | Production code. Only receives merges from `dev`. | YES — `bin/deploy` pulls this. |
| `dev` | Development and testing. All new work starts here. | NO — dev environment only. |
| `feature/*` | Individual features or fixes. Branch from `dev`, merge back to `dev`. | NO |

### Git Remotes

| Remote | URL | Purpose |
|--------|-----|---------|
| `origin` | GitHub | Public repo (AGPL code only) |
| `private` | (private mirror) | Private repo (same code, backup) |

### Archived Branches

All old version branches (`Version-1` through `Version-2.2`) have been archived as tags (`archive/Version-*`) and deleted as branches.

---

## Environment Separation

### Production Environment

| Aspect | Value |
|--------|-------|
| **Server** | Linux VPS (origin behind Cloudflare) |
| **Compose File** | `docker/docker-compose-prod.yml` |
| **Branch** | `main` |
| **URL** | https://infrasignal.org |
| **Deploy** | `bin/deploy` (auto-backup, health check, rollback) |
| **Backups** | Daily at 3 AM UTC → `/opt/backups/infrasignal/` (30-day retention) |
| **Monitoring** | `bin/healthcheck` (cron every 5 min) + UptimeRobot (external, 5 min) |
| **Logs** | `/var/log/infrasignal-*.log`, logrotate 14 days |

### Development Environment

| Aspect | Value |
|--------|-------|
| **Server** | Local machine or separate dev server |
| **Compose File** | `docker/docker-compose-dev.yml` |
| **Branch** | `dev` or `feature/*` |
| **URL** | http://localhost:3000 |
| **Extra Services** | MailHog (email catcher), CSS watcher, setup container |
| **Database** | Separate from production — test data is acceptable here |

### Rules

1. **Production and development MUST use separate compose files.** Production = `docker-compose-prod.yml`. Development = `docker-compose-dev.yml`.
2. **Never run `docker-compose-dev.yml` to serve production traffic.** It includes MailHog, CSS watcher, and has no resource limits.
3. **Never test on the production database.** If you need to test DB changes, use a local dev environment or a copy of the backup.
4. **The `main` branch is always production.** Never push untested code directly to `main`. All work goes through `dev` first.

---

## Backup System

### Automated Backups (`bin/backup-db`)

- Runs daily at 3 AM UTC via `/etc/cron.d/infrasignal-backup`
- Produces: `infrasignal_YYYYMMDD_HHMMSS.sql.gz` (gzip-compressed `pg_dump`)
- Location: `/opt/backups/infrasignal/` (directory `chmod 700`, files `chmod 600`)
- Retention: 30 days (older files auto-pruned)
- Validation: File must be > 1 KB or the script reports failure

### Pre-Deploy Backups

- `bin/deploy` automatically creates a backup before every deployment
- Stored in the same backup directory with timestamp

### Manual Backup

```bash
cd /opt/infrasignal-v2
bin/backup-db
```

### Restore from Backup

```bash
gunzip < /opt/backups/infrasignal/infrasignal_YYYYMMDD_HHMMSS.sql.gz | \
  docker compose -f docker/docker-compose-prod.yml exec -T db psql -U postgres infrasignal
```

---

## Monitoring

### Health Check (`bin/healthcheck`)

Runs every 5 minutes via `/etc/cron.d/infrasignal-healthcheck`. Performs 9 checks:

1. HTTPS reachability (curl https://infrasignal.org)
2. nginx container running
3. fixmystreet container running
4. db container running
5. memcached container running
6. PostgreSQL connectivity (`pg_isready`)
7. Disk space (warns at > 90%)
8. Memory usage (warns at > 90%)
9. Backup freshness (warns if no backup in 48 hours)

Failures logged to `/var/log/infrasignal-healthcheck.log`.

### External Monitoring

- **UptimeRobot** — monitors `https://infrasignal.org` every 5 minutes, email alert on downtime.

---

## Deployment

### Standard Deploy

```bash
cd /opt/infrasignal-v2
bin/deploy
```

This will:
1. Auto-backup the database
2. `git pull origin main`
3. Rebuild and restart containers (`docker-compose-prod.yml`)
4. Run health check (10 retries with 10s intervals)
5. Report success or failure

### Deploy Options

| Flag | Effect |
|------|--------|
| `--quick` | Skip DB backup (faster, for non-DB changes) |
| `--migrate` | Run DB migrations after restart |
| `--rollback` | Revert to previous git commit and restart |
| `--dry-run` | Show what would happen without making changes |

---

## Cron Jobs

| Schedule | Script | Purpose |
|----------|--------|---------|
| `0 3 * * *` | `bin/backup-db` | Daily DB backup |
| `*/5 * * * *` | `bin/healthcheck --quiet` | Health monitoring |

Installed at:
- `/etc/cron.d/infrasignal-backup`
- `/etc/cron.d/infrasignal-healthcheck`

Log rotation: `/etc/logrotate.d/infrasignal` — 14-day retention, daily rotation, gzip.

---

## External Services

| Service | Purpose | Config Location |
|---------|---------|----------------|
| **Cloudflare** | DNS, SSL (Full Strict), DDoS protection | Cloudflare dashboard |
| **Cloudflare Turnstile** | CAPTCHA on all public forms | `conf/general.yml` (TURNSTILE_*) |
| **SendGrid** | Transactional email (SMTP over STARTTLS) | `conf/general.yml` (SMTP_*) |
| **SightEngine** | Image content moderation | `conf/general.yml` (SIGHTENGINE_*) |
| **OpenAI** | Text content moderation | `conf/general.yml` (OPENAI_*) |
| **Google Cloud** | OAuth 2.0 OIDC sign-in | `conf/general.yml` (GOOGLE_OIDC_*) |
| **UptimeRobot** | External uptime monitoring | UptimeRobot dashboard |

---

## Security

- **Firewall:** UFW — deny all except ports 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **SSH:** Key-only auth, root password login disabled
- **Secrets:** All in `docker/.env` and `conf/general.yml` — both gitignored
- **CAPTCHA:** Cloudflare Turnstile on all public forms (server-side validation)
- **CSP:** Content Security Policy headers enabled
- **Nginx Headers:** X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy, Permissions-Policy
- **HTTPS:** Cloudflare Full (Strict) SSL with origin certificate
- **DB Passwords:** Strong random credentials, not defaults
- **Backup Permissions:** Backup directory `chmod 700`, backup files `chmod 600` — root-only access
- **DB Mount Isolation:** Production DB container mounts only `db/` directory (read-only), not the full source tree
- **Nginx Config Separation:** Dedicated `conf/nginx.conf-prod` for production, `conf/nginx.conf-dev` for development
