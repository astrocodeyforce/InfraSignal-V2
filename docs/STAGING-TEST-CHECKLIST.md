# InfraSignal — Staging Test Checklist & Go/No-Go Gate

## Overview

This document covers the **visual/manual browser checks** that complement
the automated harness (`bin/staging-acceptance.py`).  Together they form
the pre-production gate.

**Staging URL:** `http://REDACTED-IP:8080`

**Important:** Staging is accessed by **IP and port 8080**, not `https://staging.infrasignal.org`
(that hostname has no DNS). `conf/general.yml-staging.runtime` must set `BASE_URL` to
`http://REDACTED-IP:8080`, and hero/report forms must use **relative** paths (`/around`)
so reporting works even if BASE_URL is wrong.

---

## 1. Prerequisites

- [ ] The automated harness passes: `python3 bin/staging-acceptance.py`
      (exit code 0, report file `staging-test-report.txt` shows 0 FAIL).
- [ ] Staging containers are running:
      `staging-fixmystreet-1`, `staging-nginx-1`, `staging-db-1`, `staging-memcached-1`.
- [ ] You have a superuser login (see DB users:
      `docker exec staging-db-1 psql -U postgres -d infrasignal -tAc
       "SELECT email FROM users WHERE is_superuser = true LIMIT 1"`).

---

## 2. Automated Harness — Runbook

```bash
cd /opt/infrasignal-dev

# Run all suites
python3 bin/staging-acceptance.py

# Run specific suites only
python3 bin/staging-acceptance.py --suite A,B,D

# Custom base URL
python3 bin/staging-acceptance.py --base http://REDACTED-IP:8080

# With explicit superuser credentials (optional — falls back to DB token)
STAGING_SU_EMAIL="sarah.williams@example.com" \
STAGING_SU_PASS="yourpassword" \
python3 bin/staging-acceptance.py
```

### Triage instructions (for cheaper model)

1. Run `python3 bin/staging-acceptance.py`.
2. Read `staging-test-report.txt`.
3. For each `[FAIL]`, re-run that single suite: `--suite X`.
4. Inspect the failure detail.  If it says "got 502", wait 30s and retry
   (staging may be cold-starting).
5. Classify each failure as **real regression** or **flake/config**.
6. File results in `staging-test-report.md` with Go/No-Go.

---

## 3. Visual / Browser Checklist

Open staging in a browser.  Test at **desktop (1280px+)** and **mobile (375px)**.
Capture a screenshot for each item.

### 3.1 Homepage Hero — start reporting (all languages)

- [ ] On `http://REDACTED-IP:8080`, type an address (e.g. `buffalo`) and click the orange
      **Report** button — browser stays on `:8080`, URL becomes `/around?...` (not
      `staging.infrasignal.org`).
- [ ] `/?lang=en-gb` — hero search button reads "Report an Issue", fully visible.
- [ ] `/?lang=ru` — button reads "Сообщить о проблеме", **no clipping**.
- [ ] `/?lang=es` — button reads "Reportar un Problema", **no clipping**.
- [ ] `/?lang=tr` — button reads "Sorun Bildir", **no clipping**.
- [ ] The search input yields space to the button (not the other way around).

### 3.2 Navigation Bar (all languages, desktop)

- [ ] `/?lang=en-gb` — "Home | How It Works | For Government | Security | Admin"
      all visible, nothing clipped or pushed off-screen.
- [ ] `/?lang=ru` — nav labels shortened, "Admin" button still visible and clickable.
- [ ] `/?lang=tr` — same check.
- [ ] `/?lang=es` — same check.
- [ ] Resize browser from 1400px → 960px: nav compresses gracefully via `clamp()`,
      no label wraps to a second line, "Admin" never disappears.

### 3.3 Language Switchers (all three locations)

- [ ] **Header dropdown** (desktop): click flag → opens portal → click "ES" →
      page reloads in Spanish, URL stays on `:8080`, port preserved.
- [ ] **Footer pills** (scroll to bottom): click "Русский" → page loads Russian,
      URL stays on `:8080`.
- [ ] **Mobile menu** (resize to mobile or use devtools): open hamburger →
      tap "TR" → page reloads Turkish, port preserved.
- [ ] After switching to Turkish, switch back to English via footer → works.

### 3.4 Admin Body Edit Form

- [ ] Log in as superuser → `/admin/bodies` → select a state → click a body.
- [ ] On the edit form: **Parent**, **Cobrand**, **Area covered**, **Send Method**
      dropdowns are fully visible (no text clipping in selects).
- [ ] All form fields fit within the card, no horizontal overflow.

### 3.5 Full Report Submission (UI)

- [ ] Go to homepage → enter an address → click "Report an Issue".
- [ ] On `/report/new`: select "Pothole / Road Damage" category.
- [ ] Auto-fill populates title and detail text.
- [ ] Upload a photo → preview thumbnail appears.
- [ ] Fill name/email → Submit.
- [ ] Confirmation page appears with the report number.
- [ ] Navigate to `/report/{id}` → photo is visible and matches the uploaded file.

### 3.6 Reports Page — Photos & Logos

- [ ] `/reports` — InfraSignal logo renders (not broken image).
- [ ] Report cards show thumbnails (not broken images).
- [ ] Individual report pages show full-size photos.
- [ ] On `/report/524`, click the report photo. The lightbox close `x` is anchored to
      the **top-right corner of the photo itself**, not floating elsewhere in the overlay.
      Check at desktop and mobile widths.

### 3.6a Report Detail — Same Data In Every Language

- [ ] Open `/report/524?lang=en-gb`, `/report/524?lang=es`, and `/report/524?lang=tr`.
- [ ] Ref, authority, report date, source, timeline completion, and official-response
      author are the **same underlying data** in every language. Only labels should
      translate.
- [ ] Specifically verify: ref `524`, authority `Buffalo Grove, IL`, status resolved/fixed,
      and the update author `Buffalo Grove, IL`.
- [ ] This guards against using translated display text as JavaScript logic. Report detail
      enhancements must read stable `data-*` attributes/classes/API fields, not words like
      `Fixed`, `Responsible Authority`, or `Posted by`.

### 3.6b Report Update Photo Uploader

- [ ] On `/report/524?lang=tr`, scroll to **Güncellemeye izin ver**.
- [ ] Photo upload shows the styled Dropzone area (`Drag photos here or choose photos` style),
      not raw browser `Choose File` inputs.
- [ ] If raw file inputs appear, hard refresh once. If they still appear, treat as NO-GO:
      the Dropzone initializer missed the asynchronously loaded report sidebar.

### 3.7 Marketing Pages (non-English)

- [ ] `/about?lang=ru` — full Russian content, no "About Us" English leak.
- [ ] `/about/privacy?lang=tr` — full Turkish legal text, not English.
- [ ] `/about/terms?lang=es` — full Spanish legal text.
- [ ] `/faq?lang=ru` — Russian FAQ, categories listed.
- [ ] `/alert?lang=tr` — Turkish alerts page.

### 3.8 Admin Sidebar (non-English)

- [ ] `/admin?lang=ru` — sidebar shows "Дубликаты отчётов" and "Приоритетные зоны"
      (not English "Duplicate Reports" / "Priority Zones").
- [ ] `/admin?lang=tr` — sidebar shows Turkish equivalents.

### 3.9 Admin Navigation Speed

- [ ] Click "Bodies" → "Users" → "Roles" → "Templates" in the admin sidebar.
- [ ] Each page loads in under 3 seconds (no multi-second stalls).
- [ ] No browser tab freeze.

---

## 4. Go / No-Go Gate

**GO** requires **all** of the following:

1. `staging-test-report.txt` shows **0 FAIL** (exit code 0).
2. Every visual checklist item above is checked off with a screenshot.
3. No critical UI breakage observed outside the checklist.

**NO-GO** if any of the following:

- Any harness `[FAIL]` that is confirmed as a real regression.
- Any visual checklist item fails.
- The staging environment is unreachable or unstable (repeated 502s).

### On NO-GO

1. Fix the issue on the **dev** environment first.
2. Push to `origin/dev`.
3. Sync changed files to `/opt/infrasignal-staging` (copy files + recompile `.mo`
   + rebuild `base.css` + restart `staging-fixmystreet-1`).
4. Rerun the harness + visual checklist.
5. Repeat until GO.

---

## 5. Post-Promotion Production Smoke

After promoting to production, run a minimal smoke:

```bash
python3 bin/staging-acceptance.py --base https://infrasignal.org --suite A,B,D
```

This checks health, public pages, and language switching on the live site
without touching admin or creating test reports.
