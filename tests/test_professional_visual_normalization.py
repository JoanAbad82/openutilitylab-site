import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSS = (ROOT / "styles.css").read_text(encoding="utf-8")
PAGE = (ROOT / "ai-assisted-work" / "index.html").read_text(encoding="utf-8")


class ProfessionalVisualNormalizationTests(unittest.TestCase):
    def test_css_version_is_renewed_for_professional_page(self):
        self.assertEqual(PAGE.count("/styles.css?v=20261021-visual-normalization-v1"), 1)
        self.assertNotIn("/styles.css?v=20261018-project-refresh-v1", PAGE)

    def test_editorial_headings_share_a_scoped_layout(self):
        self.assertIn("body.wide-professional-layout .cv-page.professional-portfolio > .cv-section > .section-heading {", CSS)
        self.assertIn("body.wide-professional-layout .cv-page.professional-portfolio > .cv-section > .section-heading h2 {", CSS)
        self.assertIn("display: block;", CSS)
        self.assertIn("max-width: 29ch;", CSS)

    def test_dark_steps_have_contrasting_surface_and_index(self):
        self.assertIn(':root[data-theme="dark"] body.wide-professional-layout .cv-page.professional-portfolio .cv-steps li {', CSS)
        self.assertIn("background: var(--dark-panel-raised, #252d36);", CSS)
        self.assertIn("color: var(--dark-ink, #eef2f6);", CSS)
        self.assertIn(':root[data-theme="dark"] body.wide-professional-layout .cv-page.professional-portfolio .cv-steps li::before {', CSS)
        self.assertIn("color: var(--dark-muted, #c4cdd7);", CSS)

    def test_light_contact_uses_readable_text_color(self):
        self.assertIn(':root[data-theme="light"] body.wide-professional-layout .cv-page.professional-portfolio #contact-conversion {', CSS)
        self.assertIn("color: #262b32;", CSS)

    def test_content_and_commercial_links_remain(self):
        for text in ("validation-service-example", "contact-conversion", "Disciplined delivery, not random prompting", "mailto:abadbatallajoan@gmail.com"):
            self.assertIn(text, PAGE)
        self.assertNotIn("<form", PAGE)
        self.assertEqual(len(re.findall(r'id="validation-service-example"', PAGE)), 1)


if __name__ == "__main__":
    unittest.main()
