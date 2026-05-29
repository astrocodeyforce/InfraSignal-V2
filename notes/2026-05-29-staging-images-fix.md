# Staging broken images (logo + report photos) — 2026-05-29

## Summary

After moving staging onto its own source tree, the InfraSignal logo
and report photos showed as broken images on `:8080`. Two independent
causes:

1. **nginx routing bug** (the real one) — the image `location` block in
   `conf/nginx.conf-docker` had no `@catalyst` fallback, so every image
   URL (static logo/favicons **and** app-served `/photo/*.jpeg`) 404'd.
2. **Missing photo files** — the staging tree only had the ~20 photo
   files that came from the dev rsync; the full set lives in prod's
   `web/photo`.

Both fixed. Logo, favicons, and all 5 report thumbnails now load.
Staging-only changes; prod and dev untouched.

---

## Cause 1: nginx image location had no app fallback

`conf/nginx.conf-docker` (used **only** by `staging-nginx-1`; prod uses
`nginx.conf-prod`, dev uses its own) had:

```nginx
root /var/www/fixmystreet/fixmystreet/web;   # note: doubled path, wrong
...
location ~* \.(css|js)$ {
    ...
    try_files $uri @catalyst;                # css/js DO fall back to app
}

location ~* \.(jpg|jpeg|png|gif|ico|svg|...)$ {
    expires 30d;
    ...
    # <-- no try_files / no @catalyst fallback
}
```

Because the static `root` is wrong (doubled `fixmystreet`), nothing
actually resolves statically — everything relies on the `@catalyst`
fallback to the app. CSS/JS had that fallback (so `base.css` worked),
but the image block did not, so:

- `/cobrands/infrasignal/images/logo_web.png` → 404 (static miss, no fallback)
- `/photo/582.0.fp.jpeg` → 404 (these are **app-served** anyway, but the
  image block intercepted them and never proxied)

Verified the app serves both correctly when reached directly:
`curl localhost:3000/cobrands/infrasignal/images/logo_web.png` → 200.

### Fix

Added the same fallback the css/js block already uses:

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot|webp)$ {
    expires 30d;
    add_header Cache-Control "public";
    access_log off;
    try_files $uri @catalyst;     # <-- added
}
```

Applied with a live reload (no container recreate):

```bash
sudo docker exec staging-nginx-1 nginx -t        # syntax ok
sudo docker exec staging-nginx-1 nginx -s reload
```

`conf/nginx.conf-docker` is a tracked file — the edit is in
`/opt/infrasignal-v2` and mirrored to `/opt/infrasignal-dev` for commit.

I intentionally did **not** fix the doubled `root` path — the whole
site already works by falling back to `@catalyst`, and the one-line
fallback addition exactly matches the proven css/js behaviour. Changing
`root` would alter static-serving for everything and isn't needed.

---

## Cause 2: staging tree was missing most photo files

Photos are files named `<id>.<n>.<variant>.jpeg`. The dev rsync only
brought the ~20 files dev happened to have. Staging's DB (a prod copy)
references prod's photos, which live in prod's `web/photo` (86 files).

### Fix

```bash
sudo rsync -a /opt/infrasignal-v2/web/photo/ /opt/infrasignal-staging/web/photo/
# 86 -> 89 files in the staging tree
```

This is a host-only change to the generated staging tree (not in git),
same category as the rest of `/opt/infrasignal-staging`.

---

## Verification

```
staging logo       -> 200 image/png 92511b
staging favicon    -> 200
report 578 fp/full -> 200 / 200
report 579 fp/full -> 200 / 200
report 580 fp/full -> 200 / 404*
report 581 fp/full -> 200 / 404*
report 582 fp/full -> 200 / 200
home               -> 200

* 580/581 full-size files don't exist in prod either (source data gap
  for 2 reports). The fp thumbnails used in listings all load, so the
  homepage / reports list show images for all 5 photo'd reports.
```

All 5 thumbnails return real `image/jpeg` bytes (600–840 b — normal for
the small `fp` thumbnail variant).

---

## Notes / considerations

- **Real customer photos are now on staging.** They depict
  infrastructure problems (potholes, fallen branches). For a civic
  reporting demo this is the intended content, but be aware photos can
  incidentally contain PII (plates, faces, house numbers). Staging is
  non-public. If that's a concern for a specific demo, prune
  `/opt/infrasignal-staging/web/photo` to a curated set.
- **Re-sync caveat:** the photo copy must be redone whenever the staging
  tree is rebuilt from dev. Updated re-sync recipe:

  ```bash
  sudo rsync -a --delete --exclude='.git/' --exclude='local/' \
      --exclude='conf/general.yml-staging.runtime' --exclude='web/photo/' \
      /opt/infrasignal-dev/ /opt/infrasignal-staging/
  sudo rsync -a /opt/infrasignal-v2/web/photo/ /opt/infrasignal-staging/web/photo/
  ```

  (Excluding `web/photo/` from the dev rsync + syncing it from prod keeps
  the full photo set.)
- **Prod images:** this fix was to `nginx.conf-docker` (staging only).
  If prod ever shows the same broken-image symptom, check
  `nginx.conf-prod`'s image `location` block for the same missing
  fallback — but prod was not in scope here and was not touched.
