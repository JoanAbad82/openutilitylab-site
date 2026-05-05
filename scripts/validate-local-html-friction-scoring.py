#!/usr/bin/env python3

"""Validate local affiliate friction scoring and report affordances with a static demo fixture."""

import json
import re
from html import unescape
from html.parser import HTMLParser
from urllib.parse import parse_qs, urlparse
from pathlib import Path


AFFILIATE_PATTERNS = [
    "tag=", "awin", "impact", "cj.com", "commission-junction", "tradedoubler",
    "partnerize", "admitad", "rakuten", "shareasale", "tidd.ly", "ref=",
    "aff=", "affiliate", "ascsubtag",
]
OPAQUE_TRACKING_URL_PATTERNS = [
    "tracking", "track", "click", "redirect", "out", "aff", "affiliate",
]
OPAQUE_TRACKING_PARAM_PATTERNS = [
    "url", "u", "target", "destination", "dest", "redirect", "redirect_url",
]
SHORTENER_DOMAINS = [
    "short.ly", "bit.ly", "t.co", "tinyurl.com", "goo.gl", "ow.ly",
    "rebrand.ly", "cutt.ly", "is.gd",
]
CTA_PATTERNS = [
    "buy", "check price", "see price", "get deal", "view deal", "shop now",
    "compare", "best price", "donde comprar", "comprar", "ver oferta",
    "oferta", "precio", "comprobar precio", "ver mas", "ver más",
]
COMMERCIAL_PATTERNS = [
    "best", "review", "comparison", "alternatives", "discount", "deal",
    "price", "coupon", "comprar", "oferta", "descuento", "comparativa", "mejor",
    "cafetera", "cafeteras", "producto recomendado",
]

PROJECT_ROOT = Path(__file__).resolve().parents[1]
INDEX_HTML = PROJECT_ROOT / "affiliate-friction-auditor" / "index.html"

EXPECTED_UI_STRINGS = [
    "Action Backlog",
    "Audited Links",
    "Download Markdown report",
    "Quick Diagnosis",
    "Low friction",
    "Moderate friction",
    "High friction",
    "Critical friction",
    "Top priority issue",
    "Backlog items",
    "Audited links",
    "Score band",
    "severity",
    "suggested fix",
    "why it matters",
    "Score Breakdown",
    "Commercial intent",
    "Affiliate coverage",
    "CTA clarity",
    "Tracking transparency",
    "Structure / metadata",
    "Built for feedback",
    "Affiliate Friction Auditor feedback",
    "abadbatallajoan@gmail.com",
    "Works best with real monetized review or comparison pages.",
    "false positives",
    "review or comparison pages",
]


DEMO_HTML = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Best countertop espresso machines reviewed for small kitchens</title>
  <meta name="description" content="Hands-on comparison of compact espresso machines, buying notes, prices and deal routing.">
</head>
<body>
  <header>
    <h1>Best countertop espresso machines reviewed for small kitchens</h1>
    <p>This review compares price, maintenance, milk systems and current deal options for buyers choosing a compact machine.</p>
  </header>

  <main>
    <section class="comparison-grid">
      <h2>Comparison cards</h2>
      <article class="product-card">
        <h3>DeLonghi Magnifica S</h3>
        <p>Recommended product for buyers who want a reliable automatic espresso machine with frequent discounts.</p>
        <a href="https://www.amazon.com/dp/B00I67TR8A?tag=openutilitydemo-20&ascsubtag=espresso-review">Check price on Amazon</a>
      </article>

      <article class="product-card">
        <h3>Philips 2200 LatteGo</h3>
        <p>Strong alternative, but this deal button uses an opaque redirect before the merchant page.</p>
        <a href="https://tracking.example-aff.net/click?id=88271&url=https%3A%2F%2Fmerchant.example%2Fphilips-2200">View deal</a>
      </article>

      <article class="product-card">
        <h3>Breville Bambino Plus</h3>
        <p>Best premium pick when the price drops, routed through a shortened commercial link.</p>
        <a href="https://bit.ly/bambino-plus-deal">Get deal</a>
      </article>

      <article class="product-card">
        <h3>Krups Essential</h3>
        <p>Recommended budget option with unclear non-monetized routing.</p>
        <a href="/reviews/krups-essential.html">Read the full review</a>
      </article>
    </section>

    <section>
      <h2>Buying notes</h2>
      <p>For most readers, the best value comes from checking the current price, warranty and discount before buying.</p>
      <a href="/go/espresso-machine-deals?intent=buy&product=compact-espresso">Shop now in our espresso machine deal tracker</a>
      <a href="https://merchant.example.com/espresso-machines">Compare merchant catalog</a>
      <a href="https://manufacturer.example.com/support/espresso-machine-care">Manufacturer care notes</a>
    </section>
  </main>

  <footer>
    <p>Some links may be affiliate links. We may receive a commission if you buy through qualifying links.</p>
  </footer>
</body>
</html>"""


def normalize_text(value):
    return re.sub(r"\s+", " ", value or "").strip()


def includes_pattern(value, patterns):
    lower_value = value.lower()
    return [pattern for pattern in patterns if pattern in lower_value]


class DemoParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.title = ""
        self.meta_description = ""
        self.h1_count = 0
        self.links = []
        self._stack = []
        self._current_link = None
        self._current_text = []
        self._all_text = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self._stack.append(tag)
        if tag == "meta" and attrs.get("name") == "description":
            self.meta_description = normalize_text(attrs.get("content", ""))
        if tag == "h1":
            self.h1_count += 1
        if tag == "a" and attrs.get("href"):
            self._current_link = {"href": attrs["href"], "text": ""}
            self._current_text = []

    def handle_endtag(self, tag):
        if tag == "a" and self._current_link is not None:
            self._current_link["text"] = normalize_text(" ".join(self._current_text))
            self._current_link["nearby"] = self._current_link["text"]
            self.links.append(self._current_link)
            self._current_link = None
            self._current_text = []
        if self._stack:
            self._stack.pop()

    def handle_data(self, data):
        text = normalize_text(unescape(data))
        if not text:
            return
        self._all_text.append(text)
        if self._stack and self._stack[-1] == "title":
            self.title = normalize_text(f"{self.title} {text}")
        if self._current_link is not None:
            self._current_text.append(text)

    @property
    def text_scope(self):
        return normalize_text(" ".join(self._all_text))


def is_external_href(href):
    return bool(re.match(r"^https?://", href, re.I))


def is_affiliate_href(href):
    return bool(includes_pattern(href, AFFILIATE_PATTERNS))


def parsed_href(href):
    if href.startswith("/"):
        href = f"https://openutilitylab.local{href}"
    return urlparse(href)


def is_shortener_href(href):
    hostname = parsed_href(href).hostname or ""
    return hostname.removeprefix("www.").lower() in SHORTENER_DOMAINS


def is_opaque_tracking_href(href):
    lower_href = href.lower()
    parsed = parsed_href(href)
    query = parse_qs(parsed.query)
    has_tracking_pattern = any(pattern in lower_href for pattern in OPAQUE_TRACKING_URL_PATTERNS)
    has_go_pattern = bool(re.search(r"(^|[./_-])go([./_-]|$)", lower_href))
    has_tracking_param = any(parameter in query for parameter in OPAQUE_TRACKING_PARAM_PATTERNS)
    return has_tracking_pattern or has_go_pattern or has_tracking_param


def is_commercial_cta_text(text):
    return bool(includes_pattern(text, CTA_PATTERNS))


def is_product_context(text):
    return bool(
        includes_pattern(text, COMMERCIAL_PATTERNS)
        or includes_pattern(text, ["product", "review", "recommended", "recommend", "cafetera", "cafeteras", "machine"])
    )


def count_text_signals(text, patterns):
    lower_text = text.lower()
    return sum(lower_text.count(pattern) for pattern in patterns)


def classify_link(link):
    href = link["href"]
    text = link["text"]
    external = is_external_href(href)
    affiliate = is_affiliate_href(href)
    shortener = is_shortener_href(href)
    opaque = is_opaque_tracking_href(href)
    commercial_cta = is_commercial_cta_text(text)
    product_context = is_product_context(f"{text} {link['nearby']} {href}")

    if affiliate:
        return "Affiliate"
    if shortener:
        return "Shortener"
    if commercial_cta and not external:
        return "Internal commercial CTA"
    if opaque:
        return "Opaque tracking"
    if commercial_cta and external:
        return "Commercial CTA"
    if external:
        return "External non-affiliate"
    if not href or href.startswith("#") or href.startswith("javascript:") or product_context:
        return "Unclear destination"
    return "Unclear destination"


def build_score_breakdown(title, meta_description, metrics):
    return [
        ("Commercial intent", metrics["commercialIntentSignals"]),
        ("Affiliate coverage", metrics["affiliateLookingLinks"]),
        ("CTA clarity", metrics["ctaLookingSignals"]),
        ("Tracking transparency", metrics["opaque_tracking_links"] + metrics["shortener_links"]),
        ("Structure / metadata", int(bool(title)) + int(bool(meta_description)) + metrics["h1Count"]),
    ]


def get_score_band(score):
    if score <= 24:
        return "Low friction"
    if score <= 49:
        return "Moderate friction"
    if score <= 74:
        return "High friction"
    return "Critical friction"


def build_quick_diagnosis(title, source_mode, score, score_band, action_backlog, audited_links):
    top_priority = next((item for item in action_backlog if item["severity"] != "Info"), None)
    return {
        "source": f"{title or 'Untitled page'} from {source_mode.replace('-', ' ')}",
        "scoreBand": f"{score_band} ({score}/100)",
        "topPriorityIssue": f"{top_priority['severity']}: {top_priority['issue']}" if top_priority else "No priority issue detected.",
        "backlogItems": len(action_backlog),
        "auditedLinks": len(audited_links),
    }


def validate_static_ui_strings():
    html = INDEX_HTML.read_text(encoding="utf-8")
    missing = [label for label in EXPECTED_UI_STRINGS if label not in html]
    assert not missing, f"Missing expected UI/report strings: {missing}"


def analyze_demo(html):
    parser = DemoParser()
    parser.feed(html)
    links = parser.links

    affiliate_links = [link for link in links if is_affiliate_href(link["href"])]
    opaque_tracking_links = [link for link in links if is_opaque_tracking_href(link["href"])]
    shortener_links = [link for link in links if is_shortener_href(link["href"])]
    commercial_cta_links = [link for link in links if is_commercial_cta_text(link["text"])]
    internal_commercial_cta_links = [link for link in commercial_cta_links if not is_external_href(link["href"])]
    non_monetized_product_links = [
        link for link in links
        if not is_external_href(link["href"])
        and not is_affiliate_href(link["href"])
        and is_product_context(f"{link['text']} {link['nearby']} {link['href']}")
    ]
    unclear_commercial_ctas = [
        link for link in commercial_cta_links
        if not is_affiliate_href(link["href"])
        and (is_external_href(link["href"]) or is_opaque_tracking_href(link["href"]) or is_shortener_href(link["href"]))
    ]

    metrics = {
        "h1Count": parser.h1_count,
        "totalLinks": len(links),
        "affiliateLookingLinks": len(affiliate_links),
        "weakTrackingLinks": len(opaque_tracking_links),
        "opaque_tracking_links": len(opaque_tracking_links),
        "shortener_links": len(shortener_links),
        "commercial_cta_links": len(commercial_cta_links),
        "internal_commercial_cta_links": len(internal_commercial_cta_links),
        "non_monetized_product_links": len(non_monetized_product_links),
        "unclear_commercial_cta_links": len(unclear_commercial_ctas),
        "ctaLookingSignals": len(commercial_cta_links),
        "commercialIntentSignals": count_text_signals(parser.text_scope, COMMERCIAL_PATTERNS),
    }
    audited_links = [{"text": link["text"], "href": link["href"], "classification": classify_link(link)} for link in links]
    score_breakdown = build_score_breakdown(parser.title, parser.meta_description, metrics)

    findings = []
    if metrics["commercialIntentSignals"] > 0 and metrics["affiliateLookingLinks"] == 0:
        findings.append("Commercial intent appears present, but no strong affiliate-looking links were detected.")
    if metrics["opaque_tracking_links"] > 0:
        findings.append("Opaque tracking or redirect link detected")
    if metrics["shortener_links"] > 0:
        findings.append("Shortened commercial link detected")
    if metrics["unclear_commercial_cta_links"] > 0:
        findings.append("Commercial CTA points to non-affiliate or unclear destination")
    if metrics["non_monetized_product_links"] > 0 or metrics["internal_commercial_cta_links"] > 0:
        findings.append("Recommended product appears to use an internal/non-monetized link")
    if not findings:
        findings.append("No major local friction pattern was detected from the observable HTML signals.")
    action_backlog = [{"severity": "High", "issue": finding, "suggestedFix": "Review the detected link or page section.", "whyItMatters": "Observable HTML suggests a friction pattern."} for finding in findings]

    score = 100
    score += 2 if parser.title else -8
    score += 2 if parser.meta_description else -8
    score += 2 if metrics["h1Count"] == 1 else (-8 if metrics["h1Count"] == 0 else -5)
    if metrics["affiliateLookingLinks"] > 0:
        score += 3
    if metrics["ctaLookingSignals"] > 0:
        score += min(3, metrics["ctaLookingSignals"])
    if metrics["commercialIntentSignals"] > 0 and metrics["affiliateLookingLinks"] == 0:
        score -= 18
    if metrics["opaque_tracking_links"] > 0:
        score -= min(20, metrics["opaque_tracking_links"] * 10)
    if metrics["shortener_links"] > 0:
        score -= min(14, metrics["shortener_links"] * 10)
    if metrics["unclear_commercial_cta_links"] > 0:
        score -= min(14, metrics["unclear_commercial_cta_links"] * 7)
    if metrics["internal_commercial_cta_links"] > 0:
        score -= min(8, metrics["internal_commercial_cta_links"] * 4)
    if metrics["non_monetized_product_links"] > 0:
        score -= min(10, metrics["non_monetized_product_links"] * 5)
    score = max(0, min(100, round(score)))
    score_band = get_score_band(score)
    quick_diagnosis = build_quick_diagnosis(
        parser.title,
        "demo-html",
        score,
        score_band,
        action_backlog,
        audited_links,
    )

    return {
        "metrics": metrics,
        "findings": findings,
        "actionBacklog": action_backlog,
        "auditedLinks": audited_links,
        "scoreBreakdown": score_breakdown,
        "scoreBand": score_band,
        "quickDiagnosis": quick_diagnosis,
        "score": score,
    }


validate_static_ui_strings()
report = analyze_demo(DEMO_HTML)

assert report["metrics"]["affiliateLookingLinks"] == 1, report
assert report["metrics"]["weakTrackingLinks"] >= 1, report
assert report["metrics"]["shortener_links"] >= 1, report
assert len(report["findings"]) >= 3, report
assert len(report["auditedLinks"]) == report["metrics"]["totalLinks"], report
assert {link["classification"] for link in report["auditedLinks"]} >= {
    "Affiliate",
    "Opaque tracking",
    "Shortener",
    "Internal commercial CTA",
    "External non-affiliate",
    "Unclear destination",
}, report
assert [block[0] for block in report["scoreBreakdown"]] == [
    "Commercial intent",
    "Affiliate coverage",
    "CTA clarity",
    "Tracking transparency",
    "Structure / metadata",
], report
assert all({"severity", "issue", "suggestedFix", "whyItMatters"} <= set(item) for item in report["actionBacklog"]), report
assert report["score"] < 80, report
assert report["scoreBand"] == "High friction", report
assert report["quickDiagnosis"]["scoreBand"] == f"High friction ({report['score']}/100)", report
assert report["quickDiagnosis"]["topPriorityIssue"].startswith("High:"), report
assert report["quickDiagnosis"]["backlogItems"] == len(report["actionBacklog"]), report
assert report["quickDiagnosis"]["auditedLinks"] == len(report["auditedLinks"]), report
assert {get_score_band(score) for score in [0, 24, 25, 49, 50, 74, 75, 100]} == {
    "Low friction",
    "Moderate friction",
    "High friction",
    "Critical friction",
}
assert "No major local friction pattern was detected from the observable HTML signals." not in report["findings"], report

print(json.dumps({
    "score": report["score"],
    "scoreBand": report["scoreBand"],
    "quickDiagnosis": report["quickDiagnosis"],
    "affiliateLookingLinks": report["metrics"]["affiliateLookingLinks"],
    "weakTrackingLinks": report["metrics"]["weakTrackingLinks"],
    "shortenerLinks": report["metrics"]["shortener_links"],
    "auditedLinkClassifications": [link["classification"] for link in report["auditedLinks"]],
    "scoreBreakdown": [block[0] for block in report["scoreBreakdown"]],
    "findings": report["findings"],
}, indent=2, ensure_ascii=False))
