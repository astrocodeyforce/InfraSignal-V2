# InfraSignal Admin Dashboard Redesign

Date: 2026-05-07
Environment verified: `/opt/infrasignal-dev`, `http://REDACTED-IP:3001/admin`
Production status: not deployed; DEV only.

## Summary

The InfraSignal admin summary page was redesigned into a Lovable-style admin console while preserving the existing FixMyStreet admin functionality. The work included a new admin shell, permission-driven sidebar, KPI cards, chart/donut visuals, recent reports, responsive search forms, and a bounded reports-waiting table.

The dashboard metrics were also corrected. The original visual data was real, but it was derived from the rendered reports-waiting queue and the weekly chart was anchored to the newest queued report date. It now uses backend JSON generated from the report resultset, so the "last 7 days" chart means the current calendar last seven days.

## Changed Files

- `templates/web/infrasignal/admin/header.html`
  - Added an InfraSignal admin header override.
  - Keeps admin mode/sidebar behavior while allowing the custom dashboard to suppress the legacy duplicate page title.
- `templates/web/infrasignal/admin/navigation.html`
  - Added a Lovable-style admin sidebar.
  - Keeps navigation generated from `allowed_links` and `allowed_pages`, preserving permission-driven admin access.
- `templates/web/infrasignal/admin/index.html`
  - Reworked `/admin` into the new dashboard layout.
  - Preserved the existing report and user search form actions and field names.
  - Added `data-admin-dashboard` for backend JSON consumed by the dashboard JavaScript.
  - Changed recent reports to use `admin_recent_reports`.
  - Removed the legacy `clearfix` class from the search grid so pseudo-elements do not become grid items.
  - Wrapped the reports-waiting table in a bounded scrolling container.
- `perllib/FixMyStreet/App/Controller/Admin.pm`
  - Added `_admin_dashboard_json` to generate dashboard data server-side.
  - Added `admin_recent_reports` for newest submissions.
  - Added `admin_dashboard_json` to the admin stash.
- `web/cobrands/infrasignal/admin-dashboard.js`
  - Added dashboard visual rendering for the bar chart and category/status donuts.
  - Prefers backend JSON from `data-admin-dashboard`.
  - Keeps table-scraping behavior only as a fallback if backend JSON is unavailable.
- `templates/web/infrasignal/footer_extra_js.html`
  - Added the versioned `admin-dashboard.js` include.
- `web/cobrands/infrasignal/base.scss`
  - Added admin shell, sidebar, card, KPI, chart, donut, recent-report, search, and table styles.
  - Added responsive search and admin layout rules.
  - Added defensive `.admin-index-search::before` / `::after` suppression to avoid clearfix grid artifacts.
  - Added empty-bar styling so zero-count days render as a subtle baseline.
- `web/cobrands/infrasignal/base.css`
  - Rebuilt generated CSS from `base.scss`.

## Data Correctness

- `unsent_reports` is still the awaiting-send queue and remains the source for the "Awaiting send" KPI and the reports-waiting table.
- "Reports this week" now uses all cobrand reports created from current local today minus six days through today.
- Category donut uses all-report category totals.
- Status donut uses all-report lifecycle totals, mapping fixed states to `Fixed` and confirmed reports to `Open`.
- Recent reports now uses the latest reports ordered by `created DESC, id DESC`.
- Access now uses `c.cobrand.admin_allow_user(c.user)` instead of a static `Live` label.

## Verified DEV Data

Database checks on 2026-05-07 showed:

- Real current last-seven-day reports, May 1-May 7, 2026: `0`.
- Latest report created in DEV: `2026-04-09 06:00:00`.
- Awaiting-send queue total: `142`.
- All reports total: `582`.
- All-report statuses: `Fixed` 440, `Open` 142.
- Largest all-report categories:
  - `Pothole / Road Damage`: 149
  - `Sidewalk Damage`: 86
  - `Streetlight Outage`: 79
  - `Abandoned Vehicle`: 55
  - `Graffiti / Vandalism`: 49
- Newest recent reports verified on the dashboard: `#582`, `#581`, `#580`, `#579`.

## Verification Commands

- Admin controller syntax:
  - `docker exec infrasignal-dev-dev-fixmystreet-1 bash -c "cd /var/www/fixmystreet && perl -Ilocal/lib/perl5 -Icommonlib/perllib -Iperllib -c perllib/FixMyStreet/App/Controller/Admin.pm"`
- Dashboard JavaScript syntax:
  - `node --check /opt/infrasignal-dev/web/cobrands/infrasignal/admin-dashboard.js`
- CSS rebuild and template cache clear:
  - `docker exec infrasignal-dev-dev-fixmystreet-1 bash -c "cd /var/www/fixmystreet && rm -f web/cobrands/infrasignal/base.css && bin/make_css && find /var/www/fixmystreet/templates -name '*.ttc' -delete"`
- Controller reload:
  - `docker restart infrasignal-dev-dev-fixmystreet-1`
- Editor diagnostics:
  - No errors found in `Admin.pm`, admin `index.html`, `admin-dashboard.js`, or `base.scss`.

## Browser Verification

Live `/admin` verification on DEV confirmed:

- Page title: `InfraSignal`.
- No horizontal overflow at the tested narrow mobile viewport.
- `data-admin-dashboard` contains backend JSON.
- Bar chart shows May 1-May 7, 2026 with seven zero-count days.
- Category donut legend shows all-report percentages.
- Status donut legend shows `Fixed 76%` and `Open 24%`.
- Recent reports show newest submissions rather than the oldest awaiting-send queue rows.
- Reports waiting table still shows 142 queue rows and remains internally scrollable.

## Production Sync Notes

This work has only been applied to DEV. To sync later, copy the changed admin templates, `Admin.pm`, `admin-dashboard.js`, `base.scss`, generated `base.css`, and this note to `/opt/infrasignal-v2`, then compile production CSS, clear Template Toolkit cache, restart/HUP the production app if controller code changes are included, and verify `/admin` on production. Do not deploy this to production unless explicitly requested.

## May 10, 2026 Admin Polish Follow-Up

The DEV account/admin follow-up pushed as commit `a6d3a90f1` also improved admin body-picker contrast in the bodies, response priorities, site messages, and response templates pages, plus targeted role select styling in the InfraSignal SCSS. These changes are documented in `notes/infrasignal-account-dashboard.md` and `PROJECT PLAN/CHANGE_LOG.md`.
