# BTC 15m Arena - Bounded Endpoint Probe Evidence Schema V1

Date: 2026-06-16
Mode: docs-only evidence schema.

## Scope

This document records the technical evidence produced by the bounded public read-only endpoint probe chain.

It does not authorize:
- wallet integration;
- private keys;
- API keys;
- authenticated trading API;
- orders;
- order creation;
- order placement;
- order submission;
- order execution;
- runtime loop;
- collector;
- bot;
- fixture promotion;
- snapshot persistence;
- trading signals;
- financial advice;
- profit claims;
- guaranteed prediction.

The evidence is technical endpoint evidence only.

## Source phases

1. BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_ENDPOINT_PROBE_EXECUTION_V2_CONVERTFROM_JSON_COMPAT_REPAIR
   - Result: PASS.
   - Gamma public GET candidates: 7.
   - CLOB public /book lookup: 1.
   - JSON parser mode: without_depth.
   - JSON parse failures: 0.

2. BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_ENDPOINT_PROBE_EXECUTION_REVIEW_AND_EVIDENCE_CLASSIFICATION_V1
   - Result: PASS_EVIDENCE_CLASSIFIED_WITH_LIMITATIONS.
   - New market-data requests in review: 0.
   - Evidence classified as public read-only schema evidence with limitations.

## Request counters from execution V2

| Counter | Value |
|---|---:|
| endpoint probe count | 8 |
| Gamma request count | 7 |
| CLOB book request count | 1 |
| public smoke request count | 0 |
| total market-data request count | 8 |
| post request count | 0 |
| websocket count | 0 |
| auth request count | 0 |
| wallet request count | 0 |
| order request count | 0 |
| runtime loop count | 0 |
| collector count | 0 |
| bot count | 0 |
| fixture created | false |
| snapshot persisted | false |
| repo files written during execution | false |

## Gamma event-by-slug evidence

Classification: PUBLIC_GAMMA_EVENT_BY_SLUG_EVIDENCE

Observed shape:
- event object;
- markets array.

Observed event and market fields:
- question;
- slug;
- closed;
- active;
- enableOrderBook;
- clobTokenIds;
- outcomes.

Resolution method observed:
- deterministic BTC 15m slug candidates;
- zero-offset current-window selection when multiple eligible active candidates exist.

Selected evidence:
- selected slug: btc-updown-15m-1781563500;
- selected candidate offset: 0;
- selected candidate start UTC: 2026-06-15T22:45:00Z;
- selected market question: Bitcoin Up or Down - June 15, 6:45PM-7:00PM ET;
- successful eligible event candidates: 5;
- Gamma HTTP 200 responses: 7;
- Gamma parser failures: 0.

## Token resolution evidence

Observed token mapping:
- resolved outcome: Up;
- resolved token id: 52684956875620686798621800251931814130623729779789360539216085234145021811266;
- observed Down token id: 68696989398832821244153406129746252747346557543958885006106984808482906988955;
- resolution method: exact_outcome_up_or_yes.

Validation:
- Up and Down token ids are decimal token ids;
- Up and Down token ids differ;
- the resolved Up token id was used for one CLOB /book lookup.

## CLOB /book evidence

Classification: PUBLIC_CLOB_BOOK_EVIDENCE

Observed shape:
- book object;
- bids array;
- asks array.

Observed book fields:
- market;
- asset_id;
- timestamp;
- hash;
- min_order_size;
- tick_size;
- neg_risk;
- bids;
- asks.

Observed level fields:
- price;
- size.

Observed CLOB book summary:
- status code: 200;
- parse ok: true;
- parser mode: without_depth;
- market: 0x9f9cc84e9f349f4391a50d01adc9bddbca278115326af267cdb94dd7cb36ed9d;
- asset id: 52684956875620686798621800251931814130623729779789360539216085234145021811266;
- timestamp: 1781563623675;
- hash: d78108b9412936dfcca5cee856dae75a94552665;
- min order size: 5;
- tick size: 0.01;
- negative risk: False;
- bids count: 36;
- asks count: 63;
- runner-observed best bid price: 0.01;
- runner-observed best bid size: 9841.2;
- runner-observed best ask price: 0.99;
- runner-observed best ask size: 9068.66;
- runner-observed spread: 0.98;
- runner-observed mid: 0.5.

Important limitation:
The best bid, best ask, spread and mid values above are runner-observed endpoint evidence from one moment. They are not trading-grade quote logic, not a recommendation, not a signal, and not financial advice.

## Limitations

The reviewed evidence has these limitations:
- single observation;
- single selected market;
- single CLOB token lookup;
- Down token book was not queried;
- book-level ordering semantics were not formally documented by this review;
- best bid / best ask labels are runner-observed values only;
- endpoint payload timestamp is not a local clock audit;
- evidence was not persisted as a fixture or snapshot;
- evidence exists as stdout-derived review material;
- any persistence requires a separate contract or precheck.

## Schema acceptance for future work

This evidence is sufficient to document:
- the observed Gamma event-by-slug schema;
- the observed token mapping path;
- the observed CLOB /book schema;
- the limitations and next boundary.

This evidence is not sufficient to authorize:
- collector;
- runtime loop;
- bot;
- fixture promotion;
- snapshot persistence;
- wallet/API/order logic;
- trading signals;
- financial advice;
- profit claims;
- guaranteed prediction.

## Allowed next boundary

The next safe frontier after this docs-only schema artifact is a controlled commit/push phase for this document only.

Recommended next phase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_ENDPOINT_PROBE_EVIDENCE_SCHEMA_DOCS_ONLY_COMMIT_PUSH_V1

That phase must:
- validate baseline;
- validate this artifact only;
- stage only this markdown file;
- commit only this markdown file;
- push to origin/main;
- confirm HEAD equals origin/main;
- confirm working tree clean.

## Explicit prohibitions remain active

The project still prohibits:
- wallet connection;
- private keys;
- API keys;
- authenticated trading API;
- order creation;
- order placement;
- order execution;
- automated trading;
- live trading;
- trading signals;
- financial advice;
- guaranteed profit;
- guaranteed prediction;
- collector/runtime/bot without a future explicit contract and precheck.
