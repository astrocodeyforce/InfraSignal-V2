# /report/new hero polish — 2026-05-29

## Summary

The `/report/new` page (the actual report-submission flow) was visually
incomplete — its form internals had been heavily branded over the
preceding sessions, but the page-level chrome (title, back link,
routing-note) still read as default FixMyStreet. Added a tight
~120-line block at the end of `web/cobrands/infrasignal/base.scss`
that fills in the missing hero band, back-pill, routing-note uplift,
and section-label polish. Rebuilt `base.css`. Verified live.

No template files were edited. CSS-only change.

---

## Why the previous edits were "not effective"

User reported: *"previously we have applied some code but not
effective currently. can you analyze and find out."*

### Diagnosis steps

1. **Hash check** — URL cache buster `?563e7720b735` matched
   `md5sum web/cobrands/infrasignal/base.css | cut -c1-12`. So the
   browser **was** receiving the latest CSS — not a stale-cache
   problem.

2. **Rule presence** — grep for `#report-a-problem-main` in the
   compiled CSS returned **88 occurrences** (from 43 source SCSS
   rules, ~400 lines at L12064-12482 of `base.scss`). Build was fine.

3. **Where the rules actually landed** — every one of those 43 rules
   targeted **form internals**:

   | Selector                                          | Targets             |
   |---------------------------------------------------|---------------------|
   | `input.form-control`, `textarea.form-control`     | text inputs         |
   | `.govuk-radios--small`, `.govuk-radios__label`    | category radios     |
   | `.dropzone`                                       | photo upload        |
   | `.description_tips .do/.dont`                     | checkmark tips      |
   | `.btn--oidc`, `#oidc_sign_in`                     | OAuth sign-in       |
   | `.floating-button`                                | sticky submit       |
   | `.form-section-heading`, `#form_category_legend`  | field labels        |

4. **What was missing** — page-level chrome. The h1 had only a plain
   text-styling rule (font-size, color) — no hero band. The
   `.problem-back--top` back link had **zero** custom styling. The
   `.report-routing-note` (the "will be sent to Manchester, NH"
   callout) had a 4-pixel left border that, in the rendered narrow
   sidebar, was visually subtle enough to look unstyled.

So the prior work was correct — it just stopped before the visible
"InfraSignal page hero" moment that all the other branded pages
(About, How It Works, Reports) have.

---

## What changed

### File: `web/cobrands/infrasignal/base.scss` (+121 lines, end of file)

Appended a single fenced block (clearly commented with date and
purpose) after the existing tail (`is-geo-matches__chev`). Source
order means these rules win against the older `> h1` rule at L12073
at the same specificity.

```
// =====================================================================
// InfraSignal — /report/new sidebar hero polish (added 2026-05-29)
// =====================================================================
```

Five additions:

1. **`#side-form` background reset** — drop the soft top-fade gradient
   so the new hero provides the top fill cleanly.
2. **`#report-a-problem-main` padding restructure** — kill horizontal
   padding on the container so the hero can bleed edge-to-edge;
   re-apply 16px padding to every form-body child that isn't the
   hero or the back-link.
3. **`.problem-back--top` back-pill** — turn the bare link into a
   branded navy pill with rounded corners, light-navy background,
   hover state.
4. **`> h1` hero band** — InfraSignal navy gradient
   (`$lv-primary` → `$primary-900`), white text, orange
   (`$accent-500`) bottom border, subtle box-shadow + text-shadow,
   and an inline SVG pin glyph (orange) as a `::before` pseudo.
5. **`.report-routing-note` uplift** — bump left border to 5px,
   strengthen the gradient with an orange-tinted second stop, bump
   type size, set `<strong>` to the deeper `$primary-900` for more
   contrast.
6. **Section labels uplift** — `#photo-upload-label`, `#title-label`,
   `#detail-label`, `#form_category_legend` get brand navy color,
   uppercase, 12.5px with 0.04em letter-spacing so they read as
   clear "section start" markers. `.optional/.required` suffixes
   stay normal-cased and muted.

### File: `web/cobrands/infrasignal/base.css` (rebuilt)

Built via the in-container `bin/make_css web/cobrands/infrasignal/`
(uses Perl `CSS::Sass`). Hash changed from `563e7720b735` to
`61d616c92162`. File size went from ~418 KB to **420,522 bytes**
(+ ~2 KB compressed).

No SCSS in any other section was touched. No `.css` file was edited
by hand.

---

## Variables used (all already in scope)

| Variable          | Value                              | Where used         |
|-------------------|------------------------------------|--------------------|
| `$lv-primary`     | `hsl(224, 71%, 40%)` (navy)        | hero, back-pill    |
| `$primary-900`    | `#0F2444`                          | hero gradient stop |
| `$lv-primary-fg`  | white                              | hero text          |
| `$accent-500`     | `#F97316` (orange)                 | hero accent, pin   |
| `$lv-primary-10`  | navy at 10% alpha                  | back-pill bg       |
| `$lv-primary-15`  | navy at 15% alpha                  | back-pill hover    |
| `$lv-shadow-sm`   | `0 1px 2px rgba(0,0,0,0.06)`       | hero               |
| `$lv-text-muted`  | `hsl(215, 16%, 47%)`               | optional suffix    |

No new variables added.

---

## Verification

```
==new h1 hero rule in built CSS==
body.mappage #report-a-problem-main>h1::before{
  content:""; display:inline-block; width:18px; height:22px;
  margin-right:10px; vertical-align:-4px;
  background:url('data:image/svg+xml;utf8,<svg xmlns=...>...</svg>')
    no-repeat center/contain
}

==new padding-restoration rule==
body.mappage #report-a-problem-main>*:not(h1):not(.problem-back--top){
  padding-left:16px; padding-right:16px
}

==live page now serves new hash==
base.css?61d616c92162

==stack health==
dev / -> 200
dev /report/new -> 200
prod (Host: infrasignal.org) -> 200
```

---

## What did NOT change

- **No template files were touched.** All work in CSS. The h1, back
  link, routing-note, and section labels were already rendered with
  the right selectors by FixMyStreet/InfraSignal base templates —
  they just lacked CSS.
- **`/report/new`'s map+sidebar layout is unchanged.** This is still
  a `body.mappage` split-view page, not the full-width hero layout
  of `/how-it-works` or `/about`. (That would require a much bigger
  template restructure and would break the address-on-map UX.)
- **Other pages unaffected.** Every selector is namespaced under
  `body.mappage #report-a-problem-main`, so the rules apply only on
  the report-form sidebar.
- **Prod & staging untouched.** Dev-only change. Will reach prod
  only via the next deliberate `bin/deploy` pass after these changes
  are committed and merged.

---

## Reversibility

### Revert just this change

```
cd /opt/infrasignal-dev
# Remove the appended block (last ~121 lines starting from the
# "// InfraSignal — /report/new sidebar hero polish" banner).
# Then:
sudo docker exec infrasignal-dev-dev-fixmystreet-1 \
  bash -c 'cd /var/www/fixmystreet && bin/make_css web/cobrands/infrasignal/'
```

The rebuild will regenerate `base.css` without the new rules.

### Revert via git (after this is committed)

```
git revert <commit-sha>
sudo docker exec infrasignal-dev-dev-fixmystreet-1 \
  bash -c 'cd /var/www/fixmystreet && bin/make_css web/cobrands/infrasignal/'
```

---

## Open / known issues

- **Visual approval still pending** as of writing. User asked for the
  page to look more like other branded pages; this is the first
  iteration. Tunable dials if they want adjustments:
    - Hero size — currently 24px title, 20px vertical padding.
    - Pin icon — drop the `::before` if it feels too playful.
    - Accent color — `$accent-500` (orange) on the hero bottom
      border; could go to `$lv-primary` (navy) for a quieter look.
    - Section labels — currently uppercase. Could revert to title
      case if "too shouty" is the feedback.
- **Mobile layout** — at narrow viewports (`only-map map-reporting`
  class) the sidebar takes the full width. The hero still works at
  full width; no special mobile rules were added. Worth a glance
  on a phone before declaring done.
- **Not yet committed.** Will go to `origin/dev` once the look is
  approved, following the same explicit-stage commit pattern as
  previous sessions (`git add base.scss base.css` only — leaving
  all other template/CSS WIP unstaged).
