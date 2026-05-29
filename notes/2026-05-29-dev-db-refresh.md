# Dev DB seeded from prod (PII scrubbed) — 2026-05-29

## Summary

Built `bin/refresh-db` and ran it against dev. Dev's previously-empty
isolated database (from the 2026-05-26 isolation work) now holds a
**scrubbed snapshot of prod**: 723 problems, 555 comments, 28,090
bodies, 9 users. Prod was read-only throughout; only `pg_dump` ran
against `docker-db-1`. Staging was deliberately left empty per user
preference.

The whole refresh ran in ~22 seconds with no manual steps.

---

## Why

After the 2026-05-26 dev DB isolation, dev had its own database but
zero records. That made dev technically isolated but practically
useless — every page rendered empty, every test had to start by
manually creating reports, no way to validate UI changes against
realistic data shapes.

The `notes/2026-05-26-dev-db-isolation.md` follow-ups list called
this out explicitly:

> Pending: build `bin/refresh-db` to copy + scrub prod into dev / staging.

This session implements that.

---

## What changed

### New file: `bin/refresh-db`

Mirrored to both `/opt/infrasignal-dev/bin/` and `/opt/infrasignal-v2/bin/`
(same pattern as `bin/optwatch`).

Usage:

```
bin/refresh-db dev                 # refresh dev DB from prod
bin/refresh-db staging             # refresh staging DB from prod
bin/refresh-db dev --dry-run       # show plan, do nothing
bin/refresh-db dev --with-photos   # also rsync prod web/photo (opt-in)
```

Safety properties:

- **Refuses to target prod** — args `dev` or `staging` only.
- **Backs up the target DB** to `/tmp/${target}-backup-<ts>.sql.gz`
  before wiping. The dev refresh wrote a 10 KB backup (dev was empty
  so that's expected).
- **Source dump is kept** at `/tmp/prod-dump-<ts>.sql` for post-mortem
  debugging.
- **Restore log** lands at `/tmp/restore-<target>-<ts>.log`.

Pipeline (8 steps):

1. `pg_dump --clean --if-exists --no-owner` from prod (read-only,
   non-blocking on the prod app).
2. `pg_dump` of the current target DB → gzipped backup.
3. `REVOKE CONNECT` + `pg_terminate_backend` to free the target DB.
4. `DROP DATABASE infrasignal; CREATE DATABASE infrasignal;` — run as
   **separate `psql -c` calls** because `DROP DATABASE` cannot run
   inside a transaction block. Hit that bug on the first attempt and
   fixed it.
5. `psql < dump` into target.
6. Scrub SQL (see below).
7. `docker restart` the target memcached so the app stops returning
   cached empty results. (Initial attempt used a bash `/dev/tcp` trick
   to send `flush_all` — failed because the memcached image is busybox
   without bash. Restart is portable and instant.)
8. Verify: count rows in 7 key tables, print 5 sample scrubbed users.

### Scrub SQL — what gets anonymized

Wrapped in a single `BEGIN/COMMIT` so it's all-or-nothing.

| Table   | Columns set to                                                          |
|---------|-------------------------------------------------------------------------|
| users   | `email='user-<id>@example.invalid'`, `name='Dev User <id>'`, `phone=NULL`, `phone_verified=false`, `email_verified=true`, `password=''`, `twitter_id=NULL`, `facebook_id=NULL`, `oidc_ids=NULL`, `extra='{}'` |
| problem | `name='Dev Reporter <user_id>'`, `cobrand_data=''`, strip `email/phone/name/contact/first_name/last_name/reporter_email` keys from `extra` jsonb |
| comment | `name='Dev Commenter <user_id>'`, `website=NULL`, `cobrand_data=''`, strip same jsonb keys, `private_email_text=NULL` |

Tables wholesale `TRUNCATE`d:

- `abuse` — email blacklist (raw addresses).
- `admin_log` — admin action history (often references user details).
- `sessions` — active session blobs (force re-login).
- `token` — outstanding email-confirm / password-reset tokens.
- `partial_user` — half-registered users (raw emails).
- `moderation_original_data` — pre-moderation report content (often
  the raw, un-redacted version of `problem.detail`).
- `textmystreet` — SMS reporting integration (phone numbers).
- `alert_sent` — log of which alert emails were sent to which users.

A stable superuser is created/upserted so dev always has a known
admin handle regardless of what's in prod:

```sql
INSERT INTO users (email, name, password, is_superuser, email_verified, created, last_active)
VALUES ('dev-admin@example.invalid', 'Dev Admin', '', true, true, NOW(), NOW())
ON CONFLICT DO NOTHING;
```

(`ON CONFLICT DO NOTHING` so re-running the refresh doesn't error if
that account already exists.)

### Deliberately NOT scrubbed (functional content)

- `problem.title`, `problem.detail`, `comment.text` — real prod report
  content. A user-typed title like *"Tree fallen at 12 Main St"* can
  still indirectly leak an address. Acceptable for dev because dev is
  not public (it lives at `http://REDACTED-IP:3001/` behind owner
  access only), but worth being aware of if dev is ever exposed.
- All `body*`, `contacts*`, `category*`, `defect_types`,
  `response_templates`, `response_priorities`, `state`, `config`,
  `priority_zone_config`, `osm_zone_cache`, `roles`,
  `report_extra_fields`, `flickr_imported`, `manifest_theme`,
  `translation`, `secret` — operational reference data, not PII.
- Photo file references stay in `problem.photo`, but the photo
  **files** in `web/photo/` are **not** copied by default. Reports
  with photos will render broken `<img>` tags. Pass `--with-photos`
  to also rsync them in (slower, larger disk footprint, plus photos
  themselves can be a separate PII vector — license plates,
  bystanders, addresses).

### What happened during the dev run

```
Dumping prod DB → /tmp/prod-dump-20260529T151143Z.sql
  dump size: 143704259 bytes              (~137 MB; most of it is bodies/contacts)
Backing up current dev DB
  backup size: 10641 bytes                (was empty schema)
Terminating active connections to dev.infrasignal
Dropping + recreating dev.infrasignal
Restoring dump into dev.infrasignal
  restore ERROR lines: 0
Scrubbing PII
Restarting memcached
Verifying
  problems|723
  users|9                                 (8 from prod + dev-admin)
  comments|555
  bodies|28090
  alerts (kept)|6
  sessions (wiped)|0
  tokens (wiped)|0
Sample scrubbed users:
  5  | user-5@example.invalid  | Dev User 5
  9  | user-9@example.invalid  | Dev User 9
  10 | user-10@example.invalid | Dev User 10
  11 | user-11@example.invalid | Dev User 11
  12 | user-12@example.invalid | Dev User 12
```

Total wall time: 22 seconds.

---

## Verification

After the refresh:

- `http://127.0.0.1:3001/` → 200
- `http://127.0.0.1:3001/reports` → 200
- `http://127.0.0.1:3001/report/1` → 200
- `http://127.0.0.1:3001/report/723` → 200 (latest prod report id is
  reachable on dev)
- Prod DB: still 723 problems, max id 723 (unchanged)
- Prod site: still 200
- Three DB containers still on their own networks, no cross-talk in
  `pg_stat_activity`.

---

## Staging — deliberately left empty

User chose to keep staging's DB empty for now. To refresh later, the
exact same command works:

```
/opt/infrasignal-dev/bin/refresh-db staging
```

Same safety, same scrub.

---

## Reversibility

### Roll dev back to the pre-refresh empty state

```
gunzip < /tmp/dev-backup-20260529T151143Z.sql.gz \
  | sudo docker exec -i infrasignal-dev-dev-db-1 psql -U postgres -d infrasignal
```

(The backup is `--clean --if-exists` so the restore wipes the
prod-snapshot first.)

### Or just re-run the refresh

The script is idempotent — re-running it gives you a fresh prod
snapshot, current as of the moment you run it.

### Remove the script

```
rm /opt/infrasignal-dev/bin/refresh-db /opt/infrasignal-v2/bin/refresh-db
```

(Doesn't affect any container or DB. The dump/backup files in `/tmp`
also survive — clean those up manually if disk pressure matters.)

---

## Bugs hit + fixed during this session

1. **`DROP DATABASE cannot run inside a transaction block`** — psql
   wraps a multi-statement `-c` argument in an implicit transaction.
   Fixed by splitting DROP / CREATE / GRANT into three separate
   `psql -c` calls.
2. **`memcached flush via bash /dev/tcp` failed silently** — the
   memcached image is busybox and lacks both bash and nc. Switched
   to `docker restart`, which is portable and clean.

---

## Open / known follow-ups

- **Photos**: `--with-photos` exists but wasn't exercised. Worth a
  test run before relying on it (verifies the rsync target dir and
  the right host path).
- **Schema drift**: if prod's schema advances past dev's installed
  schema, the restore will work (it brings prod's schema along), but
  any dev-side feature work that touched the schema would be
  overwritten. Worth a `bin/update-schema --check` pass before
  refreshing if dev has been doing schema work.
- **Same recipe for staging**: not run yet by request. Script
  supports it identically.
- **Automation**: this still requires a manual run. A weekly cron is
  easy to add (`0 6 * * 1 root /opt/infrasignal-v2/bin/refresh-db dev`)
  but skipped for now — first let the user choose the cadence.
