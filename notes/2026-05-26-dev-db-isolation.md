# Dev database isolation — 2026-05-26

## What changed

The development environment at `/opt/infrasignal-dev` no longer shares
the production database. It now has its own postgres and its own
memcached, running as new services in dev's compose project. All other
dev behaviour (port 3001, source mount, dev-fixmystreet container,
dev-nginx-proxy) is unchanged.

## Why this was urgent

Before today, dev's `conf/general.yml` had:

```yaml
FMS_DB_HOST: 'postgres.svc'
FMS_DB_USER: 'postgres'                                # ← superuser
FMS_DB_PASS: 'M6p52lFbhHQHHvZ4tVYRFOGnhUXbTBde6ftxTPMN' # ← prod's password
MEMCACHED_HOST: 'memcached.svc'
```

Both `postgres.svc` and `memcached.svc` resolved (and still resolve,
for prod containers) to `docker-db-1` / `docker-memcached-1`. So every
test the developer ran on `:3001`:

- read prod data,
- could write to **any** prod table as the postgres superuser,
- and could evict / corrupt prod's memcached entries.

It also meant a stray schema migration on dev would have been a prod
migration. This was the single biggest production-safety hole in the
whole stack.

## What was done (no deletions, all reversible)

### 1. Added two services to `/opt/infrasignal-dev/docker/docker-compose-local.yml`

`dev-db` — built from `postgres:13.11` with `en_GB.UTF-8` locale baked
in (matching the prod and staging postgres images). Tuned small for
the host (memory had been under pressure):

```yaml
command: >
  postgres
  -c shared_buffers=64MB
  -c max_connections=50
  -c work_mem=4MB
  -c maintenance_work_mem=32MB
```

Data lives in named volume `infrasignal-dev_dev-pgdata`. Alias on the
shared `docker_default` bridge: `dev-postgres.svc`. Password:
`dev_local_password_2026` (dev-only, only reachable on the docker
bridge).

`dev-memcached` — vanilla `memcached:1.6.32`, 64 MB limit, alias
`dev-memcached.svc`.

Both services join the existing `prod_net` alias (which is
`docker_default` external). No new networks were created; no existing
services were touched.

### 2. Bootstrapped the dev DB

```
docker compose -p infrasignal-dev up -d dev-db dev-memcached
docker exec infrasignal-dev-dev-db-1 psql -U postgres -c "CREATE DATABASE infrasignal;"
docker compose -p infrasignal-dev run --rm dev-fixmystreet bin/update-schema --commit
```

`update-schema` went from "Current database version = 0093" to applying
`0094-priority-zones` cleanly. After this dev-db has 37 tables and all
five `osm_zone_*` columns on `problem` — same as prod.

### 3. Backed up and edited `/opt/infrasignal-dev/conf/general.yml`

Backup at
`/opt/infrasignal-dev/conf/general.yml.pre-isolation-2026-05-26.bak`
(byte-for-byte copy taken before any edit).

Three changes:

| Key | Before | After |
| --- | --- | --- |
| `FMS_DB_HOST` | `postgres.svc` | `dev-postgres.svc` |
| `FMS_DB_PASS` | `M6p52lFbhHQHHvZ4tVYRFOGnhUXbTBde6ftxTPMN` (prod superuser) | `dev_local_password_2026` (dev-only) |
| `MEMCACHED_HOST` | `memcached.svc` | `dev-memcached.svc` |

`FMS_DB_USER` left as `postgres` (matches the pattern dev was already
using; the user only exists inside dev's own container, not prod's).
All other settings — including SightEngine, OpenAI, Google OIDC,
Turnstile, etc — were not touched.

### 4. Restarted `infrasignal-dev-dev-fixmystreet-1`

The container reads `conf/general.yml` at boot, so restarting it was
needed to pick up the new DB pointer. The dev-setup, dev-css-watcher,
dev-nginx services in the dev compose file were not touched.

## Verification

| Check | Result |
| --- | --- |
| `curl http://127.0.0.1:3001/` | `HTTP 200`, 59 KB body |
| `SELECT count(*) FROM problem` in dev-db | `0` (clean start) |
| `SELECT count(*) FROM problem` in prod-db | `723` (unchanged from baseline) |
| `pg_stat_activity` in dev-db | one connection from `172.18.0.2` (dev-fixmystreet) |
| `pg_stat_activity` in prod-db filtered to `172.18.0.2` | zero rows — dev does not touch prod any more |

## What did **not** change

- Production stack (`docker` compose project) — untouched.
- Staging stack (`staging` compose project) — untouched.
- Legacy stack (`infrasignal-v2` compose project) — still stopped.
- The prod-side databases, volumes, and aliases — all intact.
- Dev's source tree and the dev-fixmystreet image — only restarted,
  not rebuilt.
- The `dev-nginx-proxy` container that fronts dev on port 3001 — still
  running, still proxies to `dev-fixmystreet.svc`. The DNS alias is
  unchanged.

## How to roll back (if ever needed)

```
# Stop new services (data preserved in dev-pgdata volume)
cd /opt/infrasignal-dev
sudo docker compose -p infrasignal-dev -f docker/docker-compose-local.yml stop dev-db dev-memcached

# Restore the pre-isolation config
sudo cp conf/general.yml.pre-isolation-2026-05-26.bak conf/general.yml

# Restart the app
sudo docker restart infrasignal-dev-dev-fixmystreet-1
```

After this, dev would once again share the prod DB. **Don't do this.**

## What's next (NOT done in this session — explicitly out of scope)

A PII-scrubbed copy script (`bin/refresh-db`) to seed dev / staging
DBs from prod was discussed but not built. When it lands, the flow
will be:

1. Prod takes a backup (already automated, `bin/backup-db` at 03:00 UTC).
2. `bin/refresh-db --source prod --target dev` restores it into
   `dev-postgres.svc` with PII scrubbed.
3. `bin/refresh-db --source prod --target staging` does the same for
   staging.

Photos (`web/photo/`) are still shared because all three stacks mount
the same source tree. Decide later whether to split them too.
