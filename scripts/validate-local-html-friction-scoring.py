#!/usr/bin/env python3

"""Validate LOCAL_HTML_FRICTION_SCORING_CALIBRATION_V1 with a static demo fixture."""

import json
import re
from html import unescape
from html.parser import HTMLParser
from urllib.parse import parse_qs, urlparse


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

DEMO_HTML = """<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <title>Mejores cafeteras automáticas calidad-precio 2026</title>
  <meta name="description" content="Comparativa de cafeteras automáticas con ofertas actualizadas.">
</head>
<body>
  <header>
    <h1>Mejores cafeteras automáticas calidad-precio 2026</h1>
    <p>Analizamos modelos populares y ofertas recomendadas.</p>
  </header>

  <main>
    <section>
      <h2>Top recomendado</h2>
      <article>
        <h3>DeLonghi Magnifica S</h3>
        <p>Buena opción para usuarios que quieren café automático sin complicaciones.</p>
        <a href="https://www.amazon.es/dp/B00I67TR8A?tag=demoaff-21">Ver oferta en Amazon</a>
      </article>

      <article>
        <h3>Philips Serie 2200</h3>
        <p>Modelo muy buscado, pero el enlace actual pasa por una redirección poco clara.</p>
        <a href="https://tracking.example-aff.net/click?id=88271&url=https%3A%2F%2Ftienda.example.com%2Fphilips-2200">Comprobar precio</a>
      </article>

      <article>
        <h3>Krups Roma EA8108</h3>
        <p>Producto recomendado, pero sin enlace monetizado directo.</p>
        <a href="/reviews/krups-roma-ea8108.html">Leer análisis completo</a>
      </article>
    </section>

    <section>
      <h2>Ofertas rápidas</h2>
      <ul>
        <li><a href="https://www.amazon.es/gp/product/B07XYZ123?tag=demoaff-21">Oferta cafetera compacta</a></li>
        <li><a href="https://short.ly/oferta-cafe-2026">Oferta limitada</a></li>
        <li><a href="https://example.com/deal?id=broken-product">Ver descuento</a></li>
      </ul>
    </section>

    <section>
      <h2>Preguntas frecuentes</h2>
      <p>¿Cuál comprar? Depende del presupuesto, mantenimiento y tipo de café.</p>
      <a href="/categoria/cafeteras/">Ver más cafeteras</a>
    </section>
  </main>

  <footer>
    <p>Algunos enlaces pueden ser de afiliado. Podemos recibir comisión si compras.</p>
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

    return {"metrics": metrics, "findings": findings, "score": score}


report = analyze_demo(DEMO_HTML)

assert report["metrics"]["affiliateLookingLinks"] == 2, report
assert report["metrics"]["weakTrackingLinks"] >= 1, report
assert report["metrics"]["shortener_links"] >= 1, report
assert len(report["findings"]) >= 3, report
assert report["score"] < 80, report
assert "No major local friction pattern was detected from the observable HTML signals." not in report["findings"], report

print(json.dumps({
    "score": report["score"],
    "affiliateLookingLinks": report["metrics"]["affiliateLookingLinks"],
    "weakTrackingLinks": report["metrics"]["weakTrackingLinks"],
    "shortenerLinks": report["metrics"]["shortener_links"],
    "findings": report["findings"],
}, indent=2, ensure_ascii=False))
