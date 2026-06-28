# Production hardening, no-deletion pass — 2026-05-26

## Scope and ground rules

User asked for production hardening focused on critical / reliability
items, with two hard constraints:

1. **No deletion.** Whatever existed had to stay; only stop, comment out,
   or add new alternatives.
2. **No changes to the dev environment** (this was later lifted on
   2026-05-26 for the dev DB isolation work — see
   `2026-05-26-dev-db-isolation.md`).

Everything below is reversible. Each item lists what existed before,
why action was needed, what action was taken, how to verify it, and
how to undo it.

---

## Pre-change baseline

| Aspect | State at session start |
| --- | --- |
| Live URL | `https://infrasignal.org` (HTTP 200) |
| Prod compose project | `docker` (deployed by `/opt/infrasignal-v2/bin/deploy`) |
| Prod source mount | bind mount `/opt/infrasignal-v2 → /var/www/fixmystreet` |
| Branch deployed | `dev` (not `main` — branch policy doc was out of date) |
| Legacy `infrasignal-v2` compose | containers in `Restarting (127)` loop, no working `bin/cron-wrapper` |
| nginx config | `listen 80/443 default_server;` with no `server_name` filter — would serve InfraSignal content for any hostname pointing at the box |
| Staging | not running |
| `bin/deploy` | hardcoded `BRANCH="main"`, no clean-tree guard, would silently deploy `main` over the actually-deployed `dev` |
| Prod commit | `39b493ae` (May 3 — last commit on dev branch) |

---

## Changes by item

### 1. Legacy `infrasignal-v2` compose project — stopped

**Why it existed:** original FixMyStreet bring-up before the prod stack
was refactored to compose project `docker`. Containers had been left
running with `restart: always`.

**Why action was needed:** the legacy fixmystreet container was in a
`Restarting (127)` loop — its image referenced `bin/cron-wrapper` which
does not exist in the repo. The DB inside `infrasignal-v2-postgres-1`
was empty (verified), so no data risk. But the restart loop was burning
CPU and producing log noise every few seconds.

**Action taken:**
```
sudo docker compose -p infrasignal-v2 stop
sudo docker update --restart=no \
    infrasignal-v2-fixmystreet-1 \
    infrasignal-v2-nginx-1 \
    infrasignal-v2-postgres-1 \
    infrasignal-v2-memcached-1
```

**Verification:** `docker ps` no longer lists any `infrasignal-v2-*`
containers. Volume `infrasignal-v2_postgres-data` and network
`infrasignal-v2_default` are preserved (`docker volume ls`,
`docker network ls`).

**Reversal:**
```
sudo docker update --restart=always infrasignal-v2-*
sudo docker start infrasignal-v2-postgres-1 infrasignal-v2-memcached-1 \
    infrasignal-v2-fixmystreet-1 infrasignal-v2-nginx-1
```

---

### 2. `conf/nginx.conf-prod` — locked to `infrasignal.org`

**Why it existed:** generic nginx config that accepted any Host header.

**Why action was needed:** the box's bare IP (`REDACTED-IP`) and any
stray DNS alias that ever pointed here would serve full InfraSignal
content. This is bad for SEO (duplicate hosts), bad for security (no
hostname allowlist), and would make any future probing trivial.

**Action taken:** added explicit `server_name infrasignal.org
www.infrasignal.org;` to the main server block, plus a catch-all
`server_name _;` block at the bottom that completes TLS and returns
444 (close connection, no response).

**Verification:**
- `curl -k https://infrasignal.org/` → 200 ✓
- `curl -k --resolve any-host:443:127.0.0.1 https://any-host/` → connection closed ✓

**Reversal:** delete the second `server` block (lines starting at
`# Catch-all for any hostname other than infrasignal.org`) and remove
the `server_name infrasignal.org www.infrasignal.org;` line.

---

### 2b. nginx healthcheck regression introduced by item 2 — fixed

The new `server_name _;` catch-all returned 444 for `curl
http://localhost/` (the original prod healthcheck command), so the
nginx container went unhealthy after the config reload.

**Fix:** updated the nginx healthcheck in
`docker/docker-compose-prod.yml`:
```
test: ["CMD-SHELL", "curl -sf -H 'Host: infrasignal.org' http://localhost/ || exit 1"]
```
Recreated only the nginx container so the new healthcheck took effect
without restarting the app. Same fix added to
`docker/docker-compose-prod-image.yml` (the future image-based variant)
so the regression doesn't reappear there.

---

### 3. `bin/deploy` — branch mismatch + dirty-tree guard

**Why it existed:** original deploy script assumed `main` was the
production branch.

**Why action was needed:** the actually-deployed branch is `dev`. If
anyone had run `./bin/deploy --full` it would have done `git checkout
main; git pull origin main` and clobbered ~113 commits of unreleased
work. Also nothing checked for a dirty working tree, so a
half-finished local edit could have been deployed.

**Action taken:**

```
BRANCH="${DEPLOY_BRANCH:-dev}"   # was: BRANCH="main"
```

Added a `require_clean_tree()` function that aborts with a list of
dirty files if `git status --porcelain` is non-empty. Wired into both
`--full` and `--migrate` cases (NOT `--quick` or `--rollback`, those
are valid even with a dirty tree).

**Verification:**
- `DEPLOY_BRANCH=main ./bin/deploy --dry-run` reports it would deploy `main`.
- Default `./bin/deploy --dry-run` reports it would deploy `dev`.
- With uncommitted files, `./bin/deploy --full` aborts.

**Reversal:** change `BRANCH` back to `"main"` and remove
`require_clean_tree` calls.

---

### 4. Production state pinned with a rollback tag

**Why action was needed:** before changing anything, capture the exact
deployed commit so we can `git checkout` back if needed.

**Action taken:** `git tag prod-2026-05-03 39b493aedab0` then noted it
in `ARCHITECTURE.md` under "Current Production State."

**Reversal:** `git tag -d prod-2026-05-03` (but don't — it's a free
safety net).

---

### 5. `docker-compose-prod-image.yml` — draft, not enabled

**Why action was needed:** to move prod off the live bind mount to
versioned images (CI is already pushing `ghcr.io/astrocodeyforce/
infrasignal-v2:dev` on every dev push). Bind mount = deploys are "git
pull on the box," which is hard to roll back and easy to break.

**Action taken:** added a parallel compose file
`docker/docker-compose-prod-image.yml`. It is **not** invoked anywhere
yet. Existing `docker-compose-prod.yml` stays the active prod
definition until staging has run on an image tag for >= 24h.

**Reversal:** `rm docker/docker-compose-prod-image.yml`. No runtime
effect.

---

### 6. CI image flow documented (no CI changes)

CI (GitHub Actions) already tags images with the branch name and the
short SHA on every push. Documented the manual deploy procedure in
`ARCHITECTURE.md` so we know exactly what to run when we cut over.

---

### 7. Staging environment brought up

**Why action was needed:** there was no staging. Every change went
straight from dev to prod (and dev was sharing prod's DB, see the
dev-isolation note).

**Action taken:** stood up a `staging` compose project on
`127.0.0.1:8080`:

- New compose file `docker/docker-compose-staging.yml` (4 services:
  nginx, fixmystreet, db, memcached on isolated `staging_default`
  network).
- Mounts the same `/opt/infrasignal-v2` source tree (so code reaches
  staging the same way it reaches prod), but overrides
  `conf/general.yml` with a generated runtime file:
  `../conf/general.yml-staging.runtime:/var/www/fixmystreet/conf/general.yml:ro`.
- New `bin/staging-deploy` script handles bring-up, init-db, regen,
  status, down.
- Added `conf/general.yml-staging.runtime` to `.gitignore` (it contains
  the real `POSTGRES_PASSWORD` substituted in from `docker/.env`).
- Bootstrapped the staging DB: created `fms` role + `infrasignal`
  database manually, then `bin/update-schema --commit`, then applied
  `db/schema_0094-priority-zones.sql` by hand (update-schema only
  loaded the base v0093).

**Known follow-up:** `schema_0094` (osm_zone_* columns) was not picked
up by `bin/update-schema --commit` on a fresh staging DB. Manual
re-apply worked. Future staging bootstraps should run a numbered-SQL
sweep above the base version.

**Verification:** staging serves HTTP 200 on `127.0.0.1:8080`. No
public hostname yet — access via SSH tunnel (`ssh -L 8080:127.0.0.1:8080
<server>`).

**Reversal:** `sudo bin/staging-deploy --down`. Volumes preserved.

---

## Final state snapshot (end of session)

```
prod    : https://infrasignal.org      HTTP 200  (4 containers, project docker, branch dev)
staging : http://127.0.0.1:8080        HTTP 200  (4 containers, project staging)
dev     : http://REDACTED-IP:3001     HTTP 200  (1 container, project infrasignal-dev — still sharing prod DB at this stage; isolated later same evening)
legacy  : (stopped, no restart)        4 containers preserved
```

---

## Reversibility cheat-sheet

| Change | Single command to undo |
| --- | --- |
| Legacy stack stop | `sudo docker start infrasignal-v2-{postgres,memcached,fixmystreet,nginx}-1 && sudo docker update --restart=always infrasignal-v2-*` |
| nginx server_name | Edit `conf/nginx.conf-prod` and remove the second `server` block + the `server_name infrasignal.org www.infrasignal.org;` line |
| nginx healthcheck | Edit `docker/docker-compose-prod.yml` line ~33 back to `curl -sf http://localhost/` |
| deploy branch default | Edit `bin/deploy` line ~19 back to `BRANCH="main"` |
| Clean-tree guard | Edit `bin/deploy` and remove the `require_clean_tree` function and its two call sites |
| Rollback tag | `git tag -d prod-2026-05-03` |
| Image-based draft | `rm docker/docker-compose-prod-image.yml` |
| Staging | `sudo bin/staging-deploy --down` (volumes kept) |

---

## Things deliberately not done this session

- Image-based prod cutover (the draft compose file exists; flipping
  the live stack waits on staging burn-in).
- Public hostname + SSL cert for staging.
- Adding a `staging` server_name to the prod nginx (prod is locked to
  `infrasignal.org` only).
- Any cleanup of stale untracked files in the repo (no-deletion rule).
