# Production deploy (dev→prod catch-up) + dev/staging/prod parity check — 2026-06-21

## Summary

First production deploy in ~7 weeks. Production was advanced from its
frozen commit `39b493aed` (May 3) to `origin/dev` HEAD `45c6cae05`,
bringing **153 commits** of accumulated dev work live (all of it already
validated on staging). Two headline fixes in this batch:

- **Session security timeouts** (60-min idle + 8-hr absolute cap).
- **"Report as" select clipping fix** on `/report/new`.

Also created a **Buffalo Grove test admin** for live prod testing
(to be deleted afterwards), and ran a thorough **dev = staging = prod
UI parity verification** in response to "the UI doesn't match" reports.

Net result: code/templates/CSS are now byte-identical across all three
environments (`45c6cae05`, `base.css?48f2d9c52e89`). Remaining visual
differences are **data / per-env config / login-state only** — not
missing deploys.

---

## 1. Production deploy

### Pre-deploy state (discovered, flagged before acting)

| Item | Finding |
|------|---------|
| Branch / commit | `dev` @ `39b493aed` (May 3) — **153 commits behind** `origin/dev`, 0 ahead |
| Working tree | **Dirty** — 77 uncommitted modified tracked files (stale copies superseded by dev) |
| `nginx.conf-prod`, `docker-compose-prod.yml` | Already **identical** to `origin/dev` — advancing changes neither |
| `conf/general.yml` (secrets, MapIt, Turnstile, OIDC) | **Gitignored** — untouched by any git op |
| Prod DB | had `priority_zone_config` (0094); needed `0095` (`body_id`) |
| Prod data | 4 problems, 5 users (low blast radius) |
| `bin/deploy` | its `require_clean_tree()` would have **aborted** on the dirty tree |

Because the tree was dirty, a plain `bin/deploy` could not run. The
deterministic safe path was a backed-up hard reset to `origin/dev`.
User approved the destructive step explicitly.

### Backups (all under `/opt/backups/infrasignal/`, ts `20260622_004725`)

```
prod-HEAD-before-deploy-20260622_004725.txt   = 39b493aedab0da47b61dbb0f1da8dd283857c032  (rollback target)
prod_pre-deploy_20260622_004725.sql.gz        = 11M  full prod DB dump
prod-uncommitted-tracked-20260622_004725.patch= 2.3M (79 files) the discarded uncommitted edits
prod-untracked-20260622_004725.tar.gz         = 3.0M untracked files
prod-status-20260622_004725.txt               = git status snapshot
```

### Steps executed (in order)

```bash
cd /opt/infrasignal-v2
# 1. backups (above)
# 2. align code to validated dev HEAD
git reset --hard origin/dev          # 39b493aed -> 45c6cae05, tree clean
# 3. schema migration (transactional), like staging
cat db/schema_0095-priority-zones-per-body.sql | \
    docker exec -i docker-db-1 psql -U postgres infrasignal -v ON_ERROR_STOP=1
# 4. assets (no cpanfile change -> NO image rebuild needed)
docker exec docker-fixmystreet-1 bash -lc 'cd /var/www/fixmystreet && bin/make_css infrasignal'
docker exec docker-fixmystreet-1 bash -lc 'cd /var/www/fixmystreet && bin/make_msg'   # es/ru/tr .mo
# 5. reload app + flush cache (only ~15s downtime, single container restart)
docker restart docker-fixmystreet-1
docker restart docker-memcached-1
docker exec docker-fixmystreet-1 bash -lc 'cd /var/www/fixmystreet && bin/update-all-reports'
```

Note: `.mo` translation files are **not** tracked in git, so the reset
did not refresh them — `bin/make_msg` recompiled them from the now-current
`.po` sources (Spanish/Russian/Turkish).

### Verification (post-deploy)

- `bin/healthcheck` → **9/9 passed** (HTTPS homepage, all containers, DB,
  disk 41%, memory, recent backup).
- Endpoints all **200**: `/`, `/reports`, `/auth`, `/report/new?…`, `/about`.
- "Report as" fix **live**: served `base.css?48f2d9c52e89` contains
  `select#form_as.form-control{height:auto;min-height:44px;line-height:1.4}`.
- Session-timeout code present (`check_session_timeout` ×3 in `Root.pm`);
  behavior was fully validated on staging with identical code.
- Prod serving commit `45c6cae05`.

### Rollback (if ever needed)

```bash
cd /opt/infrasignal-v2
git reset --hard 39b493aed
gunzip -c /opt/backups/infrasignal/prod_pre-deploy_20260622_004725.sql.gz | \
    docker exec -i docker-db-1 psql -U postgres infrasignal
docker restart docker-fixmystreet-1 docker-memcached-1
# or: bin/deploy --rollback
```

---

## 2. Buffalo Grove test admin (TEMPORARY — delete after testing)

Created on **production** for live admin testing:

| Field | Value |
|-------|-------|
| Email | `bg-admin-test@infrasignal.org` |
| Password | `BGtest!2026Grove` |
| User id | 17 |
| Scope (`from_body`) | 10588 = Buffalo Grove, IL |
| Role | `Auth` (role id 1) — full body-scoped manager perms |
| Superuser | No (intentionally body-scoped) |

Created via the app ORM (correct bcrypt hashing), verified
`_check_password` → `PASSWORD_OK`. A `curl` login can't complete because
prod sign-in enforces **Cloudflare Turnstile**; a real browser passes it.

**Deletion when testing is done:**

```bash
docker exec docker-db-1 psql -U postgres infrasignal -c \
  "DELETE FROM user_roles WHERE user_id=17;
   DELETE FROM users WHERE id=17 AND email='bg-admin-test@infrasignal.org';"
# also clear any active session rows for that user
```

---

## 3. dev = staging = prod UI parity verification

Triggered by reports that prod "doesn't look like dev" on the Buffalo
Grove reports page and `/report/new`. Findings (proven by fetching +
diffing rendered HTML, logged out, same URLs):

### Identical everywhere
- Git commit: all three at `45c6cae05` (staging is an rsync mirror, not a
  git repo, but content matches).
- Compiled CSS: all serve `base.css?48f2d9c52e89`.
- `/report/new` first screen (hero, category list, Continue) and `/reports`
  sidebar markup: byte-identical (prod vs staging main-content diff = only
  hostname/config lines).

### Differences — all data / config / mode / login-state (NOT deploy gaps)

| Difference | prod | dev | staging | Why |
|------------|------|-----|---------|-----|
| Report pins / demo data | 3 real | ~100 demo | demo | prod intentionally wiped of test data (`2026-05-29-prod-data-wipe.md`) |
| `data-staging` "Staging site" notice | no | yes | yes | non-prod env flag |
| Cloudflare Turnstile on report flow | yes | no | no | `general.yml` keys set on prod only (spam protection) |
| "Sign in with Google" (OIDC) button | yes | no | no | OIDC creds in prod `general.yml` only |
| Catalyst debug toolbar | no | yes | no | dev runs in development mode |
| Login state in user's screenshots | staff (Assign tool) | public (report banner) | — | role-dependent rendering, same template |

Conclusion: the product UI (code/templates/styles) matches across all
three. Perceived mismatches are explained entirely by the table above.
If prod styling ever looks stale in a browser, hard-refresh to pick up
`base.css?48f2d9c52e89`.

---

## What's committed vs host-only

- **This note + CHANGELOG entry** — in git on `dev`, mirrored to
  `/opt/infrasignal-v2`.
- **The deploy itself** — operational; no new code (prod just caught up to
  `origin/dev`). The code changes were already committed (`45c6cae05`).
- **Backups** under `/opt/backups/infrasignal/` — host-only.
- **`/opt/infrasignal-staging`** — host-only rsync mirror, not git.
- **Buffalo Grove test admin** — prod DB only, to be deleted.
