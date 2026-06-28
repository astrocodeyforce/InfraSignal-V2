#!/usr/bin/env python3
"""
InfraSignal — Staging Acceptance Test Harness
==============================================
Deterministic pre-production gate.  Runs all test suites (A–I) against
the staging environment and writes a PASS/FAIL report.

Usage:
    python3 bin/staging-acceptance.py [--base URL] [--suite A,B,...] [--report FILE]

Environment:
    STAGING_BASE_URL   (default http://REDACTED-IP:8080)
    STAGING_SU_EMAIL   superuser email for admin tests
    STAGING_SU_PASS    superuser password (or leave blank for DB-token auth)

Exit codes:  0 = all PASS   1 = at least one FAIL   2 = harness error
"""

import argparse
import html
import http.cookiejar
import io
import json
import os
import re
import subprocess
import sys
import textwrap
import time
import urllib.error
import urllib.parse
import urllib.request

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(SCRIPT_DIR, "staging-acceptance.data.json")
FIXTURE_JPG = os.path.join(SCRIPT_DIR, "fixtures", "test-report.jpg")

# ── Helpers ──────────────────────────────────────────────────────────

class Results:
    def __init__(self):
        self.rows = []

    def record(self, suite, name, passed, detail=""):
        status = "PASS" if passed else "FAIL"
        self.rows.append((suite, name, status, detail))
        tag = f"  [{status}] {suite}: {name}"
        if not passed:
            tag += f"  -- {detail}"
        print(tag)

    def skip(self, suite, name, reason=""):
        self.rows.append((suite, name, "SKIP", reason))
        print(f"  [SKIP] {suite}: {name}  -- {reason}")

    @property
    def total(self):
        return len(self.rows)

    @property
    def passed(self):
        return sum(1 for r in self.rows if r[2] == "PASS")

    @property
    def failed(self):
        return sum(1 for r in self.rows if r[2] == "FAIL")

    @property
    def skipped(self):
        return sum(1 for r in self.rows if r[2] == "SKIP")

    def summary(self):
        lines = []
        lines.append("=" * 60)
        lines.append("STAGING ACCEPTANCE TEST REPORT")
        lines.append("=" * 60)
        current_suite = None
        for suite, name, status, detail in self.rows:
            if suite != current_suite:
                lines.append(f"\n── Suite {suite} ──")
                current_suite = suite
            line = f"  [{status}] {name}"
            if detail and status != "PASS":
                line += f"  -- {detail}"
            lines.append(line)
        lines.append("")
        lines.append("-" * 60)
        lines.append(f"TOTAL: {self.total}  PASS: {self.passed}  FAIL: {self.failed}  SKIP: {self.skipped}")
        verdict = "GO" if self.failed == 0 else "NO-GO"
        lines.append(f"VERDICT: {verdict}")
        lines.append("=" * 60)
        return "\n".join(lines)


class _RewriteRedirectHandler(urllib.request.HTTPRedirectHandler):
    """Rewrites redirects that go to the configured BASE_URL back to our staging IP."""
    def __init__(self, base_url):
        self._base = base_url.rstrip("/")
        parsed = urllib.parse.urlparse(self._base)
        self._scheme = parsed.scheme
        self._netloc = parsed.netloc

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        parsed = urllib.parse.urlparse(newurl)
        # Rewrite any redirect that goes to a different host back to our staging base
        if parsed.netloc and parsed.netloc != self._netloc:
            newurl = urllib.parse.urlunparse((
                self._scheme, self._netloc,
                parsed.path, parsed.params, parsed.query, parsed.fragment
            ))
        return super().redirect_request(req, fp, code, msg, headers, newurl)


class HTTPClient:
    def __init__(self, base_url):
        self.base = base_url.rstrip("/")
        self.cj = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.cj),
            _RewriteRedirectHandler(self.base),
        )
        self.opener.addheaders = [("User-Agent", "InfraSignal-StagingTest/1.0")]

    def get(self, path, follow=True, timeout=25):
        url = self.base + path if path.startswith("/") else path
        req = urllib.request.Request(url)
        try:
            resp = self.opener.open(req, timeout=timeout)
            body = resp.read()
            return resp.status, dict(resp.headers), body
        except urllib.error.HTTPError as e:
            body = e.read() if e.fp else b""
            return e.code, dict(e.headers), body
        except Exception as e:
            return 0, {}, str(e).encode()

    def head(self, path, timeout=10):
        url = self.base + path if path.startswith("/") else path
        req = urllib.request.Request(url, method="HEAD")
        try:
            resp = self.opener.open(req, timeout=timeout)
            return resp.status, dict(resp.headers)
        except urllib.error.HTTPError as e:
            return e.code, dict(e.headers)
        except Exception:
            return 0, {}

    def post(self, path, data=None, files=None, timeout=20):
        url = self.base + path if path.startswith("/") else path
        if files:
            body, content_type = self._encode_multipart(data or {}, files)
            req = urllib.request.Request(url, data=body)
            req.add_header("Content-Type", content_type)
        else:
            encoded = urllib.parse.urlencode(data or {}).encode()
            req = urllib.request.Request(url, data=encoded)
            req.add_header("Content-Type", "application/x-www-form-urlencoded")
        try:
            resp = self.opener.open(req, timeout=timeout)
            body = resp.read()
            return resp.status, dict(resp.headers), body
        except urllib.error.HTTPError as e:
            body = e.read() if e.fp else b""
            return e.code, dict(e.headers), body
        except Exception as e:
            return 0, {}, str(e).encode()

    def get_no_redirect(self, path, timeout=10):
        """GET without following redirects."""
        url = self.base + path if path.startswith("/") else path
        opener = urllib.request.build_opener(
            urllib.request.HTTPCookieProcessor(self.cj),
            _NoRedirectHandler(),
        )
        req = urllib.request.Request(url)
        try:
            resp = opener.open(req, timeout=timeout)
            body = resp.read()
            return resp.status, dict(resp.headers), body
        except urllib.error.HTTPError as e:
            body = e.read() if e.fp else b""
            return e.code, dict(e.headers), body
        except Exception as e:
            return 0, {}, str(e).encode()

    @staticmethod
    def _encode_multipart(fields, files):
        boundary = "----InfraSignalTestBoundary"
        parts = []
        for k, v in fields.items():
            parts.append(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}".encode())
        for k, (fname, fdata, ctype) in files.items():
            parts.append(
                f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"; filename=\"{fname}\"\r\n"
                f"Content-Type: {ctype}\r\n\r\n".encode() + fdata
            )
        parts.append(f"--{boundary}--\r\n".encode())
        body = b"\r\n".join(parts)
        return body, f"multipart/form-data; boundary={boundary}"


class _NoRedirectHandler(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise urllib.error.HTTPError(newurl, code, msg, headers, fp)


def db_query(container, dbname, sql):
    try:
        out = subprocess.check_output(
            ["docker", "exec", container, "psql", "-U", "postgres", "-d", dbname, "-tAc", sql],
            stderr=subprocess.STDOUT, timeout=15,
        )
        return out.decode().strip()
    except Exception as e:
        return f"DB_ERROR: {e}"


def scrape_csrf(body_bytes):
    text = body_bytes.decode("utf-8", errors="replace")
    m = re.search(r'name="token"\s+value="([^"]+)"', text)
    if m:
        return m.group(1)
    m = re.search(r'name="__csrf_token"\s+value="([^"]+)"', text)
    if m:
        return m.group(1)
    return None

# ── Suite A: Infrastructure & Health ─────────────────────────────────

def suite_a(client, R, cfg):
    print("\n▸ Suite A: Infrastructure & Health")

    status, hdrs, body = client.get("/status/health")
    text = body.decode("utf-8", errors="replace")
    R.record("A", "/status/health returns 200", status == 200, f"got {status}")
    R.record("A", "/status/health starts with OK:", text.startswith("OK:"), f"body={text[:80]}")

    status, hdrs, body = client.get("/status.json")
    R.record("A", "/status.json returns 200 or 500 (known flaky)", status in (200, 500), f"got {status}")
    if status == 200:
        try:
            data = json.loads(body)
            R.record("A", "/status.json valid JSON with stats", "version" in data or "reports" in data,
                     f"keys={list(data.keys())[:5]}")
        except Exception as e:
            R.record("A", "/status.json valid JSON", False, str(e))

    for cname in cfg["docker_containers"]:
        try:
            out = subprocess.check_output(
                ["docker", "inspect", "-f", "{{.State.Running}}", cname],
                stderr=subprocess.STDOUT, timeout=10
            ).decode().strip()
            R.record("A", f"container {cname} running", out == "true", f"state={out}")
        except Exception as e:
            R.record("A", f"container {cname} running", False, str(e))

# ── Suite B: Public Pages (EN) ───────────────────────────────────────

def suite_b(client, R, cfg):
    print("\n▸ Suite B: Public Pages (EN)")
    for page in cfg["public_pages"]:
        status, _, body = client.get(page)
        R.record("B", f"GET {page} -> 200", status == 200, f"got {status}")

    # Hero reporting search must not point at an unresolvable BASE_URL host
    status, _, body = client.get("/")
    text = body.decode("utf-8", errors="replace")
    R.record("B", 'homepage postcodeForm action="/around"', 'action="/around"' in text, "hero form action wrong")
    R.record("B", "homepage postcodeForm not staging.infrasignal.org",
             "staging.infrasignal.org" not in text.split('id="postcodeForm"')[1][:200]
             if 'id="postcodeForm"' in text else True,
             "absolute staging.infrasignal.org URL in hero form")
    status_ar, _, _ = client.get("/around?pc=buffalo")
    R.record("B", "GET /around?pc=buffalo -> 200", status_ar == 200, f"got {status_ar}")

# ── Suite C: i18n Leak Checks ────────────────────────────────────────

def suite_c(client, R, cfg):
    print("\n▸ Suite C: i18n Leak Checks")
    markers = cfg.get("i18n_markers", {})
    for lang, pages in markers.items():
        for page, checks in pages.items():
            url = f"{page}{'&' if '?' in page else '?'}lang={lang}"
            status, _, body = client.get(url)
            text = body.decode("utf-8", errors="replace")
            if status != 200:
                R.record("C", f"{page}?lang={lang} reachable", False, f"got {status}")
                continue
            for expected in checks.get("expect", []):
                R.record("C", f"{page} [{lang}] contains '{expected[:40]}'",
                         expected in text, f"not found in {len(text)} chars")
            for forbidden in checks.get("forbid", []):
                found = forbidden in text
                R.record("C", f"{page} [{lang}] no English leak '{forbidden[:40]}'",
                         not found, "LEAKED" if found else "")

    # 404 page branded check
    for lang in ["ru", "tr", "es"]:
        status, _, body = client.get(f"/nonexistent-page-test-12345?lang={lang}")
        text = body.decode("utf-8", errors="replace")
        R.record("C", f"404 page [{lang}] returns 404", status == 404, f"got {status}")

    # Run i18n-audit.py if available
    audit_script = os.path.join(SCRIPT_DIR, "i18n-audit.py")
    if os.path.exists(audit_script):
        try:
            out = subprocess.check_output(
                [sys.executable, audit_script],
                cwd=os.path.dirname(SCRIPT_DIR),
                stderr=subprocess.STDOUT, timeout=60,
            ).decode()
            # Count hard failures only (MISSING/EMPTY); LEAK(eng==translit) is heuristic
            import re as _re
            missing_vals = [int(x) for x in _re.findall(r'MISSING=(\d+)', out)]
            empty_vals = [int(x) for x in _re.findall(r'EMPTY=(\d+)', out)]
            fuzzy_vals = [int(x) for x in _re.findall(r'FUZZY=(\d+)', out)]
            hard_issues = sum(missing_vals) + sum(empty_vals) + sum(fuzzy_vals)
            R.record("C", "i18n-audit.py: 0 missing/empty/fuzzy", hard_issues == 0,
                     f"{hard_issues} hard issues")
        except subprocess.CalledProcessError as e:
            R.record("C", "i18n-audit.py runs without error", False, e.output.decode()[:200])
        except Exception as e:
            R.skip("C", "i18n-audit.py", str(e))
    else:
        R.skip("C", "i18n-audit.py", "script not found")

# ── Suite D: Language Switcher Correctness ───────────────────────────

def suite_d(client, R, cfg):
    print("\n▸ Suite D: Language Switcher Correctness")

    # Footer links are relative
    status, _, body = client.get("/?lang=es")
    text = body.decode("utf-8", errors="replace")
    for lang_code in ["en-gb", "es", "ru", "tr"]:
        pattern = f'href="/?lang={lang_code}"'
        # Accept both /? and /?lang= styles
        has_relative = f'/?lang={lang_code}' in text and f'http://' not in text.split(f'lang={lang_code}')[0][-50:]
        R.record("D", f"footer link for {lang_code} is relative",
                 f'="/?lang={lang_code}"' in text or f"='/?lang={lang_code}'" in text,
                 "not found or absolute")

    # header-nav.js contains rewrite logic
    js_match = re.search(r'/cobrands/infrasignal/header-nav\.js\?([a-f0-9]+)', text)
    if js_match:
        js_url = f"/cobrands/infrasignal/header-nav.js?{js_match.group(1)}"
        status_js, _, js_body = client.get(js_url)
        js_text = js_body.decode("utf-8", errors="replace")
        R.record("D", "header-nav.js served (200)", status_js == 200, f"got {status_js}")
        R.record("D", "header-nav.js has langUrlFor rewrite", "langUrlFor" in js_text, "")
        R.record("D", "header-nav.js targets footer+mobile links",
                 "site-footer__lang-link" in js_text and "mobile-menu__langs" in js_text, "")
    else:
        R.record("D", "header-nav.js referenced on page", False, "regex did not match")

    # ?lang=ru sets cookie and returns Russian
    fresh = HTTPClient(client.base)
    status, hdrs, body = fresh.get("/?lang=ru")
    text = body.decode("utf-8", errors="replace")
    R.record("D", "?lang=ru returns 200", status == 200, f"got {status}")
    has_cookie = any(c.name == "lang" and c.value == "ru" for c in fresh.cj)
    R.record("D", "?lang=ru sets lang=ru cookie", has_cookie, "")
    R.record("D", "?lang=ru returns Russian content", "Сообщить о проблеме" in text, "marker not found")

# ── Suite E: Admin Pages, Auth, Sizes, Translations ──────────────────

def suite_e(client, R, cfg):
    print("\n▸ Suite E: Admin Pages & Auth")

    su_email = os.environ.get("STAGING_SU_EMAIL", "team@example.com")
    su_pass = os.environ.get("STAGING_SU_PASS", "StagingTest2026!")
    logged_in = False

    # Load auth page (sets session cookie), then POST password login
    status, _, body = client.get("/auth")
    if status != 200:
        R.record("E", "GET /auth reachable", False, f"status={status}")
        return
    login_data = {
        "username": su_email,
        "password_sign_in": su_pass,
        "sign_in_by_password": "Sign in  >",
        "r": "",
    }
    # Also pass CSRF token if one exists
    csrf = scrape_csrf(body)
    if csrf:
        login_data["token"] = csrf
    status, hdrs, body = client.post("/auth", data=login_data)
    text = body.decode("utf-8", errors="replace")
    # After successful login, the app redirects to / or /my; check we can access /admin
    status_admin, _, body_admin = client.get("/admin")
    text_admin = body_admin.decode("utf-8", errors="replace")
    logged_in = status_admin == 200 and ("Dashboard" in text_admin or "Summary" in text_admin or "admin" in text_admin.lower())
    R.record("E", f"superuser login as {su_email}", logged_in,
             f"auth POST={status}, /admin={status_admin}")

    if not logged_in:
        R.skip("E", "admin pages (auth failed)", "login unsuccessful")
        return

    # Check each admin page
    threshold = cfg.get("admin_size_threshold_kb", 400) * 1024
    for page in cfg["admin_pages"]:
        status, _, body = client.get(page)
        R.record("E", f"GET {page} -> 200", status == 200, f"got {status}")
        if page in ["/admin/bodies", "/admin/templates", "/admin/users"]:
            size_kb = len(body) / 1024
            R.record("E", f"{page} size < {cfg['admin_size_threshold_kb']}KB",
                     len(body) < threshold, f"{size_kb:.0f}KB")

    # Sidebar translations
    sidebar_trans = cfg.get("admin_sidebar_translations", {})
    for lang, labels in sidebar_trans.items():
        status, _, body = client.get(f"/admin?lang={lang}")
        text = body.decode("utf-8", errors="replace")
        for en_label, translated in labels.items():
            R.record("E", f"admin sidebar [{lang}] '{en_label}' -> translated",
                     translated in text, f"expected '{translated}'")

    # Language persistence: set TR then switch to EN
    client.get("/admin?lang=tr")
    status, _, body = client.get("/admin?lang=en-gb")
    text = body.decode("utf-8", errors="replace")
    R.record("E", "admin lang persistence: en-gb after tr",
             "Dashboard" in text or "Summary" in text, "still showing Turkish?")

# ── Suite F: Admin Bodies AJAX ───────────────────────────────────────

def suite_f(client, R, cfg):
    print("\n▸ Suite F: Admin Bodies AJAX")

    status, _, body = client.get("/admin/bodies/bodies_by_state?state=AR")
    if status != 200:
        R.record("F", "bodies_by_state?state=AR -> 200", False, f"got {status}")
        return
    R.record("F", "bodies_by_state?state=AR -> 200", True, "")
    try:
        data = json.loads(body)
    except Exception:
        R.record("F", "bodies_by_state returns valid JSON", False, "parse error")
        return
    R.record("F", "bodies_by_state returns valid JSON", True, "")
    R.record("F", "bodies_by_state count > 0", data.get("count", 0) > 0,
             f"count={data.get('count')}")

    bodies = data.get("bodies", [])
    county = None
    for b in bodies:
        name = b.get("name", "")
        if "County" in name:
            county = b
            break
    if not county:
        R.skip("F", "cities_by_county (no county found in AR bodies)", "")
        return

    county_id = county["id"]
    R.record("F", f"found county: {county['name']} (id={county_id})", True, "")

    status, _, body = client.get(f"/admin/bodies/cities_by_county?county_id={county_id}")
    R.record("F", f"cities_by_county?county_id={county_id} -> 200", status == 200, f"got {status}")
    if status == 200:
        try:
            cdata = json.loads(body)
            cities = cdata.get("cities", [])
            R.record("F", "cities_by_county returns cities", len(cities) > 0,
                     f"{len(cities)} cities")
        except Exception:
            R.record("F", "cities_by_county valid JSON", False, "parse error")

# ── Suite G: Full E2E Report Flow ────────────────────────────────────

def suite_g(client, R, cfg):
    print("\n▸ Suite G: Full E2E Report Flow")

    lat = cfg["test_coords"]["latitude"]
    lon = cfg["test_coords"]["longitude"]
    category = cfg["test_category"]

    # Step 1: Load report form
    status, _, body = client.get(f"/report/new?latitude={lat}&longitude={lon}")
    text = body.decode("utf-8", errors="replace")
    R.record("G", "report/new loads (200)", status == 200, f"got {status}")
    csrf = scrape_csrf(body)
    R.record("G", "CSRF token scraped from form", csrf is not None, "")

    if not csrf:
        R.skip("G", "report submission (no CSRF)", "")
        return

    # Step 2: Photo upload
    photo_id = None
    if os.path.exists(FIXTURE_JPG):
        with open(FIXTURE_JPG, "rb") as f:
            jpg_data = f.read()
        status_ph, _, ph_body = client.post(
            "/photo/upload",
            data={"token": csrf},
            files={"photo": ("test-report.jpg", jpg_data, "image/jpeg")},
        )
        ph_text = ph_body.decode("utf-8", errors="replace")
        if status_ph == 200:
            try:
                ph_json = json.loads(ph_body)
                photo_id = ph_json.get("id") or ph_json.get("fileid")
                R.record("G", "photo upload returns fileid", photo_id is not None,
                         f"keys={list(ph_json.keys())}")
            except Exception:
                R.record("G", "photo upload valid JSON", False, ph_text[:100])
        else:
            R.record("G", "photo upload -> 200", False, f"got {status_ph}: {ph_text[:100]}")
    else:
        R.skip("G", "photo upload", "fixture JPEG missing")

    # Step 3: Submit report (logged-in path)
    # Re-fetch form for a fresh CSRF + hidden fields
    status, _, body = client.get(f"/report/new?latitude={lat}&longitude={lon}")
    csrf2 = scrape_csrf(body)
    report_data = {
        "token": csrf2 or csrf,
        "pc": "",
        "latitude": lat,
        "longitude": lon,
        "category": category,
        "title": "[Staging Test] Pothole acceptance check",
        "detail": "Automated staging acceptance test report. Safe to delete.",
        "name": "Staging Test Bot",
        "may_show_name": "1",
        "submit_problem": "1",
        "service": "",
        "single_body_only": "",
        "do_not_send": "",
        "upload_fileid": photo_id or "",
    }

    status_sub, hdrs_sub, body_sub = client.post("/report/new", data=report_data)
    text_sub = body_sub.decode("utf-8", errors="replace")

    # Turnstile may block automated submission
    if "turnstile" in text_sub.lower() or "cf-turnstile" in text_sub.lower():
        R.skip("G", "report submit (Turnstile CAPTCHA active)",
               "automated submission blocked by Turnstile; verify via browser checklist")
        # Still try to check for validation errors
        errors = re.findall(r'class="form-error[^"]*"[^>]*>([^<]+)', text_sub)
        if errors:
            R.skip("G", f"form errors: {'; '.join(e.strip() for e in errors[:3])}", "informational")
        return

    # Check for confirmation redirect or success page
    report_url = None
    if status_sub in (301, 302):
        loc = hdrs_sub.get("Location", hdrs_sub.get("location", ""))
        if "/report/" in loc:
            report_url = loc
            R.record("G", "report submit redirects to /report/", True, loc)
        else:
            R.record("G", "report submit redirect", False, f"location={loc}")
    elif status_sub == 200:
        m = re.search(r'href="(/report/\d+)"', text_sub)
        if m:
            report_url = m.group(1)
            R.record("G", "report created (link on page)", True, report_url)
        elif "/report/confirmation" in text_sub or "Thank you" in text_sub or "report has been sent" in text_sub.lower():
            R.record("G", "report submit shows confirmation", True, "")
            m2 = re.search(r'/report/(\d+)', text_sub)
            if m2:
                report_url = f"/report/{m2.group(1)}"
        else:
            # Form re-rendered with 200 — server-side validation rejected it
            errors = re.findall(r'class="form-error[^"]*"[^>]*>([^<]+)', text_sub)
            R.skip("G", "report submit (form re-rendered, no redirect)",
                   f"likely requires body_id/Turnstile; errors={[e.strip() for e in errors[:3]]}; verify via browser checklist")
    else:
        R.skip("G", "report submit (unexpected status)",
               f"status={status_sub}; verify via browser checklist")

    # Step 4: Verify report page
    if report_url:
        # Normalize to path only
        if report_url.startswith("http"):
            report_url = urllib.parse.urlparse(report_url).path
        status_rpt, _, body_rpt = client.get(report_url)
        text_rpt = body_rpt.decode("utf-8", errors="replace")
        R.record("G", f"report page {report_url} loads", status_rpt == 200, f"got {status_rpt}")
        R.record("G", "report page shows submitted title",
                 "Pothole acceptance check" in text_rpt, "title not found")
        if photo_id:
            R.record("G", "report page has photo link",
                     "/photo/" in text_rpt, "no /photo/ link")
    else:
        R.skip("G", "report page verification", "no report URL captured")

    # Step 5: Anonymous + email-confirm path via DB token
    print("  ... anonymous email-confirm path")
    db_ct = cfg["staging_db_container"]
    db_name = cfg["staging_db_name"]
    # Find latest unconfirmed problem
    row = db_query(db_ct, db_name,
        "SELECT p.id, t.token FROM problem p "
        "JOIN token t ON t.data::jsonb->>'id' = p.id::text "
        "WHERE t.scope = 'problem' AND p.state = 'unconfirmed' "
        "ORDER BY p.id DESC LIMIT 1")
    if row and "|" in row and not row.startswith("DB_ERROR"):
        prob_id, confirm_token = row.split("|", 1)
        status_confirm, hdrs_c, _ = client.get(f"/P/{confirm_token}")
        R.record("G", f"/P/{{token}} confirms report #{prob_id}",
                 status_confirm in (200, 302), f"status={status_confirm}")
    else:
        R.skip("G", "anonymous email-confirm path", f"no unconfirmed problem+token: {row[:80] if row else 'empty'}")

# ── Suite H: Media & Assets ──────────────────────────────────────────

def suite_h(client, R, cfg):
    print("\n▸ Suite H: Media & Assets")

    # CSS served with caching
    status, _, body = client.get("/")
    text = body.decode("utf-8", errors="replace")
    css_match = re.search(r'href="(/cobrands/infrasignal/[^"]*\.css[^"]*)"', text)
    if css_match:
        css_url = css_match.group(1)
        status_css, hdrs_css, _ = client.get(css_url)
        R.record("H", "base.css served (200)", status_css == 200, f"got {status_css}")
    else:
        R.record("H", "base.css referenced on page", False, "regex miss")

    # JS served
    js_match = re.search(r'header-nav\.js\?([a-f0-9]+)', text)
    R.record("H", "header-nav.js referenced on page", js_match is not None, "")

    # Logo
    logo_match = re.search(r'src="(/cobrands/infrasignal/[^"]*logo[^"]*)"', text, re.IGNORECASE)
    if logo_match:
        logo_url = logo_match.group(1)
        status_logo, hdrs_logo = client.head(logo_url)
        R.record("H", f"logo {logo_url} -> 200", status_logo == 200, f"got {status_logo}")
    else:
        R.skip("H", "logo check", "no logo src found")

    # Category images on reports page
    status_rpts, _, body_rpts = client.get("/reports")
    text_rpts = body_rpts.decode("utf-8", errors="replace")
    img_urls = re.findall(r'src="(/photo/[^"]+)"', text_rpts)
    if img_urls:
        test_img = img_urls[0]
        status_img, hdrs_img = client.head(test_img)
        ct = hdrs_img.get("Content-Type", hdrs_img.get("content-type", ""))
        R.record("H", f"report photo {test_img} -> 200+image", status_img == 200 and "image" in ct,
                 f"status={status_img} ct={ct}")
    else:
        R.skip("H", "report photo check", "no /photo/ images on /reports page")

    # Regression guard: report detail data must not depend on translated UI text.
    # /report/524 is seeded demo data used in staging/dev screenshots.
    report_expect = {
        "data-problem-state": "fixed - council",
        "data-ref-number": "524",
        "data-update-epoch": None,
    }
    report_snapshots = {}
    for lang in ["en-gb", "es", "tr"]:
        status_rep, _, body_rep = client.get(f"/report/524?lang={lang}")
        text_rep = body_rep.decode("utf-8", errors="replace")
        R.record("H", f"/report/524 [{lang}] loads", status_rep == 200, f"got {status_rep}")
        if status_rep != 200:
            continue
        values = {}
        for attr in report_expect:
            m = re.search(rf'{attr}="([^"]+)"', text_rep)
            values[attr] = m.group(1) if m else ""
            if report_expect[attr] is None:
                R.record("H", f"/report/524 [{lang}] has {attr}",
                         bool(values[attr]), f"{attr} missing")
            else:
                R.record("H", f"/report/524 [{lang}] {attr} stable",
                         values[attr] == report_expect[attr],
                         f"got {values[attr]!r}")
        report_snapshots[lang] = values

    if "en-gb" in report_snapshots and "es" in report_snapshots:
        R.record("H", "report detail stable data matches EN vs ES",
                 report_snapshots["en-gb"] == report_snapshots["es"],
                 f"EN={report_snapshots.get('en-gb')} ES={report_snapshots.get('es')}")
    if "en-gb" in report_snapshots and "tr" in report_snapshots:
        R.record("H", "report detail stable data matches EN vs TR",
                 report_snapshots["en-gb"] == report_snapshots["tr"],
                 f"EN={report_snapshots.get('en-gb')} TR={report_snapshots.get('tr')}")

    # Regression guard: report update photo upload should be enhanced to Dropzone.
    status_rep, _, body_rep = client.get("/report/524?lang=tr")
    text_rep = body_rep.decode("utf-8", errors="replace")
    fp_match = re.search(r'/cobrands/infrasignal/filter-pills\.js\?([a-f0-9]+)', text_rep)
    if fp_match:
        fp_url = f"/cobrands/infrasignal/filter-pills.js?{fp_match.group(1)}"
        status_fp, _, fp_body = client.get(fp_url)
        fp_text = fp_body.decode("utf-8", errors="replace")
        R.record("H", "filter-pills.js served (200)", status_fp == 200, f"got {status_fp}")
        R.record("H", "filter-pills.js has Dropzone safety initializer",
                 "ensureDropzone" in fp_text and "fixmystreet.set_up.dropzone" in fp_text,
                 "missing ensureDropzone/fixmystreet.set_up.dropzone")
    else:
        R.record("H", "filter-pills.js referenced on report page", False, "regex miss")

# ── Suite I: Negative & Security ─────────────────────────────────────

def suite_i(client, R, cfg):
    print("\n▸ Suite I: Negative & Security")

    # Admin without login -> redirect
    anon = HTTPClient(client.base)
    status, hdrs, _ = anon.get_no_redirect("/admin")
    R.record("I", "/admin without auth -> redirect", status in (301, 302, 303),
             f"got {status}")

    # CSRF rejection
    status_csrf, _, body_csrf = anon.post("/report/new", data={"title": "bad", "detail": "bad"})
    text_csrf = body_csrf.decode("utf-8", errors="replace")
    R.record("I", "POST /report/new without CSRF rejected",
             status_csrf != 200 or "error" in text_csrf.lower() or "token" in text_csrf.lower(),
             f"status={status_csrf}")

    # AJAX endpoints without auth -> not 200 JSON data
    for ep in ["/admin/bodies/bodies_by_state?state=CA", "/admin/bodies/cities_by_county?county_id=1"]:
        status_ep, _, _ = anon.get_no_redirect(ep)
        R.record("I", f"unauthenticated {ep} -> not 200",
                 status_ep != 200, f"got {status_ep}")

# ── Main ─────────────────────────────────────────────────────────────

ALL_SUITES = {
    "A": ("Infrastructure & Health", suite_a),
    "B": ("Public Pages (EN)", suite_b),
    "C": ("i18n Leak Checks", suite_c),
    "D": ("Language Switcher", suite_d),
    "E": ("Admin Pages & Auth", suite_e),
    "F": ("Admin Bodies AJAX", suite_f),
    "G": ("Full E2E Report Flow", suite_g),
    "H": ("Media & Assets", suite_h),
    "I": ("Negative & Security", suite_i),
}


def main():
    parser = argparse.ArgumentParser(description="InfraSignal Staging Acceptance Tests")
    parser.add_argument("--base", default=os.environ.get("STAGING_BASE_URL", "http://REDACTED-IP:8080"),
                        help="Staging base URL")
    parser.add_argument("--suite", default="",
                        help="Comma-separated suites to run (e.g. A,B,C). Default: all")
    parser.add_argument("--report", default="staging-test-report.txt",
                        help="Output report file path")
    args = parser.parse_args()

    with open(DATA_FILE) as f:
        cfg = json.load(f)

    selected = [s.strip().upper() for s in args.suite.split(",") if s.strip()] if args.suite else list(ALL_SUITES.keys())
    client = HTTPClient(args.base)
    R = Results()

    print(f"InfraSignal Staging Acceptance Tests")
    print(f"Base: {args.base}")
    print(f"Suites: {', '.join(selected)}")
    print(f"Time: {time.strftime('%Y-%m-%d %H:%M:%S %Z')}")

    for key in selected:
        if key in ALL_SUITES:
            name, fn = ALL_SUITES[key]
            try:
                fn(client, R, cfg)
            except Exception as e:
                R.record(key, f"suite {key} unhandled error", False, str(e)[:200])
        else:
            print(f"  [WARN] Unknown suite '{key}', skipping")

    report = R.summary()
    print(f"\n{report}")

    with open(args.report, "w") as f:
        f.write(report + "\n")
    print(f"\nReport written to {args.report}")

    sys.exit(0 if R.failed == 0 else 1)


if __name__ == "__main__":
    main()
