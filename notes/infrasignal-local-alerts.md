# InfraSignal Local Alerts Page

Date: 2026-05-16
Environment: `/opt/infrasignal-dev`
Implementation commit: `b59adf8a1`
Production: not touched

## Summary

Updated the location-specific Local Alerts subscription page at `/alert/list` using the supplied design, adapted to the existing FixMyStreet alert controller and InfraSignal cobrand templates.

## Key Files

- `templates/web/infrasignal/alert/list.html` adds the InfraSignal-specific post-search Local Alerts wrapper.
- `templates/web/infrasignal/alert/_list.html` contains the existing alert subscription controls restyled as scope choices, email subscription, and RSS subscription.
- `templates/web/infrasignal/alert/index.html` remains the existing `/alert` search entry page.
- `web/cobrands/infrasignal/base.scss` contains the scoped alert-list styles.
- `web/cobrands/infrasignal/base.css` was regenerated from SCSS.

## Backend Compatibility

- The design was wired to the existing `POST /alert/subscribe` endpoint.
- Existing field names were preserved: `feed`, `distance`, `rznvy`, `alert`, `rss`, `token`, `type`, `pc`, `latitude`, and `longitude`.
- Per-option RSS links still use controller-supplied `rss_feed_uri` and `option.uri` values.
- No new Perl routes, database changes, or JavaScript were added.

## Verification

- `git diff --check` passed before the implementation commit.
- Editor diagnostics passed for the changed templates, SCSS, and generated CSS.
- Dev CSS rebuild completed with `bin/make_css`.
- Template Toolkit caches were cleared.
- `http://REDACTED-IP:3001/alert/list?pc=60089` returned HTTP 200 and rendered the title, nearby photos, scope chooser, email panel, and RSS action.
- `http://REDACTED-IP:3001/alert` returned HTTP 200 and kept the existing search page working.
- Browser verification confirmed the verification widget is contained inside the Subscribe by email panel.

## Notes

- Cloudflare Turnstile can show a connectivity/domain error on the DEV IP address. The widget is existing infrastructure and was only moved into the email panel for layout.
- The existing untracked backup file `templates/web/base/alert/index.html.bak` was not committed.

## Production Promotion

When approved for production, deploy from `/opt/infrasignal-v2` by pulling the DEV commit, rebuilding InfraSignal CSS, clearing Template Toolkit caches, and verifying `/alert` plus `/alert/list` on mobile and desktop.

## Follow-up Visual Polish

Date: 2026-05-16
Implementation commit: `527564122` (`Polish Local Alerts subscription page`)
Production: not touched

### Summary

Applied the newer enhanced Local Alerts design to `/alert/list`, keeping the existing alert controller, endpoint, and form field names intact.

### Changes

- Added a richer Local Alerts hero with location chip, alert-area meta panel, grid texture, and accent glow.
- Added category tags to real nearby report preview cards, with tagged fallback preview cards retained.
- Converted scope choices into clickable cards with selected-card styling and per-option RSS links.
- Moved the custom radius input inside the radius card and preserved the existing `distance` field.
- Reworked the email and RSS subscription actions into a responsive two-panel row.
- Added a nonce-bearing inline script to keep the selected card state synchronized with the radio buttons while ignoring clicks on per-option RSS links.
- Rebuilt `web/cobrands/infrasignal/base.css` and cleared Template Toolkit caches on DEV.

### Verification

- `git diff --check` passed before the implementation commit.
- Editor diagnostics passed for the changed templates, SCSS, and generated CSS.
- `/alert/list?pc=60089` returned HTTP 200 and served the hero chip, report tags, scope cards, email verification area, RSS panel, and card-selection script.
- `/alert` returned HTTP 200 after the shared alert style changes.
- Served form markup retained the required backend fields: `token`, `type`, `pc`, `latitude`, `longitude`, `feed`, `distance`, `rznvy`, `alert`, and `rss`.
- Browser screenshot verification confirmed the polished hero and tagged nearby-report preview layout.