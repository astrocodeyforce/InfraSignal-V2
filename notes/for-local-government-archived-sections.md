# Archived sections — `/about/for-local-government`

**Status:** ARCHIVED / not currently shown. The page currently uses a simple, plain
sentence instead (see "Current state" below).

**Why archived:** The 2026-06 website accuracy & compliance pass
(`INFRASIGNAL_WEBSITE_FIX_INSTRUCTIONS.md`, §3.1–§3.2) required removing borrowed
performance metrics, council quotes, and unverifiable badges from this page,
because showing other organisations' results/adoption figures on InfraSignal's own
page implies outcomes InfraSignal has not achieved.

**Why this doc exists:** The owner may want to bring these back later. Everything
needed to restore them — exact markup, placement, CSS status, and the easiest
one-command restore — is captured here so it can be re-added quickly and exactly.

- Template file: `templates/web/infrasignal/about/for-local-government.html`
- The full original (with everything below) is preserved in git at commit
  **`97066e7a4`** (and any earlier commit). Quick retrieval:
  ```bash
  git show 97066e7a4:templates/web/infrasignal/about/for-local-government.html > /tmp/flg-original.html
  ```

---

## Current state (KEEP AS-IS unless asked to restore)

The "Model" section is now just two plain paragraphs, no cards, no numbers:

```html
        <section class="gov-section-card">
          <span class="gov-eyebrow">[% loc('Model') %]</span>
          <h2 class="gov-section-card__title">[% loc('An established civic-reporting model') %]</h2>
          <div class="gov-section-card__body">
            <p>[% loc('InfraSignal follows a public reporting pattern already used by civic reporting services internationally: residents submit location-based reports, agencies receive structured intake, and communities can follow public updates over time.') %]</p>
            <p>[% loc('Similar civic-reporting services include FixMyStreet and SocietyWorks (United Kingdom), FixaMinGata (Sweden), and Z&uuml;ri wie neu (Switzerland). They are referenced only as background on the model &mdash; not as InfraSignal customers or endorsements.') %]</p>
          </div>
        </section>
```

The trust strip currently reads:

```html
        <div class="gov-trust-strip">
          <div class="gov-trust-strip__label">[% loc('Built for government') %]</div>
          <div class="gov-trust-strip__row">
            <span class="gov-trust-badge">[% INCLUDE gov_icon name='shield' %] [% loc('Accessibility-minded') %]</span>
            <span class="gov-trust-badge">[% INCLUDE gov_icon name='shield' %] [% loc('Privacy-conscious &middot; CCPA-aware') %]</span>
            <span class="gov-trust-badge">[% INCLUDE gov_icon name='code' %] [% loc('Open311 v2') %]</span>
            <span class="gov-trust-badge">[% INCLUDE gov_icon name='globe' %] [% loc('4 languages') %]</span>
          </div>
        </div>
```

### Important notes about the current file
- The **carousel JavaScript is still present** at the bottom of the file (the
  `<script>` block that queries `[data-gov-quotes-carousel]`). It is harmless —
  it's guarded by `if (!root) { return; }`, so with the carousel HTML removed it
  simply no-ops. **This means restoring section B below needs only the HTML; the
  JS is already in place.**
- **All CSS is still present** in `web/cobrands/infrasignal/base.scss` (classes
  `gov-ref-grid`, `gov-ref-card*`, `gov-quotes*`, `gov-quote-card*`). No SCSS work
  is needed to restore — the markup will render styled immediately.

---

## EASIEST restore (recommended)

The whole original page is in git. To bring back **everything** exactly:

```bash
cd /opt/infrasignal-dev
git show 97066e7a4:templates/web/infrasignal/about/for-local-government.html \
  > templates/web/infrasignal/about/for-local-government.html
# then sync to staging/prod per the usual rsync recipe
```

If you only want **some** of it back, use the targeted blocks below instead.

---

## A. Reference-services grid (the "linked cities" cards)

**Placement:** inside the "Model" `<section class="gov-section-card">`, replacing the
second `<p>` ("Similar civic-reporting services include…"). Goes right after the
first paragraph, inside `<div class="gov-section-card__body">`.

To restore: in the current "Model" section, replace this line —

```html
            <p>[% loc('Similar civic-reporting services include FixMyStreet and SocietyWorks (United Kingdom), FixaMinGata (Sweden), and Z&uuml;ri wie neu (Switzerland). They are referenced only as background on the model &mdash; not as InfraSignal customers or endorsements.') %]</p>
```

— with this block:

```html
            <p>[% loc('These examples are included as reference points for the wider civic reporting model, not as InfraSignal customers or endorsements.') %]</p>

            <div class="gov-ref-grid">
              <a href="https://www.zueriwieneu.ch/" class="gov-ref-card" target="_blank" rel="noopener noreferrer">
                <span class="gov-ref-card__country"><span aria-hidden="true">&#127464;&#127469;</span> [% loc('Switzerland') %]</span>
                <h3 class="gov-ref-card__name">Z&uuml;ri wie neu</h3>
                <p class="gov-ref-card__desc">[% loc('City infrastructure reporting service for Z&uuml;rich.') %]</p>
                <div class="gov-ref-card__foot"><span class="gov-ref-card__stat">[% loc('City-wide &middot; since 2013') %]</span><span class="gov-ref-card__cta">[% loc('Visit') %] &#8599;</span></div>
              </a>
              <a href="https://www.fixamingata.se/" class="gov-ref-card" target="_blank" rel="noopener noreferrer">
                <span class="gov-ref-card__country"><span aria-hidden="true">&#127480;&#127466;</span> [% loc('Sweden') %]</span>
                <h3 class="gov-ref-card__name">FixaMinGata</h3>
                <p class="gov-ref-card__desc">[% loc('National local issue reporting service for Sweden.') %]</p>
                <div class="gov-ref-card__foot"><span class="gov-ref-card__stat">[% loc('National &middot; 290 cities') %]</span><span class="gov-ref-card__cta">[% loc('Visit') %] &#8599;</span></div>
              </a>
              <a href="https://www.societyworks.org/case-studies/" class="gov-ref-card" target="_blank" rel="noopener noreferrer">
                <span class="gov-ref-card__country"><span aria-hidden="true">&#127468;&#127463;</span> [% loc('United Kingdom') %]</span>
                <h3 class="gov-ref-card__name">[% loc('SocietyWorks') %]</h3>
                <p class="gov-ref-card__desc">[% loc('Public-sector civic reporting deployments and integrations.') %]</p>
                <div class="gov-ref-card__foot"><span class="gov-ref-card__stat">[% loc('30+ UK councils live') %]</span><span class="gov-ref-card__cta">[% loc('Visit') %] &#8599;</span></div>
              </a>
            </div>
```

**Compliance note:** the stat lines (`30+ UK councils live`, `National &middot; 290
cities`, `City-wide &middot; since 2013`) are other services' figures. If you want a
compliant version, drop the `<span class="gov-ref-card__stat">…</span>` from each
`__foot` and keep only the `Visit` link.

---

## B. Council quotes carousel (borrowed case-study quotes + metrics)

**Placement:** as its own `<section>`, immediately **before** the
`<div class="gov-trust-strip">` near the bottom of the content (after the last
`gov-section-card`). The driving JS is already in the file (see note above).

```html
        <section class="gov-quotes" aria-label="[% loc('Council references') %]" data-gov-quotes-carousel>
          <div class="gov-quotes__head">
            <span class="gov-chip gov-chip--accent">[% loc('Public-sector proof points') %]</span>
            <span class="gov-quotes__hint">[% loc('Short excerpts and published outcomes from real SocietyWorks case studies.') %]</span>
          </div>
          <div class="gov-quotes__wrap">
            <span class="gov-quotes__fade gov-quotes__fade--left" aria-hidden="true"></span>
            <span class="gov-quotes__fade gov-quotes__fade--right" aria-hidden="true"></span>
            <div class="gov-quotes__scroller" data-gov-quotes-scroller tabindex="0" aria-label="[% loc('Council reference quotes') %]">
              <article class="gov-quotes__slide" data-gov-quote-slide><div class="gov-quote-card"><span class="gov-quote-card__mark" aria-hidden="true">&ldquo;</span><div class="gov-quote-card__top"><span class="gov-chip gov-chip--primary gov-chip--xs">[% loc('Public adoption') %]</span><span class="gov-quote-card__metric">[% loc('92% resolution rate shown') %]</span></div><blockquote>[% loc('&ldquo;It has been a resounding success.&rdquo;') %]</blockquote><p class="gov-quote-card__context">[% loc('Northumberland used public updates, asset mapping, and workflow messages to handle heavy drainage demand more clearly.') %]</p><div class="gov-quote-card__foot"><div class="gov-quote-card__name">Northumberland County Council</div><a href="https://www.societyworks.org/case-studies/northumberland-county-council/" target="_blank" rel="noopener noreferrer">[% loc('Read the case study') %] &#8599;</a></div></div></article>
              <article class="gov-quotes__slide" data-gov-quote-slide><div class="gov-quote-card"><span class="gov-quote-card__mark" aria-hidden="true">&ldquo;</span><div class="gov-quote-card__top"><span class="gov-chip gov-chip--primary gov-chip--xs">[% loc('Channel shift') %]</span><span class="gov-quote-card__metric">[% loc('+45% online reporting') %]</span></div><blockquote>[% loc('&ldquo;a catalyst for change.&rdquo;') %]</blockquote><p class="gov-quote-card__context">[% loc('Gloucestershire saw a 45% increase in online reporting within four months while improving transparency for residents.') %]</p><div class="gov-quote-card__foot"><div class="gov-quote-card__name">Gloucestershire County Council</div><a href="https://www.societyworks.org/case-studies/gloucestershire-county-council/" target="_blank" rel="noopener noreferrer">[% loc('Read the case study') %] &#8599;</a></div></div></article>
              <article class="gov-quotes__slide" data-gov-quote-slide><div class="gov-quote-card"><span class="gov-quote-card__mark" aria-hidden="true">&ldquo;</span><div class="gov-quote-card__top"><span class="gov-chip gov-chip--primary gov-chip--xs">[% loc('Scale') %]</span><span class="gov-quote-card__metric">[% loc('200,000+ updates each year') %]</span></div><blockquote>[% loc('&ldquo;Members of the public are choosing to use the platform...&rdquo;') %]</blockquote><p class="gov-quote-card__context">[% loc('Lincolnshire reports around 80% online reporting and automatic status updates at county scale.') %]</p><div class="gov-quote-card__foot"><div class="gov-quote-card__name">Lincolnshire County Council</div><a href="https://www.societyworks.org/case-studies/lincolnshire-county-council/" target="_blank" rel="noopener noreferrer">[% loc('Read the case study') %] &#8599;</a></div></div></article>
              <article class="gov-quotes__slide" data-gov-quote-slide><div class="gov-quote-card"><span class="gov-quote-card__mark" aria-hidden="true">&ldquo;</span><div class="gov-quote-card__top"><span class="gov-chip gov-chip--primary gov-chip--xs">[% loc('Resident experience') %]</span><span class="gov-quote-card__metric">[% loc('-24% reporting costs') %]</span></div><blockquote>[% loc('&ldquo;easier, faster to use, and more interactive&rdquo;') %]</blockquote><p class="gov-quote-card__context">[% loc('Central Bedfordshire reported a 46% increase in online reports and a 24% reduction in reporting costs.') %]</p><div class="gov-quote-card__foot"><div class="gov-quote-card__name">Central Bedfordshire Council</div><a href="https://www.societyworks.org/case-studies/central-bedfordshire-council/" target="_blank" rel="noopener noreferrer">[% loc('Read the case study') %] &#8599;</a></div></div></article>
              <article class="gov-quotes__slide" data-gov-quote-slide><div class="gov-quote-card"><span class="gov-quote-card__mark" aria-hidden="true">&ldquo;</span><div class="gov-quote-card__top"><span class="gov-chip gov-chip--primary gov-chip--xs">[% loc('Smart routing') %]</span><span class="gov-quote-card__metric">[% loc('Fewer irrelevant reports') %]</span></div><blockquote>[% loc('&ldquo;simple for the user, but deal with some complex routing behind the scenes&rdquo;') %]</blockquote><p class="gov-quote-card__context">[% loc('Transport for London uses smart routing so residents do not need to know which body owns each street asset.') %]</p><div class="gov-quote-card__foot"><div class="gov-quote-card__name">Transport for London</div><a href="https://www.societyworks.org/case-studies/transport-for-london/" target="_blank" rel="noopener noreferrer">[% loc('Read the case study') %] &#8599;</a></div></div></article>
              <article class="gov-quotes__slide" data-gov-quote-slide><div class="gov-quote-card gov-quote-card--result"><div class="gov-quote-card__top"><span class="gov-chip gov-chip--primary gov-chip--xs">[% loc('Cost efficiency') %]</span><span class="gov-quote-card__metric">[% loc('99.5% fewer duplicates') %]</span></div><p class="gov-quote-card__proof">[% loc('Up to 98.69% savings per report.') %]</p><p class="gov-quote-card__context">[% loc('Buckinghamshire reported fewer calls, fewer emails, fewer duplicate reports, and lower handling costs.') %]</p><div class="gov-quote-card__foot"><div class="gov-quote-card__name">Buckinghamshire Council</div><a href="https://www.societyworks.org/case-studies/buckinghamshire/" target="_blank" rel="noopener noreferrer">[% loc('Read the case study') %] &#8599;</a></div></div></article>
            </div>
          </div>
          <div class="gov-quotes__controls">
            <button type="button" class="gov-quotes__btn" data-gov-quotes-prev aria-label="[% loc('Previous quote') %]">[% INCLUDE gov_icon name='chevron-left' %]</button>
            <div class="gov-quotes__dots" role="tablist" aria-label="[% loc('Quote slides') %]">
              <button type="button" class="gov-quotes__dot is-active" data-gov-quotes-dot aria-label="[% loc('Go to quote 1') %]" aria-current="true"></button>
              <button type="button" class="gov-quotes__dot" data-gov-quotes-dot aria-label="[% loc('Go to quote 2') %]"></button>
              <button type="button" class="gov-quotes__dot" data-gov-quotes-dot aria-label="[% loc('Go to quote 3') %]"></button>
              <button type="button" class="gov-quotes__dot" data-gov-quotes-dot aria-label="[% loc('Go to quote 4') %]"></button>
              <button type="button" class="gov-quotes__dot" data-gov-quotes-dot aria-label="[% loc('Go to quote 5') %]"></button>
              <button type="button" class="gov-quotes__dot" data-gov-quotes-dot aria-label="[% loc('Go to quote 6') %]"></button>
            </div>
            <button type="button" class="gov-quotes__btn" data-gov-quotes-next aria-label="[% loc('Next quote') %]">[% INCLUDE gov_icon name='chevron-right' %]</button>
          </div>
          <p class="gov-quotes__disclaimer">[% loc('Short quote excerpts and published figures from publicly available SocietyWorks case studies, shown as reference points for the civic reporting model. These councils are not InfraSignal customers or endorsers.') %]</p>
        </section>
```

---

## C. Original trust badges (if you also want those back)

Current badges are `Accessibility-minded` / `Privacy-conscious &middot; CCPA-aware`.
The original (pre-compliance) badges were:

```html
            <span class="gov-trust-badge">[% INCLUDE gov_icon name='shield' %] [% loc('WCAG 2.1 AA') %]</span>
            <span class="gov-trust-badge">[% INCLUDE gov_icon name='shield' %] [% loc('SOC 2-ready') %]</span>
            <span class="gov-trust-badge">[% INCLUDE gov_icon name='shield' %] [% loc('GDPR-aligned') %]</span>
```

**Compliance note:** `SOC 2-ready` and `GDPR-aligned` were removed as unverifiable
(no SOC 2 attestation exists; GDPR is an EU regime). Only restore these if they
become true and verifiable.

---

## D. Translations

These archived strings are English `loc()` keys. The Spanish/Russian/Turkish `.po`
catalogs (`locale/{es,ru_RU,tr_TR}.UTF-8/LC_MESSAGES/FixMyStreet.po`) may still
contain (or may need) translations for them. If restoring for non-English display,
verify the relevant `msgid`s exist and re-run `commonlib`/`msgfmt` to rebuild `.mo`.
Untranslated strings fall back to the English text, so English will always render.

## E. Restore checklist
1. Add block A (and/or B, C) into `for-local-government.html` at the noted spots —
   or just `git show 97066e7a4:…` the whole file for an exact restore.
2. No SCSS/CSS changes needed (classes still in `base.scss`/`base.css`).
3. No JS changes needed for the carousel (script already present, currently dormant).
4. Clear `*.ttc` template cache for the staging/prod tree, restart app, flush memcached.
5. `curl` the page in en/es/ru/tr and confirm 200 + the cards/quotes render.
