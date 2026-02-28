# InfraSignal Platform

**Version:** 2.3  
**Live:** https://infrasignal.org  
**Branch:** `main` (production) / `dev` (development)

InfraSignal is a civic infrastructure reporting platform built on the
[FixMyStreet Platform](https://fixmystreet.org/) (AGPL v3). It enables
residents to report common infrastructure problems — potholes, broken
streetlights, drainage issues, and more — to the appropriate local authority.

Reports are routed using a 3-tier priority system (city → county → state) and
include built-in content moderation powered by
[SightEngine](https://sightengine.com) and [OpenAI](https://openai.com).

## Key Features

- **Infrastructure Reporting** — 13 built-in categories (Pothole/Road Damage,
  Streetlight Outage, Drainage/Flooding, etc.) with smart auto-fill defaults.
- **3-Tier Priority Routing** — Reports are automatically sent to the most
  local authority that handles the issue (city first, then county, then state).
- **OSM Priority Zones** — Automatic classification by proximity to hospitals,
  schools, fire stations, and 27 other OpenStreetMap feature types.
- **Image Moderation** — Uploaded photos are automatically screened for nudity,
  weapons, violence, gore, drugs, offensive content, AI-generated images, and
  more via the SightEngine API.
- **Text Moderation** — Report titles and descriptions are checked for
  profanity, URLs/links, personal information (emails/phone numbers), and
  classified via ML models for sexual, discriminatory, insulting, violent, or
  toxic content.
- **Category Auto-Fill** — Selecting a report category auto-populates the
  title and description with sensible defaults that users can customise.
- **US Coverage** — Pre-loaded with US states, counties, and cities from
  Census 2020 data.
- **Multi-Language Support** — Cookie-based language switching with full
  translation across UI strings (gettext), database content (categories,
  states), and static pages. Currently available: English, Turkish (Türkçe),
  Spanish (Español), Russian (Русский).
- **Duplicate Detection** — Geographic duplicate suggestion (500m public,
  1500m inspectors) with admin management page at `/admin/duplicate_reports`.
- **Server Scaling** — Tuned for 200–500 concurrent users: 10 Starman
  workers with preload-app, nginx rate/connection limiting, PostgreSQL
  memory optimization, and memcached tuning.
- **Automated Backups** — Daily DB backups with 30-day retention.
- **Health Monitoring** — 9-point health check (cron) + UptimeRobot (external).

## Quick Start

### Production Deployment

```bash
cd /opt/infrasignal-v2
bin/deploy              # Pull latest main, rebuild, health check
bin/deploy --dry-run    # Preview without making changes
bin/deploy --rollback   # Revert to previous commit
```

### Development Setup

```bash
cd docker
docker compose -f docker-compose-dev.yml up -d
```

The dev environment will be available at `http://localhost:3000` with additional
services (MailHog email catcher, CSS watcher, setup container).

> **Important:** Never use `docker-compose-dev.yml` for production.
> See [AI-RULES.md](AI-RULES.md) for the full set of operational rules.

### Configuration

Copy the example config and fill in your settings:

```bash
cp conf/general.yml-example conf/general.yml
```

**Required settings:**
- `FMS_DB_*` — PostgreSQL database connection
- `BASE_URL` — Your public URL
- `MAPIT_URL` — MapIt instance for geographic lookups
- `ALLOWED_COBRANDS` — Set to `infrasignal`

**Content moderation (SightEngine):**
- `SIGHTENGINE_ENABLED: 1`
- `SIGHTENGINE_API_USER` / `SIGHTENGINE_API_SECRET`

> **Security:** Never commit API keys or secrets to version control.
> Keep credentials in `conf/general.yml` (gitignored) or `docker/.env` only.

## Architecture

| Component | Technology |
|-----------|-----------|
| Backend | Perl / Catalyst / Starman (10 workers) |
| Database | PostgreSQL 13.11 + PostGIS |
| Reverse Proxy | Nginx 1.27.2 |
| Templates | Template Toolkit |
| Frontend | jQuery, OpenLayers (maps) |
| Image Moderation | SightEngine API |
| Text Moderation | OpenAI API |
| Caching | Memcached 1.6.32 (128 MB, 1024 connections) |
| Containerisation | Docker Compose (separate dev + prod configs) |
| SSL/CDN | Cloudflare Full (Strict) |
| CAPTCHA | Cloudflare Turnstile |
| Email | SendGrid SMTP (STARTTLS) |
| Auth | Google OIDC + email/password |

For detailed architecture, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Key Scripts

| Script | Purpose |
|--------|---------|
| `bin/deploy` | Production deployment (backup → pull → rebuild → health check) |
| `bin/backup-db` | Manual/automated DB backup (gzip, 30-day retention) |
| `bin/healthcheck` | 9-point health check (HTTPS, containers, DB, disk, memory, backups) |
| `bin/send-reports` | Send pending reports to authorities |
| `bin/send-alerts` | Send email alerts to subscribers |
| `bin/classify-reports` | OSM priority zone classification |

## Git Branching

```
main              ← Production (always deployable, bin/deploy pulls this)
  └── dev         ← Development (all new work starts here)
       └── feature/xyz  ← Feature branches (merge into dev, then delete)
```

**Never push directly to `main`.** All work goes through `dev` → test → merge to `main`.

## Documentation

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Full system architecture, topology, and operations guide |
| [AI-RULES.md](AI-RULES.md) | Mandatory rules for AI assistants working on this codebase |
| [CHANGELOG.md](CHANGELOG.md) | Version history and release notes |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |

## Upstream

Based on [FixMyStreet Platform](https://github.com/mysociety/fixmystreet)
v6.0 by [mySociety](https://www.mysociety.org/). See CHANGELOG.md for the
full version history.

## License

GNU Affero General Public License v3 — see [LICENSE.txt](LICENSE.txt).
