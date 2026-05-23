"""Render mockup HTMLs to PNG using Playwright (headless Chromium)."""
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

RAW_DIR = Path(__file__).parent
PNG_DIR = RAW_DIR.parent / "png"
PNG_DIR.mkdir(parents=True, exist_ok=True)

VIEWPORT = {"width": 1448, "height": 952}  # 1400 mockup + margins


FULL_PAGE_FILES = {"09_palette_reference.html", "10_components_overview.html"}


def render(html_files: list[str]):
    with sync_playwright() as p:
        browser = p.chromium.launch()
        ctx = browser.new_context(viewport=VIEWPORT, device_scale_factor=2)
        page = ctx.new_page()
        for html_name in html_files:
            html_path = RAW_DIR / html_name
            if not html_path.exists():
                print(f"[skip] {html_name} not found")
                continue
            url = html_path.absolute().as_uri()
            page.goto(url, wait_until="networkidle")
            page.wait_for_timeout(600)  # let fonts settle
            png_name = html_name.replace(".html", ".png")
            out = PNG_DIR / png_name
            full_page = html_name in FULL_PAGE_FILES
            page.screenshot(path=str(out), full_page=full_page, omit_background=False)
            print(f"[ok] {png_name} -> {out}")
        ctx.close()
        browser.close()


if __name__ == "__main__":
    if len(sys.argv) > 1:
        render(sys.argv[1:])
    else:
        render(sorted(p.name for p in RAW_DIR.glob("*.html")))
