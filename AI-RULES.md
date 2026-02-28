# InfraSignal — AI Assistant Rules

**Last Updated:** 2026-02-28  
**Applies To:** All AI assistants (GitHub Copilot, ChatGPT, Claude, or any other AI tool used to work on this codebase)

---

## Purpose

This document defines strict rules that any AI assistant MUST follow when working on the InfraSignal project. These rules exist to prevent production incidents, data loss, and architectural confusion that have occurred in past sessions.

**If you are an AI assistant reading this file, you MUST follow every rule below. No exceptions.**

---

## Rule 1: Know the Environment Before Acting

Before making ANY change, you MUST establish:

1. **Which compose file is running production?** → `docker/docker-compose-prod.yml`
2. **Which branch is production?** → `main`
3. **What is the live URL?** → `https://infrasignal.org`
4. **Where is the server?** → `srv1303443.hstgr.cloud` at `/opt/infrasignal-v2`

**How to verify:**
```bash
docker compose -f docker/docker-compose-prod.yml ps    # Check running containers
git branch --show-current                                # Check current branch
curl -sI https://infrasignal.org | head -5              # Check site is reachable
```

> **NEVER assume the environment.** Always verify first. The wrong assumption (e.g., checking the wrong compose file) has led to confusion in past sessions.

---

## Rule 2: Production vs Development Separation

### Production
| Aspect | Value |
|--------|-------|
| Compose file | `docker/docker-compose-prod.yml` |
| Git branch | `main` |
| URL | https://infrasignal.org |
| Services | nginx, fixmystreet, db, memcached (4 total) |
| Deploy script | `bin/deploy` |

### Development
| Aspect | Value |
|--------|-------|
| Compose file | `docker/docker-compose-dev.yml` |
| Git branch | `dev` or `feature/*` |
| URL | http://localhost:3000 |
| Services | nginx, fixmystreet, db, memcached, mailhog, css_watcher, setup (7 total) |
| Deploy script | N/A (manual) |

### Strict Prohibitions

- **NEVER use `docker-compose-dev.yml` for production.** It includes MailHog (dev email catcher), CSS watcher, and has no resource limits. It was previously (incorrectly) used for production — this has been fixed and must not be reverted.
- **NEVER push directly to `main`.** All work goes through `dev` first, then merges to `main` only when tested and approved.
- **NEVER create or run test data on the production database.** The production DB was cleaned of all test data. Use a local dev environment for testing.
- **NEVER run `docker compose down` on production containers without a backup first.** Always run `bin/backup-db` before any destructive operation.

---

## Rule 3: File Identification

### Critical Files (Handle with Extreme Care)

| File | Purpose | Risk |
|------|---------|------|
| `docker/docker-compose-prod.yml` | Production container definitions | Breaking this takes the site down |
| `docker/.env` | All secrets (DB password, API keys, SMTP credentials) | Leaking this compromises everything |
| `conf/general.yml` | App configuration (API keys, Turnstile, SMTP) | Changing this can break auth, email, moderation |
| `bin/deploy` | Production deployment | Bad changes = failed deploys |
| `bin/backup-db` | Automated backup | Breaking this = no backups |
| `bin/healthcheck` | Health monitoring | Breaking this = silent failures |

### Files You MUST NOT Commit to Git

| File/Directory | Reason |
|----------------|--------|
| `docker/.env` | Contains secrets |
| `conf/general.yml` | Contains API keys |
| `PROJECT PLAN/` | Private business documents |
| `DATABASE_DIRECTORY.*` | Proprietary data |
| Any `.sql` seed files | Proprietary data |
| Census CSV/JSON files | Business data |
| Contact lists (JSON) | Business data |

These are already in `.gitignore`. Do not remove them from `.gitignore`.

---

## Rule 4: Change Process

### Before Any Code Change

1. **Read** the relevant source files to understand the current implementation
2. **Check** `ARCHITECTURE.md` for system context
3. **Verify** which branch you're on (`git branch --show-current`)
4. **Verify** what's running (`docker compose -f docker/docker-compose-prod.yml ps`)

### Making Changes

1. **Work on `dev` branch** — never on `main`
2. **Make small, targeted changes** — one logical change per commit
3. **Test before committing** — verify the change works
4. **Write clear commit messages** — describe what and why

### Deploying Changes

1. Merge `dev` → `main` (only when tested and approved)
2. Run `bin/deploy` — it handles backup, pull, rebuild, health check
3. Verify the site works after deploy

### If Something Goes Wrong

1. **Don't panic.** Backups exist.
2. Run `bin/deploy --rollback` to revert to the previous commit.
3. If containers are broken: `docker compose -f docker/docker-compose-prod.yml down && docker compose -f docker/docker-compose-prod.yml up -d`
4. Restore DB from backup if needed (see ARCHITECTURE.md for restore command).

---

## Rule 5: Docker Operations

### Correct Commands

```bash
# Check production status
docker compose -f docker/docker-compose-prod.yml ps

# View production logs
docker compose -f docker/docker-compose-prod.yml logs -f

# Restart production
docker compose -f docker/docker-compose-prod.yml restart

# Full rebuild (use bin/deploy instead when possible)
docker compose -f docker/docker-compose-prod.yml up -d --build

# Run a command in the app container
docker compose -f docker/docker-compose-prod.yml exec fixmystreet <command>

# Access the production database
docker compose -f docker/docker-compose-prod.yml exec db psql -U postgres infrasignal
```

### WRONG Commands (Do NOT Use for Production)

```bash
# WRONG — this is the dev compose file
docker compose -f docker/docker-compose-dev.yml up -d

# WRONG — this is the root compose file (if it exists), not the production one
docker compose up -d

# WRONG — "docker-compose" (hyphenated) is the old v1 syntax
docker-compose up -d
```

---

## Rule 6: Database Rules

- **Production DB has real users and real reports.** Do not INSERT test rows, do not DELETE without explicit approval.
- **Always back up before any DB migration or schema change.** Run `bin/backup-db` first.
- **Never run raw DDL (CREATE TABLE, ALTER TABLE, DROP) on production without a migration script.** Use `bin/update-schema` for schema changes.
- **Current production users:** Only `nazarmenov@gmail.com` (regular user) and `admin@infrasignal.org` (superuser). Do not create additional users without approval.

---

## Rule 7: Configuration Changes

### `conf/general.yml`

- This file is the main application configuration
- It contains Turnstile keys, SMTP credentials, API keys
- **Never swap production keys for test keys** unless you swap them back immediately
- **Never commit this file to git** — it is gitignored
- A past incident involved temporarily swapping Turnstile keys for testing and forgetting to restore them — always restore immediately

### `docker/.env`

- Contains database credentials and other Docker-level secrets
- **Never commit this file to git**
- **Never print its contents in logs or terminal output**
- Changes require container restart to take effect

---

## Rule 8: Documentation Requirements

After completing any significant work, you MUST update:

1. **CHANGELOG.md** — Add version entry describing what changed
2. **ARCHITECTURE.md** — If any architectural change was made (new services, changed topology, new scripts)
3. **This file (AI-RULES.md)** — If new rules are needed based on lessons learned
4. **PROJECT PLAN/PROJECT_PLAN.md** — Update phase status if applicable

### Documentation MUST be factual

- Do not write aspirational documentation ("we plan to...")
- Document what IS, not what might be
- Include dates, versions, and specific details
- If a task was skipped, say it was skipped and why

---

## Rule 9: Secret Handling

- **Never print secrets to the terminal** unless absolutely required for debugging
- **Never include secrets in commit messages or documentation**
- **Never hardcode secrets in source files** — use `conf/general.yml` or `docker/.env`
- **If a secret is accidentally exposed**, it must be rotated immediately on the relevant platform

---

## Rule 10: Communication with the User

- **Do not assume** — if something is unclear, ask
- **Verify before acting** — especially for destructive operations (delete, drop, deploy)
- **Report clearly** — state what you did, what the result was, and what comes next
- **If you make a mistake, say so immediately** — don't try to hide it or work around it silently

---

## Quick Reference Card

```
PRODUCTION COMPOSE:  docker/docker-compose-prod.yml
PRODUCTION BRANCH:   main
PRODUCTION URL:      https://infrasignal.org
SERVER:              srv1303443.hstgr.cloud
PROJECT ROOT:        /opt/infrasignal-v2
BACKUPS:             /opt/backups/infrasignal/
DEPLOY:              bin/deploy
BACKUP:              bin/backup-db
HEALTH CHECK:        bin/healthcheck
SECRETS:             docker/.env + conf/general.yml
MONITORING:          bin/healthcheck (cron 5min) + UptimeRobot (external)
```

---

## Lessons Learned (Past Incidents)

These incidents happened in real sessions and are documented to prevent recurrence:

### Incident 1: Wrong Compose File Check
**What happened:** AI checked `docker-compose.yml` (root) for running containers and concluded "nothing is running" — when in fact all 6 containers were running via `docker/docker-compose-dev.yml`.  
**Root cause:** Assumed default compose location instead of verifying.  
**Rule created:** Rule 1 — always verify the environment before acting.

### Incident 2: Dev Compose Serving Production
**What happened:** `docker/docker-compose-dev.yml` was serving production traffic for months, including MailHog (dev email catcher) and CSS watcher — wasting resources and creating confusion.  
**Root cause:** No dedicated production compose file existed.  
**Rule created:** Rule 2 — strict production/development separation.

### Incident 3: Turnstile Test Keys Left in Production
**What happened:** During a debugging session, production Turnstile CAPTCHA keys were temporarily swapped with Cloudflare "always pass" test keys. If not restored, this would disable CAPTCHA protection on all forms.  
**Root cause:** Needed to test login flow via curl; real Turnstile blocks non-browser requests.  
**Rule created:** Rule 7 — never swap production keys without immediate restoration.

### Incident 4: Login Failure After User Creation
**What happened:** A new superuser was created via raw SQL INSERT, but login failed because `email_verified` was set to `false`. FixMyStreet requires `email_verified = true` for password-based login.  
**Root cause:** Used raw SQL instead of the platform's user creation mechanism.  
**Rule created:** Rule 6 — understand the platform's requirements before making DB changes.
