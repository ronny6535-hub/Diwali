#!/usr/bin/env python3
"""
Inline every assets/ image referenced by index.html as a data URI and write
dist/index.html — one self-contained file that works with no assets folder.

    python3 build-single-file.py

The normal deploy target is index.html + assets/ (smaller, cacheable). Use this
when you need a single file to email, preview, or drop somewhere without a
folder structure.
"""

import base64
import mimetypes
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "index.html"
OUT_DIR = ROOT / "dist"
OUT = OUT_DIR / "index.html"

# Matches src="assets/whatever.png" (images) and href="assets/whatever.svg"
# (favicon <link> tags), in either quote style
ASSET_REF = re.compile(r'(src=|href=)(["\'])(assets/[^"\']+)\2')


def inline(match: re.Match) -> str:
    attr, quote, rel = match.group(1), match.group(2), match.group(3)
    path = ROOT / rel

    if not path.is_file():
        print(f"  skip (missing): {rel}")
        return match.group(0)

    mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    print(f"  inlined: {rel}  ({path.stat().st_size / 1024:.0f} KB)")
    return f"{attr}{quote}data:{mime};base64,{encoded}{quote}"


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"index.html not found at {SOURCE}")

    html = SOURCE.read_text(encoding="utf-8")
    print(f"Reading {SOURCE.name} ({len(html) / 1024:.0f} KB)")

    built = ASSET_REF.sub(inline, html)

    OUT_DIR.mkdir(exist_ok=True)
    OUT.write_text(built, encoding="utf-8")
    print(f"\nWrote {OUT.relative_to(ROOT)} ({len(built) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
