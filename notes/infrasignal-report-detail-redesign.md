# InfraSignal Report Detail Redesign

Date: 2026-05-03
Environment first verified: `/opt/infrasignal-dev`, `http://REDACTED-IP:3001/report/551`

## Summary

The InfraSignal report detail sidebar was restyled to match the Lovable reference while keeping the implementation limited to cobrand CSS and JavaScript DOM enhancement. The page now uses a structured report header, category/status badges, a separate photo section, a details grid, a timeline-style status block, compact update/auth sections, and a transparent bottom action bar that sits at the end of the sidebar content.

## Changed Files

- `web/cobrands/infrasignal/base.scss`
  - Lovable-style report detail layout, status/timeline/details/update/form styles.
  - Dedicated report photo section and custom photo lightbox styling.
  - Map/sidebar alignment fixes to remove the blue gap between sidebar and map.
  - Static bottom action bar styling and removal of the trailing `#map_sidebar::after` spacer.
- `web/cobrands/infrasignal/filter-pills.js`
  - Existing filter pill behavior plus report detail DOM enhancements.
  - Injects header wrappers, badges, details grid, timeline markup, update restructuring, step labels, and bottom action label normalization.
  - Adds same-page photo lightbox behavior instead of navigating to the raw image.
- `web/cobrands/infrasignal/_colours.scss`
  - Adds neutral tokens used by the expanded InfraSignal SCSS.
- `web/cobrands/infrasignal/base.css`
  - Compiled output from `bin/make_css`.
- `templates/web/infrasignal/footer_extra_js.html`
  - Ensures `filter-pills.js` is loaded for the InfraSignal cobrand.

## Verification

- JavaScript syntax checked with:
  - `node --check /opt/infrasignal-dev/web/cobrands/infrasignal/filter-pills.js`
- Dev CSS compiled with:
  - `docker exec infrasignal-dev-dev-fixmystreet-1 bash -c "cd /var/www/fixmystreet && rm -f web/cobrands/infrasignal/base.css && bin/make_css"`
- Browser verification on `/report/551` confirmed:
  - report photo no longer stretches the header;
  - photo opens in an in-page overlay;
  - upload, textarea, and auth card widths align;
  - sidebar and map touch cleanly with no blue gutter;
  - bottom action bar is transparent/static and no longer overlaps while scrolling;
  - page ends immediately after the bottom action bar with no trailing spacer.

## Production Sync Notes

To move this change to production, sync the changed source files to `/opt/infrasignal-v2`, compile CSS in `docker-fixmystreet-1`, and verify the production report page renders the same report detail classes (`rpt-photo-section`, `rpt-photo-lightbox`, `rpt-details-grid`, `stl`, and static `.shadow-wrap`).