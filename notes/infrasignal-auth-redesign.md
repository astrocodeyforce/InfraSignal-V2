# InfraSignal Auth Redesign

Date: 2026-05-03
Verified first on: `/opt/infrasignal-dev`, `http://REDACTED-IP:3001/auth`

## Summary

The InfraSignal authentication pages were redesigned to match the Lovable reference while keeping FixMyStreet authentication behavior intact. The sign-in, create-account, forgot-password, and expired-password flows now use a joined split card with a blue brand panel and a compact white form panel.

## Changed Files

- `templates/web/infrasignal/auth/general.html`
  - Reworked sign-in markup into the split-card auth shell.
  - Preserved `/auth` form action, `username`, `password_sign_in`, `sign_in_by_password`, `sign_in_by_code`, `oauth_need_email`, `social_sign_in`, and Turnstile hooks.
  - Added the password visibility toggle button for `password_sign_in`.
- `templates/web/infrasignal/auth/create.html`
  - Reworked create, forgot, and expired-password states into the same split-card shell.
  - Preserved dynamic `/auth/create`, `/auth/forgot`, and `/auth/expired` form actions plus `password_register` and Turnstile hooks.
  - Added the password visibility toggle button for `password_register`.
- `web/cobrands/infrasignal/base.scss`
  - Added auth-page-only Lovable layout, form controls, validation states, button styling, and responsive split-card behavior.
  - Added an interactive dot canvas layer style for the brand panel while keeping the blue gradient panel as the base visual.
  - Fixed client-side validation placement so generated `.form-error` messages sit below inputs without shrinking or covering fields.
- `web/cobrands/fixmystreet/fixmystreet.js`
  - Added an auth password visibility toggle handler.
  - Added cursor-responsive dot motion for the auth brand panel.
  - Guarded mobile-nav setup when required legacy header elements are absent.
- `web/cobrands/infrasignal/base.css`
  - Compiled output from `bin/make_css`.

## Verification

- CSS compiled in dev with:
  - `docker exec infrasignal-dev-dev-fixmystreet-1 bash -c "cd /var/www/fixmystreet && rm -f web/cobrands/infrasignal/base.css && bin/make_css && find /var/www/fixmystreet/templates -name '*.ttc' -delete"`
- JavaScript syntax checked with:
  - `node --check web/cobrands/fixmystreet/fixmystreet.js`
- Browser verification confirmed:
  - `/auth` renders the split Lovable-style shell.
  - Empty magic-link validation appears below the email field without overlap.
  - Password eye toggles show and hide typed passwords on sign-in and create-account flows.
  - The blue panel dot layer responds to mouse movement.
  - `/auth/create` and `/auth/forgot` render correctly.

## Production Sync Notes

To sync this auth redesign to production, copy the changed auth templates, auth SCSS, shared JS, and this note to `/opt/infrasignal-v2`, compile production CSS, clear Template Toolkit cache, HUP Starman if needed, and verify `/auth`, `/auth/create`, and `/auth/forgot` on `https://infrasignal.org/`.