# Geolocation Button - HTTPS Requirement

## Issue
The "Use my location" button (`#geolocate_link`) appears briefly on page load and then **disappears completely** after refresh.

## Root Cause
Browser geolocation API requires **HTTPS** for security. The JavaScript check in [web/js/geolocation.js](web/js/geolocation.js#L33) explicitly validates:

```javascript
var https = window.location.protocol.toLowerCase() === 'https:';
if ('geolocation' in navigator && https && window.addEventListener) {
    // Show button and enable geolocation
} else {
    link.style.display = 'none';  // Hide button if not HTTPS
}
```

## Current Status
- **Server**: running on `http://76.13.107.54:3000` (HTTP, not HTTPS)
- **Result**: Button is hidden by JS after page loads
- **Behavior**: Button flashes briefly (cache/render) then disappears when JS executes

## Solution
**Enable HTTPS on the server.**

Once HTTPS is configured:
1. Condition `https === 'https:'` becomes `true`
2. Button remains visible
3. Geolocation API is accessible
4. Users can click "Use my location" to auto-populate coordinates in the report form

## Button Details
- **HTML ID**: `#geolocate_link`
- **Type**: Anchor (`<a>`) tag / button
- **Function**: Triggers browser geolocation to get user's lat/lon and pre-fill location field
- **CSS**: Styled in [web/cobrands/sass/_base.scss](web/cobrands/sass/_base.scss#L2910)
- **JavaScript**: Handler in [web/js/geolocation.js](web/js/geolocation.js)

## Production Notes
- Geolocation with HTTPS + high accuracy timeout is 10 seconds
- Falls back gracefully if user denies permission or geolocation unavailable
- Requires `addEventListener` support (modern browsers)
- Not shown if JS is disabled (`.no-js #geolocate_link { display: none; }`)
