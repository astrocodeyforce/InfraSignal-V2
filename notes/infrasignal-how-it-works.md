# InfraSignal How It Works Page

Date: 2026-05-12
Environment: `/opt/infrasignal-dev`
Implementation commit: `9c105e69a`
Production: not touched

## Summary

Created the new `/how-it-works` page from the user-provided Lovable HTML/SCSS, adapted to InfraSignal's existing FixMyStreet Template Toolkit and SCSS patterns.

## Key Files

- `perllib/FixMyStreet/App/Controller/Static.pm` adds the `/how-it-works` route and forwards to `/about/page` with `how-it-works`.
- `templates/web/infrasignal/about/how-it-works.html` contains the page content and inline SVG icon block.
- `templates/web/infrasignal/header_site.html` adds the main desktop and mobile navigation link.
- `templates/web/infrasignal/about/_sidebar.html` and visible info/contact templates add the sidebar link.
- `web/cobrands/infrasignal/base.scss` contains the `.hiw` component styles.
- `web/cobrands/infrasignal/base.css` was regenerated from SCSS.

## Content Included

- Hero: "How InfraSignal Works" with the requested subtext.
- Four-step process: Report, Locate, Route, Track.
- What happens after a report is submitted.
- Resident benefits and local-authority benefits.
- Tracking links for All Reports, Local Alerts, and account activity.
- Example journey for a broken streetlight.
- Frequently asked questions and final CTA.

## Verification

- `git diff --check` passed before commit.
- `Static.pm` syntax check passed inside the dev container.
- Dev CSS rebuild completed with `bin/make_css`.
- Template Toolkit caches were cleared.
- Browser verification confirmed `http://REDACTED-IP:3001/how-it-works` renders.
- `curl` verification returned HTTP 200 and found the required heading and four-step labels.

## Production Promotion

When approved for production, deploy from `/opt/infrasignal-v2` by pulling the DEV commit, rebuilding InfraSignal CSS, clearing Template Toolkit caches, and HUP/restarting the app for the new route.