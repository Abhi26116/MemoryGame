#!/usr/bin/env python3
"""
Check the shared translation tables against the tr("…") keys in both apps.

Reports, per language, keys used in code but missing from the table, keys in
the table no longer used anywhere, and translations whose {0}/{1} placeholders
don't match the key. Exits non-zero if anything is missing or mismatched.

Usage:  python3 scripts/check_l10n.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLES = ROOT / "localization/l10n"
SOURCES = [
    *ROOT.glob("MemoryGame/**/*.swift"),
    *ROOT.glob("android/app/src/main/java/**/*.kt"),
]
# Keys that are pure placeholders read the same in every language.
IDENTITY = {"{0}, {1}"}
CALL = re.compile(r'\btr\("((?:[^"\\]|\\.)*)"')
PLACEHOLDER = re.compile(r"\{\d+\}")


def code_keys() -> set[str]:
    keys = set()
    for path in SOURCES:
        for match in CALL.finditer(path.read_text(encoding="utf-8")):
            keys.add(match.group(1).replace('\\"', '"').replace("\\$", "$"))
    return keys


def main() -> int:
    used = code_keys()
    failed = False
    for table_path in sorted(TABLES.glob("*.json")):
        lang = table_path.stem
        table = json.loads(table_path.read_text(encoding="utf-8"))
        if lang == "en":
            # English only overrides disambiguated keys like "Orange (fruit)".
            stale = sorted(set(table) - used)
            print(f"en: {len(table)} overrides" + (f", unused: {stale}" if stale else ""))
            continue
        missing = sorted(used - set(table) - IDENTITY)
        unused = sorted(set(table) - used)
        mismatched = sorted(
            k for k, v in table.items()
            if sorted(PLACEHOLDER.findall(k)) != sorted(PLACEHOLDER.findall(v))
        )
        print(f"{lang}: {len(table)} strings, {len(missing)} missing, "
              f"{len(unused)} unused, {len(mismatched)} placeholder mismatches")
        for label, items in (("missing", missing), ("unused", unused), ("mismatch", mismatched)):
            for item in items:
                print(f"    {label}: {item}")
        failed |= bool(missing or mismatched)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
