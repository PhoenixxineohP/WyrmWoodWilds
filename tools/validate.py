#!/usr/bin/env python3
"""Validate the pack's JSONC files (comments, trailing commas, duplicate keys)."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def strip_comments(text: str) -> str:
    out: list[str] = []
    i, n = 0, len(text)
    in_string = False
    while i < n:
        ch = text[i]
        if in_string:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            out.append(" ")
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def strip_trailing_commas(text: str) -> str:
    out: list[str] = []
    i, n = 0, len(text)
    in_string = False
    while i < n:
        ch = text[i]
        if in_string:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if ch == '"':
                in_string = False
            i += 1
            continue
        if ch == '"':
            in_string = True
            out.append(ch)
            i += 1
            continue
        if ch == ",":
            j = i + 1
            while j < n and text[j] in " \t\r\n":
                j += 1
            if j < n and text[j] in "}]":
                i += 1
                continue
        out.append(ch)
        i += 1
    return "".join(out)


def no_duplicates(pairs):
    seen = set()
    for key, _ in pairs:
        if key in seen:
            raise ValueError(f"duplicate key: {key}")
        seen.add(key)
    return dict(pairs)


def main() -> int:
    files = sorted(ROOT.glob("mods/**/*.jsonc"))
    if not files:
        print("no .jsonc files found", file=sys.stderr)
        return 1

    failed = 0
    for path in files:
        raw = path.read_text(encoding="utf-8")
        cleaned = strip_trailing_commas(strip_comments(raw))
        try:
            data = json.loads(cleaned, object_pairs_hook=no_duplicates)
        except Exception as exc:  # noqa: BLE001
            print(f"FAIL {path.relative_to(ROOT)}: {exc}")
            failed += 1
            continue

        if isinstance(data, list):
            count = len(data)
            kind = "list"
        elif isinstance(data, dict):
            count = len(data)
            keys = list(data)
            if any(".jsonc" in k for k in keys):
                print(f"WARN {path.relative_to(ROOT)}: looks like a nested file name")
            kind = "object"
        else:
            print(f"FAIL {path.relative_to(ROOT)}: top level must be an object or list")
            failed += 1
            continue

        rel = path.relative_to(ROOT)
        print(f"ok   {rel} ({kind}, {count} entries)")

    if failed:
        print(f"\n{failed} file(s) failed")
        return 1
    print(f"\n{len(files)} file(s) valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
