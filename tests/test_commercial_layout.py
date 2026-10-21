import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSS = (ROOT / "styles.css").read_text(encoding="utf-8")
PAGE = (ROOT / "ai-assisted-work" / "index.html").read_text(encoding="utf-8")

class CommercialLayoutTests(unittest.TestCase):
    def test_existing_content_and_links_untouched(self):
        self.assertIn('id="validation-service-example"', PAGE)
        self.assertIn('href="mailto:abadbatallajoan@gmail.com?subject=Scoped%20AI%20workflow%20validation%20inquiry"', PAGE)
        self.assertIn('href="https://github.com/JoanAbad82/github-hidden-gems/pull/33"', PAGE)

    def test_scoped_layout(self):
        self.assertIn("#validation-service-example .section-heading {", CSS)
        self.assertIn("#validation-service-example .cv-grid {", CSS)
        self.assertIn("align-items: start;", CSS)
        self.assertIn("height: auto;", CSS)

    def test_mobile_single_column(self):
        self.assertIn("@media (max-width: 700px) {\n    #validation-service-example .cv-grid { grid-template-columns: minmax(0, 1fr); }", CSS)

if __name__ == "__main__":
    unittest.main()
