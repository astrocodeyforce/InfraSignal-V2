# Restoration after dev/v2 directory desync — 2026-05-27

## Summary

Sometime around **2026-05-27 14:58 UTC**, the on-disk state of both
`/opt/infrasignal-v2` and `/opt/infrasignal-dev` was rearranged by an
unidentified bulk operation. Every file I edited or created in the
2026-05-26 production-hardening + dev-DB-isolation sessions was deleted
from `/opt/infrasignal-v2`. A handful of dev-specific files were also
deleted from `/opt/infrasignal-dev` (notably the edited
`docker-compose-local.yml` and the live `conf/general.yml`).

**The running containers were not restarted by the deletion**, so
prod, staging, and dev continued serving HTTP 200 the whole time —
because Docker loads compose files at `up` time and never re-reads
them. The risk: any container restart (host reboot, OOM, `docker
restart`) would have failed because the on-disk compose / config was
gone.

This note documents what happened, how I diagnosed it, and how I
rebuilt the on-disk state from the running containers + the one
surviving backup file (`general.yml.pre-isolation-2026-05-26.bak`).

---

## How I noticed

User asked to "document every change" from the previous session. I
ran `git status` in `/opt/infrasignal-v2` and saw:

```
 D .gitignore
 D ARCHITECTURE.md
 D CHANGELOG.md
 D README.md
 D bin/deploy
 D conf/nginx.conf-prod
 D docker/docker-compose-prod.yml
 D docker/docker-compose-staging.yml
```

The leading `D` means "tracked, missing from worktree." Direct `ls`
and `Read` calls confirmed every file from the 2026-05-26 work was
gone. Worse, several FixMyStreet-base tracked files (the ones I'd
edited on top of) were also missing.

---

## Forensic snapshot at first contact

```
=== existed in /opt/infrasignal-v2 ===
conf/general.yml                      ← prod runtime config (intact)
conf/general.yml-staging.runtime      ← from 2026-05-26 staging work (intact)
conf/nginx-main.conf                  ← intact (mtime Feb 28)
conf/ssl/                             ← intact
docker/docker-compose-local.yml       ← FixMyStreet template (intact)
docker/docker-compose-test.yml        ← FixMyStreet template (intact)
docker/docker-compose-dev.yml         ← FixMyStreet template (intact)
docker/.env -> /opt/infrasignal-v2/.env  ← intact
bin/* (most original FixMyStreet tools, but NOT bin/deploy, NOT bin/staging-deploy, NOT bin/cron-wrapper)

=== missing from /opt/infrasignal-v2 ===
ARCHITECTURE.md                              (was edited)
CHANGELOG.md                                 (was edited)
README.md                                    (was edited)
SYSTEM-MAP.md                                (new in 2026-05-26)
.gitignore                                   (was edited)
bin/deploy                                   (was edited)
bin/staging-deploy                           (new in 2026-05-26)
bin/cron-wrapper                             (FixMyStreet original — also gone)
conf/nginx.conf-prod                         (was edited)
docker/docker-compose-prod.yml               (was edited)
docker/docker-compose-staging.yml            (was edited)
docker/docker-compose-prod-image.yml         (new in 2026-05-26)
notes/2026-05-26-prod-hardening.md           (new in 2026-05-26)
notes/2026-05-26-dev-db-isolation.md         (new in 2026-05-26)

=== existed in /opt/infrasignal-dev ===
ARCHITECTURE.md         ← FixMyStreet original, not my edited prod version
CHANGELOG.md            ← FixMyStreet original
README.md               ← FixMyStreet original
bin/deploy              ← FixMyStreet/InfraSignal original (BRANCH="main", no clean-tree guard)
docker/docker-compose-prod.yml       ← pre-2026-05-26 version (no Host-header healthcheck)
docker/docker-compose-staging.yml    ← pre-2026-05-26 version (no runtime mount)
conf/general.yml.pre-isolation-2026-05-26.bak  ← byte-for-byte backup of dev's pre-isolation general.yml

=== missing from /opt/infrasignal-dev ===
docker/docker-compose-local.yml      (was edited in 2026-05-26)
conf/general.yml                     (was edited in 2026-05-26)
```

All affected directories in BOTH repos had mtimes within a 2-second
window around `14:58:38–14:58:40 UTC` 2026-05-27. That's the
signature of a single bulk operation (script, rsync, sync tool),
not manual editing.

---

## What I checked to rule out git

- `git -C /opt/infrasignal-v2 rev-parse HEAD` → still on
  `39b493ae...` (May 3 commit) — no new commits.
- `git -C /opt/infrasignal-v2 reflog` shows NO operation since
  `2026-05-03 20:15:06` — no `checkout`, no `reset`, no `restore`, no
  `clean`, no merge. So git itself did not delete anything.
- `/etc/cron.d/*` contained only `infrasignal-backup` (runs at 03:00
  UTC, just `pg_dump`), `infrasignal-healthcheck` (every 5 min, just
  curl), `docker-image-prune` (00:56 UTC, just prune). None of these
  delete source files.

Conclusion: the deletions happened **outside git, outside cron, and
outside the obvious scripts**. The bash history showed multiple
`cp -p /opt/infrasignal-dev/... /opt/infrasignal-v2/...` calls
(copying templates between the two trees) but no `rm`, no `rsync`, no
`git clean`. The actual mechanism remains unknown — most likely
suspects are an editor extension, a manual sync command not run in
the visible shell, or an IDE/extension that ran a sync between two
"workspaces." Confirming the cause is left as an open item; the
restoration is complete regardless.

---

## What I did to recover

### 1. Snapshotted ground truth from the running containers

`docker inspect` is the source of truth for what a running container
is using. For each of the 11 live containers I dumped the full
inspect JSON to `/tmp/<name>.json` and extracted: `Image`, `Cmd`,
`Env`, `Mounts`, `Networks`, `NetworkSettings.Networks[*].Aliases`,
`HostConfig.Binds`, `HostConfig.RestartPolicy`, `HostConfig.PortBindings`,
`Config.Healthcheck`. That gave me a complete reconstruction of every
service's compose definition.

### 2. Discovered the bind-mount inode trick

`docker exec docker-nginx-1 cat /etc/nginx/conf.d/default.conf`
returned the **complete current nginx config including my 2026-05-26
edits** — even though the source file
(`/opt/infrasignal-v2/conf/nginx.conf-prod`) had been deleted from
the host. Docker's bind mount kept the inode alive for the running
container. I captured both `nginx.conf-prod` and `nginx-main.conf`
this way (`docker exec ... cat ... > /tmp/...`).

### 3. Used files that ended up in the wrong repo

`docker-compose-prod.yml`, `docker-compose-staging.yml`, and
`bin/deploy` had landed in `/opt/infrasignal-dev/` after the desync
(in pre-2026-05-26 form). I copied them back to `/opt/infrasignal-v2/`
with `sudo cp -p ...` and then re-applied my edits via StrReplace:

- prod compose: added `Host: infrasignal.org` to the nginx healthcheck.
- staging compose: added the
  `../conf/general.yml-staging.runtime:/var/www/fixmystreet/conf/general.yml:ro`
  mount to the fixmystreet service.
- `bin/deploy`: changed `BRANCH="main"` → `BRANCH="${DEPLOY_BRANCH:-dev}"`,
  added the `require_clean_tree()` function, wired it into `--full`
  and `--migrate`.

### 4. Restored the dev compose by template + edit

`/opt/infrasignal-v2/docker/docker-compose-local.yml` happened to
still contain the original FixMyStreet "local" compose (which was
also the base for dev's compose pre-edits). I copied that to
`/opt/infrasignal-dev/docker/docker-compose-local.yml`, then added
the `dev-db` + `dev-memcached` service blocks and the `dev-pgdata`
volume — exactly matching what `docker inspect dev-db-1` showed for
the running container.

### 5. Restored dev's general.yml from .bak + 3 edits

The byte-for-byte pre-isolation backup was still on disk. I copied
it to `conf/general.yml` and re-applied the three isolation edits
(`FMS_DB_HOST`, `FMS_DB_PASS`, `MEMCACHED_HOST`).

### 6. Recreated bin/staging-deploy and the prod-image draft from memory

Both files were authored 2026-05-26 and I rewrote them with the same
behavior. Cross-checked the staging-deploy logic against the still-running
`staging-*-1` containers.

### 7. Recreated documentation

- `ARCHITECTURE.md`: copied dev's FixMyStreet base, prepended the
  "Current Production State" / "CI image" / "Staging environment" /
  "Development environment" sections.
- `CHANGELOG.md`: copied dev's base, prepended the three new
  Unreleased entries (dev DB isolation, prod hardening, restoration).
- `README.md`: copied dev's base, added the pointer block at the top.
- `SYSTEM-MAP.md`: rewrote from memory (Mermaid diagrams,
  environment matrix, where-to-edit-what, disaster recovery section).
- `notes/2026-05-26-prod-hardening.md` and
  `notes/2026-05-26-dev-db-isolation.md`: rewrote with the same
  content as the 2026-05-26 originals.

---

## Validation after restoration

| Check | Result |
| --- | --- |
| `docker compose -f docker-compose-prod.yml config --quiet` | OK |
| `docker compose -f docker-compose-staging.yml config --quiet` | OK |
| `docker compose -f docker-compose-local.yml config --quiet` (dev) | OK |
| `docker compose -f docker-compose-prod-image.yml config --quiet` | OK (with `IMAGE_TAG=test`) |
| `bin/deploy` is executable, `bin/staging-deploy` is executable | yes |
| prod: `curl -k https://infrasignal.org/` | HTTP 200 |
| staging: `curl http://127.0.0.1:8080/` | HTTP 200 |
| dev: `curl http://127.0.0.1:3001/` | HTTP 200 |
| prod-db `SELECT count(*) FROM problem` | 723 (unchanged) |
| dev-db `SELECT count(*) FROM problem` | 0 (still isolated) |

---

## Incident during restoration: ~30-second prod outage

While verifying the restored prod compose matched the running stack,
I ran:

```
sudo docker compose -p docker -f docker/docker-compose-prod.yml \
    --env-file docker/.env up -d --no-build --no-start
```

intending it to be a dry-run. It is not. `--no-start` means "create
containers without starting them," but if compose detects config
drift versus the running containers, **it deletes-and-recreates the
containers first, then leaves them in `Created` (stopped) state.**
`docker-db-1` and `docker-fixmystreet-1` were both recreated this way
because the inline command-flag formatting in my restored compose
differed slightly from what compose had stored from the original
`up`. Prod returned HTTP 504 for ~30 seconds until I noticed and ran
`docker start docker-db-1 docker-fixmystreet-1`.

**Lesson:** `docker compose ... up --no-start` is NOT a dry-run.
Use `docker compose ... config` for a no-side-effect drift check.

After the recovery, both containers came up healthy with the
restored compose, and prod returned to HTTP 200. Final smoke test:
`time_total=0.253s` on `https://infrasignal.org/`.

---

## Open items

- **Root cause of the 14:58 UTC desync is not confirmed.** It would
  be worth instrumenting the box (auditd, or even a periodic
  `find /opt/infrasignal-v2 -newer /tmp/last-check`) to catch the
  next occurrence.
- The shell environment used by the agent hung intermittently today
  (twice for 30+ minutes on `sudo` + `journalctl` / `sudo find -mmin`
  / `sudo docker inspect` combinations). Cause unknown. Workaround
  in the moment was to use the file tools (`Read`, `Glob`, `Grep`)
  instead of shell. Worth re-checking if the box is under unusual
  load or if there's a misbehaving fuse/overlay mount.
- `bin/cron-wrapper` is referenced by the legacy stack but is missing
  from `/opt/infrasignal-v2/bin/` — still present in
  `/opt/infrasignal-dev/bin/`. Not restored because nothing active
  uses it, but you may want it back if you ever revive the legacy
  stack.

---

## Files restored (in order of safety priority)

1. `/opt/infrasignal-v2/conf/nginx.conf-prod` — from `docker exec`
   extraction
2. `/opt/infrasignal-dev/conf/general.yml` — from `.bak` + 3 edits
3. `/opt/infrasignal-dev/docker/docker-compose-local.yml` — from
   FixMyStreet template + 2 new services
4. `/opt/infrasignal-v2/docker/docker-compose-prod.yml` — from dev
   copy + 1 edit
5. `/opt/infrasignal-v2/docker/docker-compose-staging.yml` — from dev
   copy + 1 edit
6. `/opt/infrasignal-v2/bin/deploy` — from dev copy + 3 edits, chmod +x
7. `/opt/infrasignal-v2/bin/staging-deploy` — rewritten from memory,
   chmod +x
8. `/opt/infrasignal-v2/docker/docker-compose-prod-image.yml` —
   rewritten from memory (still draft, not active)
9. `/opt/infrasignal-v2/ARCHITECTURE.md` — base from dev + 4 new sections
10. `/opt/infrasignal-v2/CHANGELOG.md` — base from dev + 3 new entries
11. `/opt/infrasignal-v2/README.md` — base from dev + pointer block
12. `/opt/infrasignal-v2/SYSTEM-MAP.md` — rewritten from memory
13. `/opt/infrasignal-v2/notes/2026-05-26-prod-hardening.md` — rewritten
14. `/opt/infrasignal-v2/notes/2026-05-26-dev-db-isolation.md` —
    rewritten
15. `/opt/infrasignal-v2/notes/2026-05-27-restoration-after-desync.md`
    — this file
