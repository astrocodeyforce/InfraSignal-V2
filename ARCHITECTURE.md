# InfraSignal — Architecture Guide

**Last Updated:** 2026-02-28  
**Version:** 2.3  
**Live URL:** https://infrasignal.org  
**Server:** `srv1303443.hstgr.cloud` — 2 vCPU, 8 GB RAM, 96 GB disk (x86_64)

---

## System Overview

InfraSignal is a civic infrastructure reporting platform built on [FixMyStreet Platform](https://fixmystreet.org/) v6.0 (AGPL v3). It runs as a set of Docker containers on a single Linux server, fronted by Cloudflare for DNS, SSL termination, and DDoS protection.

```
Internet → Cloudflare (DNS + SSL) → Server (srv1303443.hstgr.cloud)
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

> **CRITICAL:** The dev compose file must NEVER serve production traffic. See [AI-RULES.md](AI-RULES.md).

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
| `origin` | `InfraSignal-V2.git` (GitHub) | Public repo (AGPL code only) |
| `private` | `infrasignal-v3.git` | Private repo (same code, backup) |

### Archived Branches

All old version branches (`Version-1` through `Version-2.2`) have been archived as tags (`archive/Version-*`) and deleted as branches.

---

## Environment Separation

### Production Environment

| Aspect | Value |
|--------|-------|
| **Server** | `srv1303443.hstgr.cloud` |
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
- Location: `/opt/backups/infrasignal/`
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
