from __future__ import annotations

import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import unittest
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets/showcase/captures.json"
EXPECTED = {
    "repas_actiu": "https://repasactiu.pages.dev/",
    "programacion_practica": "https://programacion-practica.pages.dev/",
    "github_hidden_gems": "https://github.com/JoanAbad82/github-hidden-gems",
}


class ShowcaseParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.images = []
        self.links = []
    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        if tag == "img" and d.get("src", "").startswith("/assets/showcase/"):
            self.images.append(d)
        if tag == "a" and "showcase-preview-link" in d.get("class", "").split():
            self.links.append(d)


class VerifiedShowcaseTest(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.html = (ROOT / "index.html").read_text(encoding="utf-8")
        self.parser = ShowcaseParser()
        self.parser.feed(self.html)

    def test_three_public_captures_and_provenance(self):
        records = self.manifest["captures"]
        self.assertEqual(self.manifest["version"], 1)
        self.assertEqual(self.manifest["snapshot_date"], "2026-10-20")
        self.assertEqual(self.manifest["source_type"], "unmodified_chrome_rendered_public_pages")
        self.assertEqual({row["id"] for row in records}, set(EXPECTED))
        self.assertEqual(len(records), 3)
        for record in records:
            with self.subTest(project=record["id"]):
                self.assertEqual(record["source_url"], EXPECTED[record["id"]])
                self.assertTrue(record["captured_at_utc"].endswith("Z"))
                self.assertTrue(record["alt"].strip())
                self.assertEqual((record["width"], record["height"]), (1280, 740))
                url = urlsplit(record["source_url"])
                self.assertEqual(url.scheme, "https")
                self.assertTrue(url.hostname)
                self.assertFalse(url.username or url.password or url.query or url.fragment)

    def test_real_jpegs_exact_hash_size_and_budget(self):
        self.assertLess(sum(row["size_bytes"] for row in self.manifest["captures"]), 350_000)
        for record in self.manifest["captures"]:
            with self.subTest(project=record["id"]):
                asset = record["asset"]
                self.assertTrue(asset.startswith("/assets/showcase/"))
                self.assertNotIn("..", asset)
                content = (ROOT / asset.lstrip("/")).read_bytes()
                self.assertTrue(content.startswith(bytes.fromhex("ffd8")))
                self.assertTrue(content.endswith(bytes.fromhex("ffd9")))
                self.assertEqual(record["size_bytes"], len(content))
                self.assertLess(len(content), 150_000)
                self.assertEqual(hashlib.sha256(content).hexdigest(), record["sha256"])

    def test_markup_accessible_and_dated(self):
        self.assertEqual(self.html.count('class="showcase-preview"'), 3)
        self.assertEqual(self.html.count("showcase-card--lead"), 1)
        self.assertEqual(len(self.parser.images), 3)
        self.assertEqual(len(self.parser.links), 3)
        self.assertEqual(self.html.count("20 October 2026"), 3)
        for image in self.parser.images:
            self.assertEqual(image.get("loading"), "lazy")
            self.assertEqual(image.get("decoding"), "async")
            self.assertTrue(image.get("alt"))
            self.assertEqual((image.get("width"), image.get("height")), ("1280", "740"))
        for link in self.parser.links:
            self.assertIn(link["href"], set(EXPECTED.values()))
            self.assertIn("noopener", link.get("rel", "").split())
            self.assertIn("noreferrer", link.get("rel", "").split())

    def test_no_private_project_or_new_runtime(self):
        self.assertNotIn("Badia Portbou", self.html)
        self.assertNotIn("M2M_EVIDENCE_ROUTER", self.html)
        self.assertNotIn("AGENTE_MULTIPLE_AUTONOMO", self.html)
        for tag in ("<iframe", "<video", "<canvas"):
            self.assertNotIn(tag, self.html)


if __name__ == "__main__":
    unittest.main()
