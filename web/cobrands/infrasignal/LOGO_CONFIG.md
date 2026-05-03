# InfraSignal Logo Configuration

## Current Mark

InfraSignal uses the pin + wordmark image logo in the app header. The optimized web asset is:

- `web/cobrands/infrasignal/images/logo_web.png` — 800x269 PNG, displayed at up to 275x45 in the header
- The `Signal` wordmark uses light slate (`#F1F5F9`) so it remains readable on the dark navy site header.

The primary markup lives in `templates/web/infrasignal/header_site.html` and the fallback logo include in `templates/web/infrasignal/header_logo.html` should use the same structure:

```html
<a href="/" class="header-logo" title="InfraSignal">
   <img src="/cobrands/infrasignal/images/logo_web.png" class="header-logo-image" alt="InfraSignal">
</a>
```

## CSS Styling

Logo styling is defined in `web/cobrands/infrasignal/base.scss`:

```scss
.header-logo {
   display: flex;
   align-items: center;
   text-decoration: none;
   flex-shrink: 0;
   width: 275px;
   height: 45px;
}

.header-logo-image {
   display: block;
   width: 100%;
   height: 100%;
   object-fit: contain;
   object-position: left center;
}
```

## Icon Files

The browser/favicon and PWA icon files are:

- `web/cobrands/infrasignal/favicon.ico`
- `web/cobrands/infrasignal/images/favicon.ico`
- `web/cobrands/infrasignal/images/192.png`
- `web/cobrands/infrasignal/images/512.png`
- `web/cobrands/infrasignal/images/apple-touch-icon.png`
- Production theme copies: `web/theme/infrasignal/192.png` and `web/theme/infrasignal/512.png`

Older `#site-logo-wrapper` / `#site-logo` markup is hidden by the current header CSS and should not be used for InfraSignal's primary header. If a template include needs logo output, use `.header-logo` with `.header-logo-image`.

## Build

- Compile CSS in production with:
   `docker exec docker-fixmystreet-1 bash -c "cd /var/www/fixmystreet && rm -f web/cobrands/infrasignal/base.css && bin/make_css"`
- Clear template cache after template edits with:
   `docker exec docker-fixmystreet-1 bash -c "find /var/www/fixmystreet/templates -name '*.ttc' -delete"`
