#!/usr/bin/env python3
"""Dump the exact msgids that are missing from the ru catalog (same set for all
three languages) as a JSON list, preserving placeholders/markup."""
import os, re, json
import polib

ROOT = "/opt/infrasignal-dev"
TPL_DIR = os.path.join(ROOT, "templates/web/infrasignal")
COBRAND = os.path.join(ROOT, "perllib/FixMyStreet/Cobrand/Infrasignal.pm")

LOC_RE = re.compile(r"""loc\(\s*(['"])(.*?)(?<!\\)\1""", re.S)
GETTEXT_RE = re.compile(r"""(?<![\w])_\(\s*(['"])(.*?)(?<!\\)\1""", re.S)


def collect():
    ids = {}
    for dp, _d, fs in os.walk(TPL_DIR):
        for f in fs:
            if f.endswith(".html"):
                t = open(os.path.join(dp, f), encoding="utf-8", errors="ignore").read()
                for m in LOC_RE.finditer(t):
                    ids.setdefault(m.group(2), os.path.join(dp, f)[len(ROOT)+1:])
    t = open(COBRAND, encoding="utf-8", errors="ignore").read()
    for m in GETTEXT_RE.finditer(t):
        ids.setdefault(m.group(2), "cobrand")
    return ids


po = polib.pofile(os.path.join(ROOT, "locale/ru_RU.UTF-8/LC_MESSAGES/FixMyStreet.po"))
have = set(e.msgid for e in po)
norm = {re.sub(r"\s+", " ", e.msgid).strip() for e in po}

missing = []
for mid, f in collect().items():
    if not mid.strip():
        continue
    if mid in have or re.sub(r"\s+", " ", mid).strip() in norm:
        continue
    missing.append({"msgid": mid, "file": f})

# drop obvious proper-noun / placeholder false positives
SKIP = {"MapIt", "JSON:", "SocietyWorks", "WCAG 2.1 AA", "Open311 v2", "your@email.com"}
missing = [m for m in missing if m["msgid"] not in SKIP]

print(json.dumps(missing, ensure_ascii=False, indent=1))
print(f"\nTOTAL={len(missing)}", )
