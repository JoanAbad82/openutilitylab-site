# BTC 15m Arena — Live Data Source Discovery Result Classification V1

Status: docs-only classification.
Date: 2026-06-08.
Repository: C:\openutilitylab-site.
Baseline expected before this classification: HEAD equals origin/main equals fe8ce89.

This document classifies the result of:

BTC_15M_ARENA_LIVE_DATA_SOURCE_DISCOVERY_PROBE_READ_ONLY_V4_PRECISE_BTC_15M_RESOLVER

This document does not authorize implementation.

No runtime fetch is authorized.
No UI live data is authorized.
No polling is authorized.
No WebSocket is authorized.
No serverless proxy is authorized.
No bot is authorized.
No wallet is authorized.
No private keys are authorized.
No API keys are authorized.
No authenticated trading API is authorized.
No order creation is authorized.
No order placement is authorized.
No order execution is authorized.
No trading automation is authorized.
No financial advice is authorized.
No guaranteed profit is authorized.
No guaranteed prediction is authorized.

---

## 1. Classification summary

The V4 discovery probe is classified as:

PASS_TECHNICAL_READ_ONLY_WITH_AMBIGUOUS_NON_TARGET_CANDIDATE

Meaning:

- The read-only probe completed safely.
- The repository was not changed.
- Gamma public discovery endpoints were reachable.
- Gamma responses were parseable as JSON.
- Candidate scoring produced BTC-related candidates.
- Token IDs were extracted from a tokenized candidate.
- CLOB public read endpoints were reachable for those token IDs.
- CLOB `/book` returned parseable JSON for those token IDs.
- CLOB `/price?side=BUY` returned parseable JSON for those token IDs.
- CLOB `/price?side=SELL` returned parseable JSON for those token IDs.
- The resolved candidate was not the BTC 15m target market.
- The resolved candidate was ambiguous.
- The score gap was zero.
- Therefore live data implementation remains blocked.

This classification separates:

1. CLOB_ENDPOINTS_REACHABLE
2. BTC_15M_TARGET_MARKET_RESOLVED

V4 established the first item only.

V4 did not establish the second item.

---

## 2. Exact V4 metrics

The V4 read-only discovery probe produced these key metrics:

- total_gamma_response_count=28
- total_market_like_object_count=20006
- deduped_scored_candidate_count=1118
- observations count=1
- warnings count=1
- issues count=0
- resolved_candidate_present=true
- resolved_candidate_score=81
- resolved_candidate_slug=will-bitcoin-hit-150k-by-june-30-2026
- score_gap=0
- unique_token_ids_for_probe=2
- final working tree clean

Classification:

- total_market_like_object_count=20006 is useful discovery coverage.
- deduped_scored_candidate_count=1118 confirms the scoring pipeline produced candidates.
- resolved_candidate_present=true does not imply target resolution.
- unique_token_ids_for_probe=2 confirms token extraction for a tokenized candidate.
- score_gap=0 is BLOCKING_FOR_IMPLEMENTATION.
- warnings count=1 is BLOCKING_FOR_IMPLEMENTATION because the warning concerns candidate ambiguity.
- issues count=0 means the read-only probe itself completed safely, not that live data is ready.

---

## 3. Resolved candidate classification

Resolved candidate:

will-bitcoin-hit-150k-by-june-30-2026

Candidate text:

Will Bitcoin hit $150k by June 30, 2026?

Classification:

NON_TARGET_BTC_LONG_DATE_HIT_PRICE_MARKET

Reason:

- It is BTC-related.
- It has token IDs.
- It is active and tokenized.
- It has Yes/No outcomes.
- It is not a BTC 15m up/down market.
- It is a long-date hit-price market.
- It resolves based on whether BTC reaches a specified high price by a future date.
- It does not represent a short 15-minute up/down window.
- It does not establish the target market identity required for BTC 15m Arena live data.

Decision:

This candidate must not be used for BTC 15m live data implementation.

---

## 4. CLOB result classification

V4 probed CLOB public read endpoints using token IDs from the ambiguous non-target candidate.

Observed CLOB read coverage:

- `/book` status 200 + json=parse_ok
- `/price?side=BUY` status 200 + json=parse_ok
- `/price?side=SELL` status 200 + json=parse_ok

Observed book/price shape included fields such as:

- market
- asset_id
- timestamp
- hash
- bids
- asks
- min_order_size
- tick_size
- neg_risk
- last_trade_price
- price

Classification:

CLOB_SHAPE_OBSERVED_FOR_NON_TARGET_CANDIDATE

Meaning:

- The public CLOB endpoints appear reachable.
- The response shape is technically useful for future planning.
- The result does not validate BTC 15m live data.
- The result does not validate BTC 15m token IDs.
- The result does not validate BTC 15m outcome mapping.
- The result does not validate BTC 15m orderbook depth, price, spread, exit-risk, or staleness behavior.

Decision:

CLOB endpoint reachability is not enough to authorize live data implementation.

---

## 5. Why V4 improved over V3

V3 result:

- total_market_like_object_count=1944
- deduped_candidate_market_count=0
- unique_token_ids_for_probe=0
- CLOB book/price probe status: SKIPPED_BECAUSE_NO_TOKEN_IDS

V4 improvement:

- total_market_like_object_count=20006
- deduped_scored_candidate_count=1118
- resolved_candidate_present=true
- unique_token_ids_for_probe=2
- CLOB `/book` reached and parseable
- CLOB `/price` BUY reached and parseable
- CLOB `/price` SELL reached and parseable

But V4 still did not resolve the target market.

Therefore:

V4 closes the endpoint-shape question partially, but not the target-market question.

---

## 6. Why V4 still blocks implementation

Implementation remains blocked because all of the following are unresolved:

1. No unequivocal BTC 15m candidate was resolved.

2. No BTC 15m market slug was confirmed.

3. No BTC 15m event slug was confirmed.

4. No BTC 15m series slug was confirmed.

5. No BTC 15m condition id was confirmed.

6. No BTC 15m token IDs were confirmed.

7. No UP/DOWN or YES/NO mapping was confirmed for the target.

8. CLOB `/book` was not tested on BTC 15m token IDs.

9. CLOB `/price?side=BUY` was not tested on BTC 15m token IDs.

10. CLOB `/price?side=SELL` was not tested on BTC 15m token IDs.

11. No target staleness policy was validated.

12. No browser CORS feasibility was validated.

13. No serverless proxy need was classified.

14. No target fallback or error-state policy was classified.

15. No live-data UI contract was authorized.

---

## 7. Misclassification risk identified

V4 revealed a concrete scoring risk.

Risk:

A BTC-related market with token IDs can score highly even when it is not a BTC 15m target market.

Example:

will-bitcoin-hit-150k-by-june-30-2026

Why it scored:

- bitcoin
- btc
- price
- token IDs
- binary outcome shape
- active
- closed=false
- accepting_orders=true
- enable_order_book=true

Why this is insufficient:

- It lacks 15m / 15 minute / short-window identity.
- It is a long-date milestone market.
- It uses Yes/No milestone resolution, not Up/Down short-window resolution.
- It is incompatible with the product target.

Required future scoring repair:

A future resolver must penalize or exclude:

- `by June 30, 2026`
- `by [date]`
- `hit $150k`
- `hit $1m`
- long-date strike markets
- milestone markets
- yearly or monthly market windows
- resolution by High price over a long date range
- absence of 15m / 15 minute / next 15 / up or down identity

A future resolver must positively require or seed:

- explicit 15m / 15 minute identity;
- current short-window event or series identity;
- Up/Down or equivalent short-window binary outcome;
- token IDs from that target market only.

---

## 8. Acceptance criteria before live data implementation

Live data implementation may not begin until all of the following are documented:

1. TARGET_MARKET_CONFIRMED

2. TARGET_MARKET_IS_BTC_15M

3. TARGET_MARKET_NOT_LONG_DATE_HIT_PRICE_MARKET

4. TARGET_MARKET_SLUG_CONFIRMED

5. TARGET_EVENT_OR_SERIES_CONFIRMED, if applicable

6. TARGET_CONDITION_ID_CONFIRMED, if available

7. TOKEN_IDS_CONFIRMED_FOR_TARGET

8. OUTCOME_MAPPING_CONFIRMED

9. CLOB_BOOK_CONFIRMED_FOR_TARGET

10. CLOB_BUY_PRICE_CONFIRMED_FOR_TARGET

11. CLOB_SELL_PRICE_CONFIRMED_FOR_TARGET

12. EMPTY_BOOK_OR_NON_2XX_FAILURE_MODES_CLASSIFIED

13. STALENESS_POLICY_DEFINED

14. BROWSER_OR_PROXY_FEASIBILITY_CLASSIFIED

15. FALLBACK_AND_ERROR_STATES_DEFINED

16. GUARDRAILS_PRESERVED

17. NO_WALLET_API_ORDER_LOGIC_CONFIRMED

Only after those criteria pass may a later phase discuss live-data UI design.

Even then, implementation must remain read-only and must not include wallet, private keys, API keys, authenticated trading API, orders, execution, or automation.

---

## 9. Recommended next discovery path

This classification recommends one of two future read-only discovery paths.

### Option A — Seeded discovery

Recommended phase:

BTC_15M_ARENA_LIVE_DATA_SOURCE_SEEDED_DISCOVERY_PROBE_READ_ONLY_V1

Use this if the user provides a current Polymarket BTC 15m URL, market slug, event slug, or series slug.

Purpose:

- Start from a known candidate.
- Resolve the public Gamma object.
- Extract token IDs.
- Map outcomes.
- Probe CLOB only for the seeded target.
- Avoid broad search ranking mistakes.

This is the preferred path if a current target URL/slug is available.

### Option B — Series/tag resolver

Recommended phase:

BTC_15M_ARENA_LIVE_DATA_SOURCE_DISCOVERY_PROBE_READ_ONLY_V5_SERIES_OR_TAG_RESOLVER

Use this if no manual seed is available.

Purpose:

- Discover the correct BTC 15m event/series/tag structure.
- Avoid broad search results.
- Exclude long-date hit-price markets.
- Require explicit short-window identity before selecting token IDs.
- Probe CLOB only after target confirmation.

This is the preferred path if discovery must remain fully automated.

---

## 10. Explicit non-authorization

This document does not authorize:

- editing btc-15m-arena/index.html;
- editing scenario-calculator.js;
- adding runtime Gamma fetch;
- adding runtime CLOB fetch;
- adding live snapshot UI;
- adding polling;
- adding WebSocket;
- adding EventSource;
- adding serverless proxy;
- adding manual refresh live mode;
- adding browser fetch to Polymarket;
- adding backend functions;
- adding API keys;
- adding private keys;
- adding wallet connection;
- adding authenticated trading API;
- adding account state;
- adding order state;
- creating orders;
- placing orders;
- executing orders;
- cancelling orders;
- trading automation;
- bots;
- financial advice;
- guaranteed profit claims;
- guaranteed prediction claims.

---

## 11. Final decision

Final classification:

V4 is a technical read-only PASS.

V4 is not a target-resolution PASS.

V4 is not an implementation-unblocking PASS.

Live data remains blocked.

Next phase must be either:

- seeded read-only discovery, if a target URL/slug is available; or
- V5 series/tag read-only resolver, if no target seed is available.

No implementation may start from V4 alone.
