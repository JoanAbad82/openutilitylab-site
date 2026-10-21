import re
import unittest
from pathlib import Path
from urllib.parse import urlsplit, parse_qs, unquote

ROOT = Path(__file__).resolve().parents[1]
PAGE = (ROOT / "ai-assisted-work" / "index.html").read_text(encoding="utf-8")
PROFILE = (ROOT / "index.html").read_text(encoding="utf-8")

class CommercialContactPathTests(unittest.TestCase):
    def test_service_entrypoints_reach_one_section(self):
        self.assertEqual(PAGE.count('id="validation-service-example"'), 1)
        self.assertGreaterEqual(PAGE.count('href="#validation-service-example"'), 2)
        self.assertIn('aria-labelledby="validation-case-heading"', PAGE)
        self.assertIn('id="validation-case-heading"', PAGE)

    def test_commercial_email_destinations(self):
        for html in (PAGE, PROFILE):
            targets = re.findall(r'href="(mailto:[^"]+)"', html)
            self.assertTrue(targets)
            for target in targets:
                if "security@" in target or "conduct@" in target:
                    continue
                self.assertEqual(urlsplit(target).path, "abadbatallajoan@gmail.com")
        scoped = re.findall(r'href="(mailto:[^"]+)"', PAGE)
        scoped = [x for x in scoped if "Scoped%20AI%20workflow" in x]
        self.assertEqual(len(scoped), 1)
        self.assertIn("validation inquiry", unquote(parse_qs(urlsplit(scoped[0]).query)["subject"][0]))

    def test_no_personal_tracking_or_new_form(self):
        section = PAGE.split('id="validation-service-example"', 1)[1].split('</section>', 1)[0]
        self.assertNotIn("<form", section)
        self.assertNotIn("data-email", section)
        self.assertNotIn("onclick=", section)

if __name__ == "__main__":
    unittest.main()
