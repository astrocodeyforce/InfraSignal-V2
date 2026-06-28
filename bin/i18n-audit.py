#!/usr/bin/env python3
"""Audit InfraSignal loc()/_() strings against ru/tr/es catalogs.

Reports, per language:
  - MISSING : msgid used in templates but absent from the .po catalog
  - EMPTY   : present but msgstr is empty (renders English)
  - FUZZY   : marked fuzzy (renders English / unreviewed)
  - LEAK    : msgstr identical to the English msgid (likely untranslated)
"""
import os, re, sys
import polib

ROOT = "/opt/infrasignal-dev"
TPL_DIR = os.path.join(ROOT, "templates/web/infrasignal")
COBRAND = os.path.join(ROOT, "perllib/FixMyStreet/Cobrand/Infrasignal.pm")
LANGS = {"ru": "ru_RU", "tr": "tr_TR", "es": "es"}

# Pages that are fully translated via dedicated per-language template files
# (about-ru.html etc.), so their English source templates are NOT catalog-driven.
SKIP_FILES = re.compile(r"/(about|faq|privacy|terms|security)\b.*\.html$")

# loc('...') / loc("...") and the inner string of tprintf(loc('...'), ...)
LOC_RE = re.compile(r"""loc\(\s*(['"])(.*?)(?<!\\)\1""", re.S)
GETTEXT_RE = re.compile(r"""(?<![\w])_\(\s*(['"])(.*?)(?<!\\)\1""", re.S)


def collect_msgids():
    ids = {}  # msgid -> set(files)
    for dirpath, _dirs, files in os.walk(TPL_DIR):
        for f in files:
            if not f.endswith(".html"):
                continue
            path = os.path.join(dirpath, f)
            rel = path[len(ROOT) + 1:]
            text = open(path, encoding="utf-8", errors="ignore").read()
            for m in LOC_RE.finditer(text):
                # Template Toolkit unescapes \" and \' at runtime; loc() looks up
                # the unescaped value, so normalize to match the catalog.
                mid = m.group(2).replace('\\"', '"').replace("\\'", "'")
                ids.setdefault(mid, set()).add(rel)
    # cobrand admin page titles wrapped with _()
    if os.path.exists(COBRAND):
        text = open(COBRAND, encoding="utf-8", errors="ignore").read()
        for m in GETTEXT_RE.finditer(text):
            ids.setdefault(m.group(2), set()).add("perllib/.../Infrasignal.pm")
    return ids


def normalize(s):
    # collapse TT-style whitespace so multi-line msgids match catalog forms
    return re.sub(r"\s+", " ", s).strip()


def has_cyrillic(s):
    return bool(re.search(r"[\u0400-\u04FF]", s))


def main():
    ids = collect_msgids()
    print(f"Collected {len(ids)} distinct loc()/_() msgids from infrasignal templates\n")

    for lang, locale in LANGS.items():
        po_path = os.path.join(ROOT, f"locale/{locale}.UTF-8/LC_MESSAGES/FixMyStreet.po")
        po = polib.pofile(po_path)
        cat = {}
        for e in po:
            cat[e.msgid] = e
            cat[normalize(e.msgid)] = e

        missing, empty, fuzzy, leak = [], [], [], []
        for mid, files in ids.items():
            if not mid.strip():
                continue
            e = cat.get(mid) or cat.get(normalize(mid))
            sample = sorted(files)[0]
            short = (mid[:70] + "…") if len(mid) > 70 else mid
            if e is None:
                missing.append((short, sample))
            elif "fuzzy" in e.flags:
                fuzzy.append((short, sample))
            elif not e.msgstr.strip():
                empty.append((short, sample))
            elif e.msgstr.strip() == mid.strip():
                # identical translation: strong signal for ru (cyrillic expected),
                # weaker for es/tr (could be 'Email', 'OK', proper nouns)
                if lang == "ru" or len(mid) > 12:
                    leak.append((short, e.msgstr[:40], sample))

        print("=" * 72)
        print(f"### {lang} ({locale})")
        print(f"  MISSING={len(missing)}  EMPTY={len(empty)}  FUZZY={len(fuzzy)}  LEAK(eng==translit)={len(leak)}")
        def dump(title, rows, withval=False):
            if not rows:
                return
            print(f"\n  -- {title} ({len(rows)}) --")
            for r in rows:
                if withval:
                    print(f"     [{r[2]}] '{r[0]}'  ==>  '{r[1]}'")
                else:
                    print(f"     [{r[1]}] '{r[0]}'")
        dump("MISSING from catalog", missing)
        dump("EMPTY msgstr (shows English)", empty)
        dump("FUZZY (shows English)", fuzzy)
        dump("LEAK: translation == English source", leak, withval=True)
        print()


if __name__ == "__main__":
    main()
