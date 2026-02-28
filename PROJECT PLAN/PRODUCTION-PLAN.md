# InfraSignal — Production Professionalization Plan

**Created:** 2026-02-28  
**Status:** In Progress  
**Server:** `/opt/infrasignal-v2` on `srv1303443` (2 CPU, 8 GB RAM, 96 GB disk)  
**Live URL:** https://infrasignal.org / https://www.infrasignal.org  
**Branch:** `Version-2.2` → migrating to `main`

---

## Current State (Problems Identified)

| # | Issue | Detail |
|---|---|---|
| 1 | **No environment separation** | Single server, single DB. The dev compose file (`docker-compose-dev.yml`) is serving production traffic. |
| 2 | **Test data in production DB** | 59 reports — many are junk ("Coffee pot", "Vvvv", "Dgfbfdfg", "TEST LATESt 1", "Sex", "Fuck"). |
| 3 | **Compose file misnamed** | `docker-compose-dev.yml` serves production; no dedicated prod compose file exists. |
| 4 | **Deploy script outdated** | `bin/deploy` references branch `Version-2.1`; actual branch is `Version-2.2`. |
| 5 | **MailHog in production** | Dev email catcher running alongside real SendGrid SMTP — confusing and unnecessary. |
| 6 | **No automated backups** | No DB backup strategy; a bad deploy could lose all data. |
| 7 | **No monitoring** | No health checks, uptime monitoring, or alerting. |
| 8 | **Messy git branches** | 15+ version branches (`Version-1` through `Version-2.2`); no standard branching workflow. |
| 9 | **Secrets need rotation** | Credentials were exposed during debugging session and should be rotated. |

---

## Phase 1: Backup Everything ⚡ FIRST PRIORITY

> Before touching anything, protect what exists.

### Steps

1. **Dump the production database:**
   ```bash
   cd /opt/infrasignal-v2
   mkdir -p /opt/backups/infrasignal
   docker compose -f docker/docker-compose-dev.yml exec db \
     pg_dump -U postgres infrasignal > /opt/backups/infrasignal/backup_20260228_pre-cleanup.sql
   ```

2. **Back up the `.env` file:**
   ```bash
   cp docker/.env /opt/backups/infrasignal/env_backup_20260228
   ```

3. **Tag the current state in git:**
   ```bash
   git tag v2.2-pre-cleanup
   git push origin v2.2-pre-cleanup
   ```

### Verification
- [ ] Backup SQL file exists and is non-empty
- [ ] `.env` backup exists
- [ ] Git tag pushed

---

## Phase 2: Clean Production Data

> Remove test/junk records so the live site only shows real data.

### Test Data Identified

| IDs | Titles | Reason |
|---|---|---|
| 1, 2 | Coffee pot | Fake |
| 3 | Pot hole / "Flowers" | Nonsense detail |
| 4 | Tree test | Dev testing |
| 5 | Test | Named "Test" |
| 7 | Test 1 | Named "Test 1" |
| 8, 9 | Test County Before City | Dev testing |
| 10 | Vvvv / Bbbbb | Keyboard mash |
| 12 | TEST LATESt 1 | Named "TEST" |
| 15 | Cvc | Keyboard mash |
| 16 | Wewefewfcwe | Keyboard mash |
| 17 | Ergre | Keyboard mash |
| 20 | Auto-priority test | Dev testing |
| 22 | Rythf | Keyboard mash |
| 23 | Mmm | Keyboard mash |
| 24 | Dgfbfdfg | Keyboard mash |
| 25 | Kj6m | Keyboard mash |
| 35, 36, 37 | Sex, Fuck, Sex | Content filter testing |
| 54 | Test | Named "Test" |

### Steps

1. **Delete comments associated with junk reports:**
   ```sql
   DELETE FROM comment WHERE problem_id IN (1,2,3,4,5,7,8,9,10,12,15,16,17,20,22,23,24,25,35,36,37,54);
   ```

2. **Delete the junk reports:**
   ```sql
   DELETE FROM problem WHERE id IN (1,2,3,4,5,7,8,9,10,12,15,16,17,20,22,23,24,25,35,36,37,54);
   ```

3. **Delete test user account (admin@infrasignal.local):**
   - Keep: mansuychik@gmail.com, buythewayai@gmail.com, nazarmenov@gmail.com, truckmansur@gmail.com, astrocodeyforce@gmail.com
   - Review: admin@infrasignal.local (ID 1) — may be needed for admin access; keep but update email

4. **Verify site still works after cleanup.**

### Verification
- [ ] Junk reports removed
- [ ] Site loads without errors
- [ ] Remaining reports are legitimate

---

## Phase 3: Create Production Compose File

> Separate dev and production configurations.

### New file: `docker/docker-compose-prod.yml`

**Differences from dev:**

| Feature | Dev | Prod |
|---|---|---|
| MailHog | ✅ Included | ❌ Removed |
| CSS Watcher | ✅ Included | ❌ Removed (CSS pre-built at deploy) |
| Setup service | ✅ Runs every start | ❌ Removed (run manually on first deploy) |
| Source mounts | ✅ Full source tree | ❌ Minimal (only custom overlays) |
| Restart policy | Basic | `restart: always` + health checks |
| Resource limits | None | CPU/memory limits set |
| Ports | 80, 443 | 80, 443 (same) |

### Steps

1. Create `docker/docker-compose-prod.yml` with only essential services:
   - nginx
   - fixmystreet
   - db
   - memcached

2. Add health checks:
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:9000"]
     interval: 30s
     timeout: 10s
     retries: 3
   ```

3. Add resource limits:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 2G
   ```

4. Remove MailHog, CSS watcher, and setup service.

5. Test by switching to the new compose file.

### Verification
- [ ] `docker-compose-prod.yml` exists
- [ ] All 4 essential services start and are healthy
- [ ] Site loads on https://infrasignal.org
- [ ] No MailHog or CSS watcher running

---

## Phase 4: Fix Deploy Script

> Update `bin/deploy` for reliable production deployments.

### Changes

1. **Update compose file reference:**
   ```bash
   COMPOSE_FILE="docker/docker-compose-prod.yml"
   ```

2. **Update branch reference:**
   ```bash
   BRANCH="main"
   ```

3. **Add pre-deploy backup** (automatic `pg_dump` before every deploy)

4. **Add post-deploy health check** (curl the site, verify 200 OK)

5. **Add rollback command** (`./bin/deploy --rollback`)

6. **Add dry-run mode** (`./bin/deploy --dry-run`)

### Verification
- [ ] `./bin/deploy --dry-run` works without making changes
- [ ] `./bin/deploy` completes successfully
- [ ] Post-deploy health check passes

---

## Phase 5: Git Branching Strategy

> Stop using version branches. Use a standard flow.

### New Strategy

```
main              ← always deployable, production code
  └── dev         ← active development happens here
       └── feature/xyz  ← individual features, merge into dev
```

| Branch | Rule |
|---|---|
| `main` | Protected. Only receives merges from `dev`. Deploy pulls from here. |
| `dev` | Day-to-day work and testing. |
| `feature/*` | Short-lived. One per feature/fix. Merge into `dev`, then delete. |

### Steps

1. **Merge `Version-2.2` into `main`:**
   ```bash
   git checkout main
   git merge Version-2.2
   git push origin main
   ```

2. **Ensure `dev` is up to date:**
   ```bash
   git checkout dev
   git merge main
   git push origin dev
   ```

3. **Archive old version branches as tags:**
   ```bash
   for branch in Version-1 Version-1.3 Version-1.4-SC Version-1.5-SCct \
     Version-1.6 Version-1.7 Version-1.8 Version-1.9 Version-2.0 \
     Version-2.1 Version-2.2; do
     git tag "archive/$branch" "$branch"
   done
   git push origin --tags
   ```

4. **Delete old version branches** (local + remote) after confirming tags are pushed.

### Verification
- [ ] `main` has all `Version-2.2` code
- [ ] `dev` is synced with `main`
- [ ] All old versions preserved as `archive/*` tags
- [ ] Old version branches deleted

---

## Phase 6: Automated Backups

> Never lose data.

### Create `bin/backup-db`

```bash
#!/usr/bin/env bash
set -euo pipefail
BACKUP_DIR="/opt/backups/infrasignal"
COMPOSE_FILE="/opt/infrasignal-v2/docker/docker-compose-prod.yml"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=30

mkdir -p "$BACKUP_DIR"

docker compose -f "$COMPOSE_FILE" exec -T db \
  pg_dump -U postgres infrasignal | gzip > "$BACKUP_DIR/infrasignal_${TIMESTAMP}.sql.gz"

# Prune old backups
find "$BACKUP_DIR" -name "infrasignal_*.sql.gz" -mtime +${KEEP_DAYS} -delete

echo "[$(date)] Backup complete: infrasignal_${TIMESTAMP}.sql.gz"
```

### Cron Job

```
# /etc/cron.d/infrasignal-backup
0 3 * * * root /opt/infrasignal-v2/bin/backup-db >> /var/log/infrasignal-backup.log 2>&1
```

### Verification
- [ ] `bin/backup-db` runs successfully
- [ ] Compressed backup file created in `/opt/backups/infrasignal/`
- [ ] Cron job installed

---

## Phase 7: Rotate Secrets

> Credentials were exposed; rotate everything.

### Secrets to Rotate

| Secret | Where to rotate | Update in |
|---|---|---|
| `POSTGRES_PASSWORD` | PostgreSQL (ALTER USER) | `docker/.env` |
| `SUPERUSER_PASSWORD` | App DB | `docker/.env` |
| `SMTP_PASSWORD` (SendGrid) | https://app.sendgrid.com | `docker/.env` |
| `OPENAI_API_KEY` | https://platform.openai.com | `docker/.env` |
| `SIGHTENGINE_API_SECRET` | https://dashboard.sightengine.com | `docker/.env` |
| `GOOGLE_OIDC_SECRET` | https://console.cloud.google.com | `docker/.env` |
| `TURNSTILE_SECRET_KEY` | https://dash.cloudflare.com | `docker/.env` |

### Steps

1. Generate new credentials on each platform
2. Update `docker/.env` with new values
3. Restart containers: `docker compose -f docker/docker-compose-prod.yml down && up -d`
4. Verify site still works
5. Verify email sending still works

### Verification
- [ ] All secrets rotated
- [ ] Containers restart without errors
- [ ] Site loads, login works, email works

---

## Phase 8: Basic Monitoring

> Know when the site goes down before users tell you.

### Steps

1. **Sign up for UptimeRobot** (free tier):
   - Monitor: `https://infrasignal.org` — HTTP(S), 5-min interval
   - Alert: Email notification on downtime

2. **Add `/healthz` endpoint** to the app that checks:
   - DB connectivity
   - Memcached connectivity
   - Returns `200 OK` with JSON status

3. **Add Docker health checks** in `docker-compose-prod.yml` for all services

4. **Set up log rotation:**
   ```bash
   # /etc/logrotate.d/infrasignal
   /var/log/infrasignal*.log {
       daily
       missingok
       rotate 14
       compress
       notifempty
   }
   ```

### Verification
- [ ] UptimeRobot monitoring active
- [ ] `/healthz` returns 200 OK
- [ ] Docker health checks configured
- [ ] Log rotation configured

---

## Execution Order & Timeline

| Priority | Phase | Effort | Day |
|---|---|---|---|
| 🔴 CRITICAL | Phase 1: Backup | 10 min | Day 1 |
| 🔴 CRITICAL | Phase 7: Rotate secrets | 30 min | Day 1 (manual — external dashboards) |
| 🟠 HIGH | Phase 2: Clean data | 30 min | Day 1 |
| 🟠 HIGH | Phase 3: Prod compose file | 1-2 hrs | Day 1 |
| 🟡 MEDIUM | Phase 4: Fix deploy script | 1 hr | Day 2 |
| 🟡 MEDIUM | Phase 5: Git branching | 30 min | Day 2 |
| 🟢 NORMAL | Phase 6: Automated backups | 1 hr | Day 3 |
| 🟢 NORMAL | Phase 8: Monitoring | 30 min | Day 3 |

---

## Notes

- **Compose file in use:** `docker/docker-compose-dev.yml` (will change to `docker-compose-prod.yml`)
- **Server specs:** 2 vCPU, 8 GB RAM, 96 GB disk (x86_64)
- **6 containers currently running:** nginx, fixmystreet, db, memcached, css_watcher, mailhog
- **6 users in DB** — all appear to be dev/team accounts
- **Secret rotation (Phase 7)** requires manual action on external dashboards — cannot be automated here
