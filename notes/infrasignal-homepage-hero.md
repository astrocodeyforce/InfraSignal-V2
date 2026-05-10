# InfraSignal Homepage Hero Refresh

Date: 2026-05-10
Environment verified: `/opt/infrasignal-dev`, `http://REDACTED-IP:3001/`
Production status: not deployed; DEV only.
GitHub dev commit: `9af1462f0` (`Update homepage hero copy`)

## Summary

The InfraSignal homepage hero now uses the requested reporting-focused copy and a clearer primary call to action. The search field was widened and adjusted so the full `Enter your address or zipcode` placeholder remains visible beside the longer `Report an Issue` button.

## Changed Files

- `templates/web/infrasignal/around/intro.html`
  - Added an InfraSignal-specific homepage intro override.
  - Headline: `Report issues. Improve your neighborhood with Infrasignal.`
  - Subtext: `Residents report problems. Local authorities fix them. Track everything.`
- `templates/web/infrasignal/around/postcode_form.html`
  - Updated the hidden label, placeholder, and aria-label to `Enter your address or zipcode`.
  - Changed the submit button to `Report an Issue`.
- `web/cobrands/infrasignal/base.scss`
  - Increased the homepage search pill width.
  - Adjusted text input flex behavior, min width, and padding.
  - Added a small-screen fallback for input and CTA sizing.
- `web/cobrands/infrasignal/base.css`
  - Rebuilt generated CSS from `base.scss`.

## Verification

- Rebuilt CSS and cleared Template Toolkit cache in the dev container:
  - `docker exec infrasignal-dev-dev-fixmystreet-1 bash -c "cd /var/www/fixmystreet && rm -f web/cobrands/infrasignal/base.css && bin/make_css && find templates -name '*.ttc' -delete"`
- Browser verification confirmed:
  - The new headline and subtext render on the dev homepage.
  - The textbox exposes `Enter your address or zipcode`.
  - The CTA renders as `Report an Issue`.
  - The final `e` in `zipcode` is visible beside the CTA.
- Editor diagnostics and `git diff --check` passed for the touched files.

## Rollback Notes

- Revert commit `9af1462f0` on the `dev` branch.
- Rebuild `web/cobrands/infrasignal/base.css` from SCSS and clear Template Toolkit cache.
- Production is unchanged, so no production rollback is required for this DEV-only update.