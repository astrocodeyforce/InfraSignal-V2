# InfraSignal Logo Configuration

## Current Mark

InfraSignal uses the inline header mark shown in the app header:

- A rounded gradient square containing `IS`
- Uppercase `INFRASIGNAL` wordmark text
- No bitmap logo image is required for the primary site header

The primary markup lives in `templates/web/infrasignal/header_site.html` and the fallback logo include in `templates/web/infrasignal/header_logo.html` should use the same structure:

```html
<a href="/" class="header-logo" title="InfraSignal">
   <span class="header-logo-icon" aria-hidden="true">IS</span>
   <span class="brand-text">INFRASIGNAL</span>
</a>
```

## CSS Styling

Logo styling is defined in `web/cobrands/infrasignal/base.scss`:

```scss
.header-logo {
   display: flex;
   align-items: center;
   gap: 8px;
   text-decoration: none;
   flex-shrink: 0;
}

.header-logo-icon {
   display: flex;
   align-items: center;
   justify-content: center;
   width: 36px;
   height: 36px;
   border-radius: 10px;
   background: linear-gradient(135deg, $primary-500, $accent-500);
   color: #fff;
   font-size: 14px;
   font-weight: 800;
}

.brand-text {
   color: #fff;
   font-size: 17px;
   font-weight: 700;
   letter-spacing: 0.1em;
}
```

## Legacy Path

Older `#site-logo-wrapper` / `#site-logo` image-based markup is intentionally hidden by the current header CSS and should not be used for InfraSignal's primary header. If a template include needs logo output, use `.header-logo` with `.header-logo-icon` and `.brand-text`.

## Build

- Compile CSS in production with:
   `docker exec docker-fixmystreet-1 bash -c "cd /var/www/fixmystreet && rm -f web/cobrands/infrasignal/base.css && bin/make_css"`
- Clear template cache after template edits with:
   `docker exec docker-fixmystreet-1 bash -c "find /var/www/fixmystreet/templates -name '*.ttc' -delete"`
