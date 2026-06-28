# InfraSignal Logo Configuration

## Current Header Logo

InfraSignal uses the image-based pin + wordmark logo in the app header. Do not replace it with generated text, the old `IS` mark, or the base FixMyStreet `#site-logo` wrapper.

The current assets are:

- `web/cobrands/infrasignal/images/logo.png` - high-resolution source/current mark, 1536x1024 PNG.
- `web/cobrands/infrasignal/images/logo_web.png` - optimized header asset, 800x269 PNG.
- Both PNGs have the right-hand `Signal` wordmark recolored to light slate (`#F1F5F9`) so it remains readable on the dark navy site header while keeping the pin and orange `Infra` mark intact.

The primary markup lives in `templates/web/infrasignal/header_site.html`. The fallback logo include in `templates/web/infrasignal/header_logo.html` should use the same structure:

```html
<a href="[% c.cobrand.base_url IF admin %]/" class="header-logo" title="[% site_name %]">
   <img src="[% version('/cobrands/infrasignal/images/logo_web.png') %]" class="header-logo-image" alt="[% site_name %]">
</a>
```

Always use the Template Toolkit `version()` helper for `logo_web.png`. It cache-busts the image URL when the PNG changes, so browsers do not keep showing an older logo after the file is replaced.

## CSS Styling

Logo styling is defined in `web/cobrands/infrasignal/base.scss`:

```scss
.header-logo {
    display: flex;
    align-items: center;
    text-decoration: none;
    flex-shrink: 0;
    width: 190px;
    height: 45px;

    @media (min-width: 640px) { width: 235px; }
    @media (min-width: 1024px) { width: 275px; }
}

.header-logo-image {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: contain;
    object-position: left center;
}
```

This keeps the wordmark 45px tall while scaling the width from 190px on small screens to 275px on desktop.

## Icon Files

The browser/favicon and PWA icon files are:

- `web/cobrands/infrasignal/favicon.ico` - active browser tab icon, loaded by `templates/web/base/common_header_tags.html`.
- `web/cobrands/infrasignal/images/favicon.ico` - duplicate/reference favicon copy.
- `web/cobrands/infrasignal/images/192.png`
- `web/cobrands/infrasignal/images/512.png`
- `web/cobrands/infrasignal/images/apple-touch-icon.png`
- Production theme copies: `web/theme/infrasignal/192.png` and `web/theme/infrasignal/512.png`

## Legacy Header Paths

Do not use `.header-logo-icon`, `.brand-text`, `#site-logo-wrapper`, or `#site-logo` for the current InfraSignal header. The old `#site-logo-wrapper` / `#site-logo` markup is hidden by the current header CSS for compatibility only.

If a template include needs logo output, use `.header-logo` with `.header-logo-image` and the versioned `logo_web.png` URL shown above.

## Updating Logo Assets

- Make source changes in `web/cobrands/infrasignal/images/logo.png` first.
- Regenerate or update `web/cobrands/infrasignal/images/logo_web.png` from the source asset for header use.
- Keep the right-hand `Signal` wordmark at `#F1F5F9` for contrast on the dark header.
- Keep the header template URL wrapped in `version()`.
- Clear Template Toolkit cache after template edits.
- Recompile CSS only if `base.scss` changes.

## Build and Cache Commands

- Compile CSS in dev with:
   `docker exec infrasignal-dev-dev-fixmystreet-1 bash -c "cd /var/www/fixmystreet && rm -f web/cobrands/infrasignal/base.css && bin/make_css"`
- Compile CSS in production with:
   `docker exec docker-fixmystreet-1 bash -c "cd /var/www/fixmystreet && rm -f web/cobrands/infrasignal/base.css && bin/make_css"`
- Clear dev template cache after template edits with:
   `docker exec infrasignal-dev-dev-fixmystreet-1 bash -c "find /var/www/fixmystreet/templates -name '*.ttc' -delete"`
- Clear production template cache after template edits with:
   `docker exec docker-fixmystreet-1 bash -c "find /var/www/fixmystreet/templates -name '*.ttc' -delete"`
