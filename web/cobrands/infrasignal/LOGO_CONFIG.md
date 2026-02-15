# InfraSignal Logo Configuration

## Final Specifications

**Logo File**
- Path: `/opt/infrasignal-v2/web/cobrands/infrasignal/images/logo.png`
- Format: PNG (2.1MB, high-resolution)
- Aspect Ratio: Edge-to-edge design (no padding)
- Design: Unified pin graphic + text consolidated in single PNG

## CSS Styling

**Logo Wrapper (`#site-logo-wrapper`)** — holds the background image, NOT clickable
```scss
width: 550px;
height: 120px;
background-image: url('/cobrands/infrasignal/images/logo.png');
background-size: contain;
background-repeat: no-repeat;
background-position: left -35px;
pointer-events: none;
```

**Logo Link (`#site-logo`)** — only the logo graphic area is clickable
```scss
display: block;
width: 200px;
height: 100%;
background-image: none !important;
pointer-events: auto;
```

**Header Container (`#site-header`)**
```scss
height: 45px;
overflow: hidden;
padding: 0;
position: relative;
```

**Navigation (`#main-nav`)**
```scss
min-height: 1.5em;
```

## Display Behavior

- **Logo Display Size**: 550px wide × 120px tall (CSS dimensions)
- **Visible Area**: Top 45px of the 120px logo (header clips the rest)
- **Vertical Offset**: Logo shifted up by 35px (`background-position: left -35px`)
- **Visible Logo Height**: ~45px (clipped by header overflow)
- **Header Height**: 45px (compact, fixed)

## Layout Architecture

1. **Container Hierarchy**:
   - `#site-header` (45px fixed height, overflow hidden)
   - `#site-logo-wrapper` (550×120px, background image, non-clickable)
   - `#site-logo` (200px wide link, clickable — navigates to home)
   - `#main-nav` (1.5em min-height, flex layout)

2. **CSS Inheritance**:
   - Logo styling: Defined in `/opt/infrasignal-v2/web/cobrands/infrasignal/base.scss`
   - Header base styles: Inherited from `/opt/infrasignal-v2/web/cobrands/sass/_base.scss`
   - Layout rules: Inherited from `/opt/infrasignal-v2/web/cobrands/sass/_layout.scss`

3. **Compilation**:
   - Build tool: Docker container `docker_css_watcher_1`
   - Build command: `docker exec docker_css_watcher_1 bin/make_css`
   - Compiled output: `/opt/infrasignal-v2/web/cobrands/infrasignal/layout.css`

## Size Evolution (Session History)

| Width | Height | Offset | Status |
|-------|--------|--------|--------|
| 175px | 35px   | 0px    | Initial SVG logo |
| 175px | 50px   | 0px    | First PNG test |
| 280px | 70px   | 0px    | Increased |
| 350px | 100px  | 0px    | Too tall header |
| 400px | 55px   | 0px    | Header good, logo small |
| 380px | 90px   | 0px    | Compact design approved |
| 500px | 90px   | 0px    | Widened, kept height |
| 550px | 120px  | -30px  | Larger, moved up |
| 550px | 120px  | -35px  | Final (current) |

## Visual Result

- Logo appears **prominent and wider** (550px)
- Header remains **compact and slim** (45px fixed)
- Logo graphic is **visible but clipped**, showing top portion
- No header expansion despite large logo CSS dimensions

## Notes

- The 120px logo height is intentionally larger than the 45px header to create visual depth
- The -35px vertical offset positions the logo so the prominent graphic area appears in the visible header space
- `background-size: contain` ensures the full PNG scales proportionally without distortion
- The side navigation and menu items align below/around the compact header
- **Clickable area**: Only the left 200px (logo graphic) is clickable; the rest of the blue header is inert
- Template override: `templates/web/infrasignal/header_logo.html` wraps the logo link in a `#site-logo-wrapper` div
