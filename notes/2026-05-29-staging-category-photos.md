# Category demo photos — staging + dev (2026-05-29)

**Scope:** STAGING (`/opt/infrasignal-staging`, `staging-db-1`, `:8080`) and
DEV (`/opt/infrasignal-dev`, `infrasignal-dev-dev-db-1`, `:3001`).
PRODUCTION (`infrasignal.org`, `docker-db-1`) is **intentionally excluded** —
it was wiped clean for customers and has **0 visible reports**, so there are no
photos to replace and no mock data is added to the live site.

## Goal

Every visible report on dev + staging should display an on-topic, realistic
photo so the environments look credible in customer demos. Previously only 5
reports per environment had photos (carried over from the prod copy).

| Env | Visible reports | With photo (after) |
|---|---|---|
| staging | 722 | 722 |
| dev | 723 | 723 |
| prod | 0 | 0 (clean, untouched) |

## What was done

13 photorealistic "citizen report" photos were generated — one per distinct
issue type — and assigned to all 722 visible reports by category. The 17
category strings in the data collapse to 13 real-world issue types:

| Photo file (`demo-assets/category-photos/`) | Categories it covers |
|---|---|
| `cat-pothole.jpg`            | Pothole / Road Damage · Pothole & Road |
| `cat-sidewalk.jpg`           | Sidewalk Damage · Sidewalk |
| `cat-streetlight.jpg`        | Streetlight Outage · Streetlight |
| `cat-abandoned-vehicle.jpg`  | Abandoned Vehicle |
| `cat-illegal-dumping.jpg`    | Illegal Dumping |
| `cat-graffiti.jpg`           | Graffiti / Vandalism · Graffiti |
| `cat-traffic-signal.jpg`     | Traffic Signal / Sign Issue |
| `cat-drainage.jpg`           | Drainage / Flooding |
| `cat-park.jpg`               | Park / Public Space Issue |
| `cat-fallen-tree.jpg`        | Fallen Tree / Vegetation |
| `cat-water-sewer.jpg`        | Water / Sewer Issue |
| `cat-bridge.jpg`             | Bridge / Guardrail Damage |
| `cat-other.jpg`              | Other |

Masters were downsized to 1200×800, q82 progressive JPEG (~80–340 KB each,
~2.9 MB total) so the full-size "zoom" image isn't multi-MB.

## How it works (FixMyStreet photo internals)

The Photo controller (`perllib/.../Controller/Photo.pm` → `index`) requires
`problem.photo` to be non-null, then `PhotoSet->get_image_data` is called.
`get_image_data` (`.../Model/PhotoSet.pm`) **checks the `web/photo` cache
first** (`get_cached`, keyed by `<report_id>.<num>.<size>.jpeg`) and only falls
back to resizing the master from `UPLOAD_DIR/<hash>.jpeg` if no cache file
exists. The `web/photo` dir is the persistent host mount
(`/opt/infrasignal-staging/web/photo`); `UPLOAD_DIR` resolves to
`/var/www/upload` which is **inside the container (ephemeral)**.

Sizes requested by templates:
- `fp` (crop, ~90×60) — list/thumbnail (`_item.html` `url_fp`)
- default / no-size (shrink 250×250) — main image on report detail (`url`)
- `full` (master, unresized) — zoom link (`url_full`)
- `tn` (shrink x100), `og` (crop 1200×630, social meta) — incidental

## Per-report isolation (verified)

Each report has its **own** cache files keyed by report id
(`<id>.0.<size>.jpeg`). `delete_cached` (`PhotoSet.pm`) only unlinks files for
the report's own id and never touches the `UPLOAD_DIR` master. When a real user
uploads a photo, FixMyStreet content-hashes the new image, stores it as a new
`UPLOAD_DIR/<newhash>.jpeg`, sets only that report's `photo` column, and
regenerates only that report's cache.

Therefore a later upload/edit/delete on one report **cannot affect any other
report**, even though same-category reports currently share one source master
(normal FMS content-dedup — identical to two real users uploading the same
image). Verified live on dev: changing report 6's photo to a different image
left report 26 (same category, same original image) byte-for-byte unchanged.

## Procedure (reproducible: `bin/seed-demo-photos.sh <dev|staging>`)

1. SHA1 each master, `docker cp` it into the container as
   `/var/www/upload/<hash>.jpeg`.
2. Per category: `UPDATE problem SET photo='<hash>.jpeg'` for every visible
   report in that category.
3. Pick one representative report; delete any stale prod cache for it
   (otherwise `get_cached` would serve the old image), then `curl` its
   `fp`/`tn`/default URLs so the app regenerates fresh resized variants into
   `web/photo`. Copy the master in as `<rep>.0.full.jpeg`.
4. Fan out: copy the representative's 4 variant files to every other report id
   in the category (identical image ⇒ identical resized blobs) and `cp` the
   master as each `<id>.0.full.jpeg`.

Re-run any time with:

```bash
bash /opt/infrasignal-dev/bin/seed-demo-photos.sh staging
bash /opt/infrasignal-dev/bin/seed-demo-photos.sh dev
```

## Verification

- `full` served byte-identical to the category master (md5 match) for sampled
  reports across all categories.
- `fp` (~1.7–2.3 KB), default (~7–13 KB), `full` (~80–285 KB) all return 200.
- Report detail page emits `/photo/<id>.0.jpeg` + `…full` + `…og`.
- 722 / 722 visible reports now have `problem.photo` set.

## Caveats / persistence

- The displayed sizes (`fp`, default, `full`) live in the **persistent** host
  mount `web/photo`, so they survive container restarts/recreates.
- The hash masters in `/var/www/upload` are **ephemeral**. They are only needed
  as a fallback when a cached size is missing (e.g. `og` for social previews).
  After a container recreate, re-run `bin/seed-staging-photos.sh` to repopulate
  upload (and refresh any missing cache).
- Photos are synthetic/demo only; not real incident imagery.
