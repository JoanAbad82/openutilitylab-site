# BTC 15m Arena — Live Data Source Contract V1

Date: 2026-06-08

Microphase:
$Phase

Mode:
Docs-only source contract.

Repository baseline:
- Expected branch: main
- Expected HEAD: $ExpectedHead
- Expected origin/main: $ExpectedHead

## 1) Purpose

This document defines the first allowed live/data contract for BTC 15m Arena.

The selected product slice is:

READ_ONLY_BTC_15M_MARKET_SNAPSHOT

The purpose is to resolve the current or nearest BTC 15m binary market and display a read-only market snapshot with execution-risk context.

This document does not authorize implementation. It only authorizes a future read-only probe phase if reviewed and accepted.

## 2) Core boundary

Allowed direction:

- read-only market discovery;
- read-only token ID resolution;
- read-only orderbook/price/spread inspection;
- read-only staleness and liquidity warnings;
- no wallet;
- no private keys;
- no API keys;
- no authenticated trading API;
- no order creation;
- no order placement;
- no order execution;
- no cancellations;
- no trading automation;
- no background execution loop;
- no financial advice;
- no guaranteed profit;
- no guaranteed prediction;
- no sure-win strategy;
- no auto hedge;
- no auto arbitrage.

## 3) Source priority

### Priority 1 — Gamma API markets/events discovery

Role:
Find the current or nearest BTC 15m market/event and extract stable identifiers needed by downstream read-only book/price calls.

Candidate public endpoints to verify in the next probe phase:

- https://gamma-api.polymarket.com/events
- https://gamma-api.polymarket.com/markets
- https://gamma-api.polymarket.com/public-search

Candidate query patterns to verify:

- active markets/events only;
- closed markets excluded;
- BTC-related title/question/slug matching;
- 15-minute interval matching;
- nearest unresolved/current event by close/end timestamp.

Expected candidate fields:

- event id;
- event slug;
- event title;
- market id;
- market question/title;
- market slug;
- active/closed/resolved flags;
- end/close timestamp;
- outcomes;
- token IDs or clob token IDs;
- condition id if available;
- volume/liquidity fields if public and stable.

Contract note:
Field names may drift. The next probe phase must inspect actual response shape before implementation.

### Priority 2 — CLOB public orderbook/price/spread endpoints

Role:
Given token IDs from Gamma discovery, read public book/price data to compute execution-risk context.

Candidate public endpoints to verify in the next probe phase:

- https://clob.polymarket.com/book
- https://clob.polymarket.com/price
- any documented public CLOB read endpoint for spread/midpoint if stable and no-auth.

Allowed read-only inputs:

- token id;
- side parameter if required by endpoint;
- public book bids;
- public book asks;
- public best bid;
- public best ask;
- public spread;
- public midpoint if available;
- public last trade price if included in book response.

Expected derived fields:

- best bid;
- best ask;
- spread;
- midpoint if derivable;
- top-of-book available size;
- shallow-depth warning;
- stale snapshot warning;
- missing-side warning;
- execution gap warning.

### Priority 3 — Data API / price history

Role:
Optional historical context only after the current snapshot contract is stable.

Not required for the first implementation.

### Priority 4 — third-party datasets

Role:
Backtesting or research only.

Explicitly deferred for the first live/data UI slice because it may be stale, heavy, or inconsistent with the current public market state.

## 4) First snapshot contract

The first read-only snapshot should produce these output groups.

### Market identity

- market/event title;
- binary outcome labels;
- active/closed/resolved status;
- scheduled close/end time;
- snapshot timestamp;
- source timestamp if provided.

### Token resolution

- token ID for UP/YES-like side;
- token ID for DOWN/NO-like side;
- mapping confidence;
- fallback status if mapping is ambiguous.

### Book/price snapshot

Per side:

- best bid;
- best ask;
- top-of-book spread;
- top-of-book visible size if available;
- shallow book warning if depth is poor;
- missing bid/ask warning if one side is empty.

### Risk context

Allowed labels:

- READ_ONLY_MARKET_SNAPSHOT
- STALE_SNAPSHOT_WARNING
- THIN_BOOK_WARNING
- WIDE_SPREAD_WARNING
- MISSING_SIDE_WARNING
- EXECUTION_GAP_WARNING
- MARKET_NOT_FOUND
- AMBIGUOUS_MARKET_MATCH
- MARKET_CLOSED_OR_RESOLVED

Forbidden labels:

- BUY_SIGNAL
- SELL_SIGNAL
- PLACE_ORDER
- EXECUTE_ORDER
- AUTO_HEDGE
- AUTO_ARBITRAGE
- GUARANTEED_PROFIT
- RISK_FREE
- SURE_WIN

## 5) Staleness rules

A future implementation must display staleness explicitly.

Candidate staleness states:

- fresh: snapshot age <= 15 seconds;
- caution: snapshot age > 15 seconds and <= 60 seconds;
- stale: snapshot age > 60 seconds;
- unknown: source timestamp unavailable.

Important:
These thresholds are UI risk labels, not trading signals.

No automatic polling is authorized by this contract.

A future implementation may use manual refresh only unless a separate phase explicitly authorizes controlled polling.

## 6) Manual refresh only

First implementation must prefer manual refresh.

Allowed:

- user clicks refresh;
- one request flow resolves market identity and book/price snapshot;
- result is rendered as a read-only snapshot.

Not allowed:

- setInterval polling;
- setTimeout polling loop;
- WebSocket stream;
- background bot;
- automated hedge;
- automated order tracking;
- account/wallet state;
- private authenticated state.

## 7) Safety and compliance guardrails

Every live/data UI result must include:

Read-only public market snapshot. No wallet. No orders. No live trading. No financial advice.

Every result must avoid:

- direct trading instructions;
- buy/sell language;
- "you should enter";
- "you should hedge";
- "guaranteed";
- "risk-free";
- "sure win";
- "signal";
- "edge" as a promise;
- "profit locked" without simulated/assumption-dependent qualifier.

Preferred wording:

- candidate;
- warning;
- snapshot;
- assumption-dependent;
- public data;
- visible liquidity;
- executable price may differ;
- not a trading instruction.

## 8) Failure modes

A future implementation must handle these states explicitly:

1. Documentation unreachable during probe.
2. Gamma discovery returns no BTC 15m candidate.
3. Gamma discovery returns multiple ambiguous candidates.
4. Candidate market is closed/resolved.
5. Token IDs are missing or ambiguous.
6. CLOB book endpoint returns non-2xx.
7. CLOB price endpoint returns non-2xx.
8. Book has missing bids.
9. Book has missing asks.
10. Book has very shallow visible size.
11. Timestamp missing.
12. Snapshot stale.
13. CORS or browser access blocks direct client-side request.
14. Public endpoint schema differs from documentation.
15. Any response suggests authenticated trading endpoint requirement.

Failure behavior:
Show a read-only warning and do not produce a trading signal.

## 9) CORS and architecture decision point

The next probe must determine whether direct browser access is viable.

Possible outcomes:

### Outcome A — direct browser read is viable

A later implementation may read public endpoints client-side if:

- no keys are required;
- CORS allows it;
- endpoints remain public;
- no authenticated headers are needed;
- no order endpoint is touched.

### Outcome B — direct browser read is blocked by CORS

Do not workaround with secrets in frontend.

Allowed next decisions:

- keep the product static/manual;
- create a serverless read-only proxy in a separate authorized phase;
- keep proxy strictly no-auth/no-orders/no-wallet;
- document rate limits and caching.

Not authorized here:

- adding keys;
- authenticated CLOB;
- wallet auth;
- order endpoints;
- private user state;
- backend trading logic.

## 10) Acceptance tests for next read-only probe

The next phase should be:

BTC_15M_ARENA_LIVE_DATA_SOURCE_PROBE_READ_ONLY_V1

That phase should:

- validate repository baseline;
- perform no writes;
- perform no stage;
- perform no commit;
- perform no push;
- probe official docs;
- probe Gamma discovery endpoint shape;
- identify whether a BTC 15m market can be found deterministically;
- inspect fields needed for token ID resolution;
- probe CLOB public book/price endpoint shape using token IDs only if safely available;
- avoid authenticated endpoints;
- avoid private headers;
- avoid wallet/API/order logic;
- print response field summaries, not massive raw payloads;
- classify failures as source/shape/CORS/rate-limit/auth-boundary issues;
- recommend implementation only if source contract is technically viable.

## 11) Non-goals

This contract does not authorize:

- implementation;
- route edits;
- JS edits;
- UI changes;
- live polling;
- WebSocket;
- bots;
- scraping;
- wallet connection;
- private keys;
- API keys;
- authenticated CLOB trading;
- order creation;
- order placement;
- order cancellation;
- order execution;
- trading automation;
- real-time trading signals;
- financial advice;
- guaranteed prediction;
- guaranteed profit;
- auto hedge;
- auto arbitrage.

## 12) File scope for this phase

Allowed in this phase:

- create this document only:
  - project_sources/btc-15m-arena/BTC_15M_ARENA_LIVE_DATA_SOURCE_CONTRACT_V1.md

Not allowed in this phase:

- tc-15m-arena/index.html
- tc-15m-arena/scenario-calculator.js
- tc-15m-arena/fixtures/static-scenarios.v1.json
- tc-15m-arena/fixture-replay.js
- tc-15m-arena/fixtures/static-scenarios.v1.js
- index.html
- sitemap.xml
- styles.css
- obots.txt
- README.md
- package files
- scripts
- src
- public
- dist
- other products.

## 13) Recommended next phase

If this docs-only contract passes local review:

BTC_15M_ARENA_LIVE_DATA_SOURCE_CONTRACT_DOCS_ONLY_COMMIT_PUSH_V1

After commit/push, the next technical read-only phase should be:

BTC_15M_ARENA_LIVE_DATA_SOURCE_PROBE_READ_ONLY_V1

## 14) Closure note

This artifact is a source contract only.

It does not implement live data.

It does not connect to Polymarket.

It does not touch wallet, API keys, private keys, orders, order execution, trading automation or trading advice.

No implementation is authorized by this document.