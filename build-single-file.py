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


STYLE_BLOCK = re.compile(r"(<style>)(.*?)(</style>)", re.S)
SCRIPT_BLOCK = re.compile(r"(<script>)(.*?)(</script>)", re.S)


def minify_css(css: str) -> str:
    """Strip comments and collapse whitespace. Only used on the bundle — the
    source index.html keeps every comment, since that's the file people
    actually edit. Safe to be this aggressive because the stylesheet has no
    url(...) values; a colon or slash inside one of those is exactly what a
    careless minifier corrupts, so that gets checked before this ships, not
    assumed."""
    css = re.sub(r"/\*.*?\*/", "", css, flags=re.S)
    css = re.sub(r"[ \t\r\n]+", " ", css)
    css = re.sub(r" *([{};]) *", r"\1", css)
    return css.strip()


def minify_js(js: str) -> str:
    """Deliberately smaller than the CSS pass: only /* */ block comments and
    blank lines. Line comments (//) are left alone — a regex can't reliably
    tell a real // comment from one inside a string or a `https://` URL
    without actually tokenising the code, and getting that wrong silently
    breaks the page. The block-comment style used throughout this file's
    script is still most of the saving anyway."""
    js = re.sub(r"/\*.*?\*/", "", js, flags=re.S)
    js = re.sub(r"\n[ \t]*\n", "\n", js)
    js = re.sub(r"^[ \t]+", "", js, flags=re.M)
    return js.strip()


def main() -> None:
    if not SOURCE.is_file():
        raise SystemExit(f"index.html not found at {SOURCE}")

    html = SOURCE.read_text(encoding="utf-8")
    print(f"Reading {SOURCE.name} ({len(html) / 1024:.0f} KB)")

    built = ASSET_REF.sub(inline, html)

    css_before = css_after = js_before = js_after = 0

    def do_css(m: re.Match) -> str:
        nonlocal css_before, css_after
        css_before += len(m.group(2))
        minified = minify_css(m.group(2))
        css_after += len(minified)
        return f"{m.group(1)}{minified}{m.group(3)}"

    def do_js(m: re.Match) -> str:
        nonlocal js_before, js_after
        js_before += len(m.group(2))
        minified = minify_js(m.group(2))
        js_after += len(minified)
        return f"{m.group(1)}{minified}{m.group(3)}"

    built = STYLE_BLOCK.sub(do_css, built)
    built = SCRIPT_BLOCK.sub(do_js, built)

    if css_before:
        print(f"Minified CSS: {css_before / 1024:.0f} KB -> {css_after / 1024:.0f} KB")
    if js_before:
        print(f"Minified JS:  {js_before / 1024:.0f} KB -> {js_after / 1024:.0f} KB")

    OUT_DIR.mkdir(exist_ok=True)
    OUT.write_text(built, encoding="utf-8")
    print(f"\nWrote {OUT.relative_to(ROOT)} ({len(built) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
