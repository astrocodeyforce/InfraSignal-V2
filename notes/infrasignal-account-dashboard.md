# InfraSignal Account Dashboard and Admin Polish

Date: 2026-05-10
Environment verified: `/opt/infrasignal-dev`
Production status: not deployed; DEV only.
GitHub dev commit: `a6d3a90f1` (`Add account dashboard and admin style updates`)

## Summary

Older local account/admin changes were reviewed, cleaned, validated, documented, and pushed to GitHub `origin/dev`. The work adds an InfraSignal account dashboard, a change-name flow, admin body-picker contrast fixes, and matching SCSS/CSS.

## Changed Files

- `perllib/FixMyStreet/App/Controller/Auth/Profile.pm`
  - Added `/auth/change_name` handling.
  - Trims submitted names, validates required/maximum length, updates the user name, flashes success, and redirects back to `/my`.
- `templates/web/base/auth/change_name.html`
  - Added a base change-name template.
- `templates/web/infrasignal/auth/change_name.html`
  - Added the InfraSignal Lovable-style change-name template.
- `templates/web/infrasignal/my/my.html`
  - Added the InfraSignal account dashboard override.
  - Shows profile details, notification preferences, report history, updates, and a civic-impact card.
- `templates/web/infrasignal/admin/bodies/index.html`
- `templates/web/infrasignal/admin/responsepriorities/index.html`
- `templates/web/infrasignal/admin/sitemessage/index.html`
- `templates/web/infrasignal/admin/templates/index.html`
  - Improved table/header/body text contrast for admin body picker flows.
- `web/cobrands/infrasignal/base.scss`
  - Added simple auth-card support for profile editing.
  - Added account dashboard layout and responsive styles.
  - Added targeted admin role-select and body-picker readability fixes.
- `web/cobrands/infrasignal/base.css`
  - Rebuilt generated CSS from `base.scss`.
- `PROJECT PLAN/PROJECT_PLAN.md`
  - Updated current phase progress before the follow-up documentation pass.

## Verification

- Cleaned trailing whitespace and final newlines in the new templates/docs.
- Rebuilt dev InfraSignal CSS and cleared Template Toolkit cache.
- Syntax checked `Profile.pm` with app and commonlib include paths:
  - `docker exec infrasignal-dev-dev-fixmystreet-1 bash -c "cd /var/www/fixmystreet && perl -Ilocal/lib/perl5 -Icommonlib/perllib -Iperllib -c perllib/FixMyStreet/App/Controller/Auth/Profile.pm"`
- Editor diagnostics passed for changed docs, templates, controller, and SCSS.
- `git diff --check` passed for the staged change set.
- `t/template.t` passed.
- `t/app/controller/my.t` is blocked by an existing test DB schema gap: the test DB is missing `problem.osm_zone_*` columns from `db/schema_0094-priority-zones.sql`.

## Remaining Local File

- `templates/web/base/alert/index.html.bak` remains untracked and uncommitted because it is a backup file.

## Rollback Notes

- Revert commit `a6d3a90f1` on the `dev` branch.
- Rebuild `web/cobrands/infrasignal/base.css` from SCSS and clear Template Toolkit cache.
- Production is unchanged, so no production rollback is required for this DEV-only update.