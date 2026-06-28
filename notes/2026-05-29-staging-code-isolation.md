# Staging code isolation — own source tree — 2026-05-29

## Summary

Staging now runs from its **own** source tree
(`/opt/infrasignal-staging`), a mirror of the dev working tree, instead
of sharing prod's `/opt/infrasignal-v2`. This lets staging show the
latest dev UI (for customer demos) while production stays frozen on its
old code. Completes the isolation started with the separate staging DB:
staging now has its own **DB + own code**, fully decoupled from prod.

Prod was verified byte-for-byte unchanged throughout (same CSS hash,
same mount, same commit, 0 reports). Only the two staging containers
(`staging-fixmystreet-1`, `staging-nginx-1`) were recreated.

---

## The problem this solves

`docker inspect` showed staging and prod mounting the **same** host
directory:

```
staging-fixmystreet-1 : /opt/infrasignal-v2 -> /var/www/fixmystreet
docker-fixmystreet-1  : /opt/infrasignal-v2 -> /var/www/fixmystreet   (prod)
staging-nginx-1       : /opt/infrasignal-v2/web -> .../web (ro)       (static assets)
docker-nginx-1        : /opt/infrasignal-v2/web -> .../web (ro)       (prod assets)
```

So staging and prod ran the **same code** — they differed only by
database and the `general.yml-staging.runtime` config override. There
was no way to update staging's UI without also changing live prod.

The latest UI work lives on the **dev** tree (`/opt/infrasignal-dev`,
`origin/dev` @ `b87297993` + WIP). Prod/staging were ~113 commits
behind on the shared tree.

---

## What changed

### New host directory: `/opt/infrasignal-staging`

Created as a mirror of the dev working tree (option "b" — exact current
working tree including uncommitted WIP, so staging matches what's on
`:3001`):

```bash
sudo rsync -a --delete --exclude='.git/' --exclude='local/' \
    /opt/infrasignal-dev/ /opt/infrasignal-staging/
sudo cp /opt/infrasignal-v2/conf/general.yml-staging.runtime \
        /opt/infrasignal-staging/conf/general.yml-staging.runtime
```

- `.git/` excluded — staging doesn't need history to run; keeps it lean
  and avoids a slow 228 MB copy. **`/opt/infrasignal-staging` is a plain
  working tree, NOT a git repo.** Re-sync is by rsync (below), not git.
- `local/` excluded — Perl/carton deps come from the `staging-local`
  Docker volume (already populated; the recreated app started healthy
  with no carton reinstall needed).
- The staging runtime config (DB password, staging flags) was copied in
  from v2 since dev doesn't carry it (it's gitignored / v2-specific).

Tree size: ~173 MB. `base.css` hash in the new tree: `61d616c92162`
(matches dev exactly).

### `docker/docker-compose-staging.yml` (in `/opt/infrasignal-v2`)

Three bind mounts repointed from the shared `../` (= `/opt/infrasignal-v2`)
to the isolated `/opt/infrasignal-staging`:

| Service     | Mount (target)                       | Before (`../`)            | After                                   |
|-------------|--------------------------------------|---------------------------|-----------------------------------------|
| fixmystreet | `/var/www/fixmystreet`               | `/opt/infrasignal-v2`     | `/opt/infrasignal-staging`              |
| fixmystreet | `/var/www/fixmystreet/conf/general.yml` | `.../v2/conf/...runtime` | `/opt/infrasignal-staging/conf/...runtime` |
| nginx       | `/var/www/fixmystreet/web` (ro)      | `/opt/infrasignal-v2/web` | `/opt/infrasignal-staging/web`          |

**Left shared with v2 on purpose** (identical content, no UI impact,
db container not recreated):

- nginx routing config: `../conf/nginx.conf-docker`, `../conf/nginx-main.conf`
- db schema: `../db`

This compose file lives in prod's tree but only drives the `staging`
compose project (prod uses `docker-compose-prod.yml`), so the edit does
not affect prod.

### Containers recreated

```bash
cd /opt/infrasignal-v2
sudo docker compose -p staging -f docker/docker-compose-staging.yml \
    --env-file docker/.env up -d --no-build --no-deps fixmystreet
# waited healthy, then:
sudo docker compose -p staging -f docker/docker-compose-staging.yml \
    --env-file docker/.env up -d --no-build --no-deps nginx
```

`--no-build` (reuse existing image) and `--no-deps` (don't touch db /
memcached) kept the blast radius to exactly the two app/web containers.

---

## Issue hit + fixed: `/reports` 500

After recreating the app container, `/reports` returned 500:

```
Error open ... '/var/www/fixmystreet/../data/all-reports.json':
No such file or directory at .../Controller/Reports.pm line 47.
Perhaps the bin/update-all-reports script needs running.
```

Cause: the reports index reads a generated JSON in the container's
`/var/www/data/` (ephemeral, **not** a mounted volume). The old
container had it; the freshly-recreated container did not. Fix:

```bash
sudo docker exec staging-fixmystreet-1 \
    bash -c 'cd /var/www/fixmystreet && bin/update-all-reports'
```

This regenerated `/var/www/data/all-reports-dashboard.json` (the
InfraSignal cobrand's dashboard data) and `/reports` returned to 200.

**Caveat:** because `/var/www/data` is ephemeral, `/reports` will 500
again if the staging app container is recreated. Same setup as prod/dev
(normally kept fresh by the FixMyStreet cron). After any future staging
recreate, re-run `bin/update-all-reports`. (Future hardening option:
mount a `data` dir or volume so it persists — not done now to avoid
scope creep.)

---

## Verification

```
staging /            -> 200
staging /reports     -> 200
staging /report/1    -> 410   (correct — the 'Test' report was hidden)
staging /report/2    -> 200
staging /report/723  -> 200
staging /report/new… -> 200
staging /about       -> 200
staging /how-it-works-> 200
staging /alert/list  -> 200
staging CSS hash     -> 61d616c92162   (dev's latest)

containers: staging-fixmystreet-1 healthy, staging-nginx-1 healthy

PROD (untouched):
  / -> 200
  css hash 9f74d1d3f54a   (old — NOT dev's; prod still on its own code)
  problems 0
  mount still /opt/infrasignal-v2, commit still 39b493aed

DEV (untouched): / -> 200
```

---

## How to re-sync staging with dev in future

When dev advances and you want staging to match again:

```bash
sudo rsync -a --delete --exclude='.git/' --exclude='local/' \
    --exclude='conf/general.yml-staging.runtime' \
    /opt/infrasignal-dev/ /opt/infrasignal-staging/
# (the --exclude on the runtime config keeps staging's DB password file)
sudo docker exec staging-fixmystreet-1 \
    bash -c 'cd /var/www/fixmystreet && bin/make_css web/cobrands/infrasignal/'   # if SCSS changed
sudo docker exec staging-fixmystreet-1 \
    bash -c 'cd /var/www/fixmystreet && bin/update-all-reports'                   # refresh /reports
```

Templates and prebuilt CSS are picked up live (Catalyst reads templates
per-request; nginx serves `web/` static). A container restart is only
needed if Perl code under `perllib/` changed in a way the running
workers cached.

---

## Three environments now (fully independent)

| Env     | URL      | Source tree                | Database                      |
|---------|----------|----------------------------|-------------------------------|
| prod    | infrasignal.org (`:80/443`) | `/opt/infrasignal-v2` (39b493aed) | `docker-db-1` (0 reports, clean) |
| staging | `:8080`  | `/opt/infrasignal-staging` (dev mirror) | `staging-db-1` (722 demo reports) |
| dev     | `:3001`  | `/opt/infrasignal-dev` (b87297993 + WIP) | `infrasignal-dev-dev-db-1` (723 scrubbed) |

Each has its own code tree **and** its own database/volume. Changes in
one cannot affect another.

---

## What's committed vs host-only

- **`docker/docker-compose-staging.yml`** — the mount edits. This IS in
  git (`/opt/infrasignal-v2` + mirrored to `/opt/infrasignal-dev`),
  should be committed/pushed to `dev`.
- **`/opt/infrasignal-staging`** — host-only directory, not in git
  (it's a generated mirror, like a build artifact). Rebuilt by rsync.
- Documentation (this note + CHANGELOG) — in git, mirrored to both repos.
