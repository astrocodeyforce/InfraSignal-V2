# Prod data wipe (clean slate for customers) — 2026-05-29

## Summary

Cleared all user-generated / demo content from the **production**
database so the first real customers see a fresh app. Operational
reference data (bodies, contacts, categories, zone config, etc.) was
kept intact. The demo dataset (723 reports) was first copied to
**staging** so it survives as a presentation environment.

Prod downtime: **zero** (no container restarts beyond a memcached
cache flush). The whole wipe was a single atomic SQL transaction.

---

## Why

User request, verbatim:

> "i want to remove these fake mockup '723 problems / 8 users / 555
> comments' we need to keep body related fields and datas. … keep
> superusers true"

and:

> "main purpose is to keep it clean for customers. but on staging env
> we can make sure everything is clear and we can show it / present it
> when we try to implement it"

So: prod = clean slate for real customers; staging = the demo data,
kept for sales/implementation walkthroughs.

---

## Order of operations (safety-first)

1. **Inventoried prod users + FKs** — found 4 superusers to keep,
   4 test users to wipe, and the FK graph pointing at `users`.
2. **Refreshed staging from prod** (`bin/refresh-db staging`) — full
   723-report dataset copied to staging, PII scrubbed. Prod read-only
   during this step.
3. **Took two persistent prod backups** to
   `/opt/infrasignal-v2/backups/` (not /tmp — survives reboots).
4. **Showed the exact SQL to the user, waited for explicit "go".**
5. **Ran the wipe transaction** on prod.
6. **Flushed prod memcached + verified.**

No step touched prod data until step 5, and only after the user
reviewed the SQL.

---

## The transaction that ran on prod

```sql
BEGIN;

TRUNCATE TABLE
    problem,
    comment,
    alert,
    alert_sent,
    questionnaire,
    user_planned_reports,
    moderation_original_data,
    textmystreet,
    flickr_imported,
    abuse,
    admin_log,
    sessions,
    token,
    partial_user
RESTART IDENTITY CASCADE;

-- body.comment_user_id is a NO ACTION FK to users(id); null it so the
-- non-superuser delete below isn't blocked. (No rows actually had it
-- set — UPDATE 0 — but the statement is there for safety.)
UPDATE body SET comment_user_id = NULL WHERE comment_user_id IS NOT NULL;

-- user_body_permissions: NO ACTION FK, clear for non-superusers first.
DELETE FROM user_body_permissions
WHERE user_id IN (SELECT id FROM users WHERE NOT is_superuser);

-- The 4 test users. user_roles / user_planned_reports are CASCADE FKs
-- and clean up automatically.
DELETE FROM users WHERE NOT is_superuser;

COMMIT;
```

Result lines: `BEGIN / TRUNCATE TABLE / UPDATE 0 / DELETE 0 / DELETE 4
/ COMMIT`.

Then:

```bash
docker restart docker-memcached-1     # flush stale cached pages
```

`RESTART IDENTITY` on the TRUNCATE reset all sequences, so the next
real customer report is `/report/1`, not `/report/724`.

---

## Before / after (prod)

| Table                  | Before    | After   | Action |
|------------------------|-----------|---------|--------|
| problem                | 723       | 0       | wiped  |
| comment                | 555       | 0       | wiped  |
| alert                  | 6         | 0       | wiped  |
| sessions / token       | (some)    | 0       | wiped  |
| users                  | 8         | 4       | kept superusers only |
| **body**               | 28,090    | 28,090  | **kept** |
| **contacts**           | 365,170   | 365,170 | **kept** |
| **translation**        | 1,095,540 | 1,095,540 | **kept** |
| **osm_zone_cache**     | 56        | 56      | **kept** |
| **priority_zone_config** | 30      | 30      | **kept** |

`response_templates` and `defect_types` were already empty (0) in prod
before the wipe — nothing lost there.

### Surviving users (all `is_superuser = true`, passwords unchanged)

| id | email                          |
|----|--------------------------------|
| 9  | admin@infrasignal.org          |
| 11 | REDACTED-EMAIL          |
| 12 | dev-admin@infrasignal.org      |
| 14 | dev-admin@infrasignal.local    |

---

## Where the old prod data lives now

1. **Staging** — `http://127.0.0.1:8080/` — full 723-report dataset,
   PII scrubbed, kept as the demo / presentation environment. Reports
   `/report/1` … `/report/723` all load.
2. **Backup 1** —
   `/opt/infrasignal-v2/backups/prod-20260529T174837Z-pre-wipe.sql.gz`
   (11 MB, plain SQL, `--clean --if-exists`).
3. **Backup 2** —
   `/opt/infrasignal-v2/backups/prod-20260529T174837Z-pre-wipe.dump`
   (11 MB, custom format — supports selective `pg_restore -t table`).

---

## Verification

```
prod content:   problems 0, comments 0, alerts 0, sessions 0, tokens 0
prod reference:  bodies 28090, contacts 365170, translation 1095540,
                 osm_zone_cache 56, priority_zone_config 30
prod users:      4 (all superusers)
next problem id: 1
site:            infrasignal.org / -> 200, /reports -> 200
```

---

## Rollback

Full restore to the exact pre-wipe state (~15 s):

```bash
gunzip < /opt/infrasignal-v2/backups/prod-20260529T174837Z-pre-wipe.sql.gz \
  | sudo docker exec -i docker-db-1 psql -U postgres -d infrasignal
sudo docker restart docker-memcached-1
```

Or selectively restore a single table from the custom-format dump:

```bash
sudo docker cp /opt/infrasignal-v2/backups/prod-20260529T174837Z-pre-wipe.dump \
  docker-db-1:/tmp/restore.dump
sudo docker exec docker-db-1 \
  pg_restore -U postgres -d infrasignal -t problem --data-only /tmp/restore.dump
```

---

## Staging demo polish (customer-facing presentation)

Staging (`:8080`) is the environment shown to **prospective
customers** — not dev, not prod. The raw `bin/refresh-db` scrub
leaves obviously-synthetic placeholder names (`Dev User 5`,
`Dev Reporter 11`) which display publicly on report pages
(145 named reports, 115 named comments) and read as "test site".
For a credible demo these were replaced with realistic-but-synthetic
identities.

Applied on staging only (single transaction, fully reversible by
re-running `bin/refresh-db staging`):

| user_id | name              | email                          |
|---------|-------------------|--------------------------------|
| 5       | Michael Anderson  | michael.anderson@example.com   |
| 9       | Jennifer Martinez | jennifer.martinez@example.com  |
| 10      | David Thompson    | david.thompson@example.com     |
| 11      | Sarah Williams    | sarah.williams@example.com     |
| 12      | Robert Johnson    | robert.johnson@example.com     |
| 13      | Emily Davis       | emily.davis@example.com        |
| 14      | James Wilson      | james.wilson@example.com       |
| 15      | Jessica Brown     | jessica.brown@example.com      |
| 16      | InfraSignal Team  | team@example.com               |

- `users.name/email`, `problem.name` (723 rows), and `comment.name`
  (555 rows) all updated from this map by `user_id` so the same
  person shows the same name everywhere. `example.com` is the
  reserved example domain — looks real, can never be a live inbox.
- The one obviously-fake report (id 1, title `Test`) was hidden from
  public view (`state = 'hidden'` — not deleted). Visible reports:
  **722**; hidden: 1.
- Result: 0 `Dev *` names remain anywhere public; `/report/2` now
  shows "Sarah Williams"; staging `/` and `/reports` return 200.

## Notes / follow-ups

- **The wipe was prod-only.** Dev (`infrasignal-dev-dev-db-1`) and
  staging (`staging-db-1`) are separate databases on separate volumes
  and were not affected.
- **Staging data is PII-scrubbed then demo-polished** (see section
  above). Report titles / details / comment text are verbatim from
  prod (needed for a realistic demo); identities are synthetic.
  Acceptable because staging is non-public and contains no real PII.
- **Photos** were not copied to staging (the DB references them by
  hash but the files live in prod's `web/photo/`). Reports with
  photos will show broken images on staging. Run
  `bin/refresh-db staging --with-photos` if photo fidelity matters
  for the demo.
- **Backups are not in git** (`/opt/infrasignal-v2/backups/` — 11 MB
  binaries). They live on the host only. If the host is rebuilt,
  copy them off first.
