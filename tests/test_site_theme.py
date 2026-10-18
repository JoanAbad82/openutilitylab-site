from __future__ import annotations
from html.parser import HTMLParser
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
HTML_ROUTES = [
    "index.html",
    "404.html",
    "ai-assisted-work/index.html",
    "affiliate-friction-auditor/index.html",
    "affiliate-friction-auditor/affiliate-review-audit-example/index.html",
    "btc-15m-arena/index.html",
    "spectralcode/index.html",
    "tension-cores/index.html",
]


class HeadParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_head = False
        self.links = []
        self.scripts = []
        self.heads = 0
    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == "head":
            self.in_head = True
            self.heads += 1
        elif self.in_head and tag == "link":
            self.links.append(values.get("href"))
        elif self.in_head and tag == "script":
            self.scripts.append(values.get("src"))
    def handle_endtag(self, tag):
        if tag == "head":
            self.in_head = False


class ThemeContractTest(unittest.TestCase):
    def test_all_eight_html_routes_have_exactly_one_shared_theme(self):
        for path in HTML_ROUTES:
            with self.subTest(path=path):
                source = (ROOT / path).read_text(encoding="utf-8")
                head = HeadParser()
                head.feed(source)
                self.assertGreaterEqual(head.heads, 1)
                self.assertEqual(
                    sum(x is not None and x.startswith("/assets/theme.css?") for x in head.links),
                    1,
                )
                self.assertEqual(
                    sum(x is not None and x.startswith("/assets/theme.js?") for x in head.scripts),
                    1,
                )

    def test_css_declares_true_dark_scheme_and_game_guard(self):
        css = (ROOT / "assets/theme.css").read_text(encoding="utf-8")
        for required in ('[data-theme="dark"]', "--dark-panel:", "color-scheme: dark",
                         ".site-appearance-button:focus-visible",
                         ".tc-shell", "prefers-reduced-motion"):
            self.assertIn(required, css)

    def test_toggling_is_user_driven_and_system_aware(self):
        source = (ROOT / "assets/theme.js").read_text(encoding="utf-8")
        for required in ("prefers-color-scheme: dark", "localStorage.getItem",
                         "localStorage.setItem", "DOMContentLoaded",
                         "aria-pressed", "data-appearance-choice",
                         '"system"', '"light"', '"dark"'):
            self.assertIn(required, source)
        for forbidden in ("eval(", "innerHTML", "fetch(", "XMLHttpRequest", "document.cookie"):
            self.assertNotIn(forbidden, source)

    def test_no_new_third_party_or_tracking(self):
        source = (ROOT / "assets/theme.js").read_text(encoding="utf-8")
        self.assertNotIn("https://", source)
        self.assertNotIn("http://", source)


if __name__ == "__main__":
    unittest.main()
