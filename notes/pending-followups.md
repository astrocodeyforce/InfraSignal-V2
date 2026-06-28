# Pending follow-ups / reminders

Running list of deferred items the owner asked to revisit later.

---

## 1. Re-add creator GitHub link in footer  (deferred 2026-06-23)

**What:** The footer creator credit currently shows plain text:
`Created and engineered by Mansur Islamov` (link removed on owner's request, "add later").

**File:** `templates/web/infrasignal/front/footer-marketing.html` (the
`site-footer__attribution` block, the second `<p>`).

**To restore the link**, change:

```html
            <p>[% loc('Created and engineered by') %] Mansur Islamov</p>
```

back to:

```html
            <p>[% loc('Created and engineered by') %] <a href="https://github.com/astrocodeyforce" target="_blank" rel="noopener noreferrer">Mansur Islamov</a></p>
```

(Confirm the exact profile URL with the owner before re-adding.)

**Note:** The **"Source code"** repo link in the same block was also removed — see #2.

---

## 2. Re-add "Source code" repo link in footer (AGPL §13)  (deferred 2026-06-23)

**What:** The footer "Source code" link was removed on owner's request ("add later").
The AGPL attribution sentence (FixMyStreet / mySociety / GNU AGPL v3) is still shown;
only the repo link was taken out.

**File:** `templates/web/infrasignal/front/footer-marketing.html` (the
`site-footer__attribution` block, first `<p>`).

**To restore the link**, change:

```html
            <p>[% loc('InfraSignal is built on <a href="https://fixmystreet.org" target="_blank" rel="noopener noreferrer">FixMyStreet</a>, open-source software by <a href="https://www.mysociety.org" target="_blank" rel="noopener noreferrer">mySociety</a>, and is distributed under the <a href="https://www.gnu.org/licenses/agpl-3.0.html" target="_blank" rel="noopener noreferrer">GNU AGPL v3</a>.') %]</p>
```

back to:

```html
            <p>[% loc('InfraSignal is built on <a href="https://fixmystreet.org" target="_blank" rel="noopener noreferrer">FixMyStreet</a>, open-source software by <a href="https://www.mysociety.org" target="_blank" rel="noopener noreferrer">mySociety</a>, and is distributed under the <a href="https://www.gnu.org/licenses/agpl-3.0.html" target="_blank" rel="noopener noreferrer">GNU AGPL v3</a>.') %]
               <a href="https://github.com/astrocodeyforce/InfraSignal-V2/tree/main" target="_blank" rel="noopener noreferrer">[% loc('Source code') %]</a></p>
```

**Before re-adding (AGPL §13 requirement):** confirm the public repo's `main` actually
matches what's deployed, and run a secret scan on it (no leaked secrets/config).
Until then, leave the link out.
