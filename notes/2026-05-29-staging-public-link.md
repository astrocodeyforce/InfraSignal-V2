# Staging exposed on a public port (2026-05-29)

## What changed

Staging's nginx was bound to `127.0.0.1:8080` (server-localhost only), so it
had no public link. Changed the port binding to `0.0.0.0:8080` so it is
reachable like dev (`:3001`).

- File: `docker/docker-compose-staging.yml`
  - `- "127.0.0.1:8080:80"`  →  `- "0.0.0.0:8080:80"`
- Recreated **only** the `staging-nginx` container (DB + app untouched):
  ```
  cd /opt/infrasignal-v2/docker
  sudo docker compose -p staging -f docker-compose-staging.yml --env-file .env up -d nginx
  ```

## Result

**Public demo link: http://REDACTED-IP:8080/** (verified 200; seeded photos
load over the public IP).

## Notes

- The running compose file lives in the prod checkout
  (`/opt/infrasignal-v2/docker/`); the same edit is mirrored in the dev
  checkout (`/opt/infrasignal-dev/docker/`) so it is captured in git on `dev`.
- Staging is **open to anyone with the IP** — no auth. Fine for a demo (data
  was PII-scrubbed). To lock down later: HTTP basic-auth or IP allow-listing in
  `conf/nginx.conf-docker`, or front it behind the prod nginx with a
  `staging.` server_name + SSL.

## Promotion stays manual

dev → staging → prod is a one-way, human-initiated flow. No auto-sync.
Re-sync staging code with:

```
sudo rsync -a --delete --exclude='.git/' --exclude='local/' \
  --exclude='web/photo/' /opt/infrasignal-dev/ /opt/infrasignal-staging/
```
