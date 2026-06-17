# BTC 15m Arena - Bounded Dual Token Book Probe Contract V1

Date: 2026-06-17
Mode: docs-only contract.

## Purpose

This contract defines the boundary for a future bounded public read-only dual-token book probe for one BTC 15m market.

The future probe is intended to compare the public CLOB /book shape for both outcome tokens:
- Up token;
- Down token.

This document does not execute that probe.

## Baseline evidence

The prior evidence schema chain is closed at commit:
e1222e464c22ebe9e1faa4e923e1a859c5e77f62

The prior schema artifact is:
project_sources/btc-15m-arena/BTC_15M_ARENA_BOUNDED_ENDPOINT_PROBE_EVIDENCE_SCHEMA_V1.md

The prior schema established:
- PUBLIC_GAMMA_EVENT_BY_SLUG_EVIDENCE;
- PUBLIC_CLOB_BOOK_EVIDENCE;
- token mapping from Gamma outcomes and clobTokenIds;
- one public CLOB /book lookup for the resolved Up token;
- no wallet/API/order logic;
- no collector;
- no runtime loop;
- no bot;
- no fixture or snapshot authorization.

## Reason for this contract

The prior evidence has explicit limitations:
- single observation;
- single selected market;
- single CLOB token lookup;
- Down token book was not queried;
- book-level ordering semantics were not formally documented;
- runner-observed best bid / best ask were not trading-grade quote logic.

Therefore any future Up/Down comparison requires a separate bounded contract before any market-data request.

## Future probe authorization boundary

This contract may authorize only a future read-only execution phase after separate user approval.

The future execution phase, if opened, must be bounded as follows:

### Gamma public requests

Maximum Gamma public event-or-market resolution requests:
7

Allowed reason:
- resolve one active BTC 15m market by deterministic slug candidates;
- retrieve market metadata needed to map Up and Down token ids.

Disallowed:
- broad crawling;
- polling loop;
- recurring collector;
- background monitor;
- authenticated API.

### CLOB public book requests

Maximum CLOB public /book requests:
2

Allowed reason:
- exactly one /book request for the Up token;
- exactly one /book request for the Down token.

Disallowed:
- repeated retries beyond abort rules;
- full order book collector;
- live loop;
- websocket;
- persistence as fixture or snapshot unless separately authorized.

### Total public market-data requests

Maximum total public market-data requests:
9

Breakdown:
- up to 7 Gamma requests;
- up to 2 CLOB /book requests.

## Timeouts and abort conditions

Timeout per future public request:
10 seconds

Abort immediately if any of these occur:
- repo baseline mismatch;
- origin/main mismatch;
- working tree dirty before execution;
- selected market cannot be resolved within request cap;
- Up token id cannot be resolved exactly;
- Down token id cannot be resolved exactly;
- Up and Down token ids are equal;
- CLOB /book status is not 200;
- CLOB /book JSON cannot be parsed;
- book response missing bids or asks arrays;
- response shape changes materially;
- any authentication, wallet, order, websocket, POST, or polling path is encountered;
- any file persistence is attempted without separate authorization.

## Allowed future evidence

A future execution phase may print technical stdout evidence only:
- selected slug;
- selected market question;
- selected market id or condition id if present;
- Up token id;
- Down token id;
- request counters;
- CLOB /book status for Up;
- CLOB /book status for Down;
- bids and asks count for each token;
- endpoint-provided fields such as market, asset_id, timestamp, hash, tick_size, min_order_size, neg_risk;
- runner-observed best bid / best ask summaries if clearly labeled as non-trading-grade endpoint evidence.

## Explicit non-authorization

This contract does not authorize:
- wallet integration;
- private keys;
- API keys;
- authenticated trading API;
- order creation;
- order placement;
- order submission;
- order execution;
- live trading;
- automated trading;
- trading signals;
- financial advice;
- profit claims;
- guaranteed prediction;
- collector;
- runtime loop;
- bot;
- websocket;
- POST requests;
- background polling;
- fixture creation;
- snapshot persistence;
- repo writes during execution;
- UI changes;
- code implementation.

## Quote logic warning

Any future best bid, best ask, spread, mid or depth summary is technical endpoint evidence only.

It must not be presented as:
- a trading signal;
- a recommendation;
- financial advice;
- quote logic suitable for real orders;
- guaranteed executable outcome;
- profit prediction.

## Future execution phase requirements

A future execution phase must:
- validate HEAD and origin/main before requests;
- validate working tree clean before requests;
- print request counters;
- keep wallet/API/order counters at zero;
- keep POST/websocket/runtime/collector/bot counters at zero;
- avoid file writes unless separately authorized;
- end with explicit RESULT=PASS or RESULT=NO_PASS;
- recommend a review phase before any persistence or downstream use.

## Next allowed phase after this docs-only contract

If this contract is created locally and reviewed as PASS, the next allowed phase is a controlled commit/push for this document only:

BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_DUAL_TOKEN_BOOK_PROBE_CONTRACT_DOCS_ONLY_COMMIT_PUSH_V1

That commit/push phase must stage only:
project_sources/btc-15m-arena/BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_DUAL_TOKEN_BOOK_PROBE_CONTRACT_V1.md

## Still blocked after this contract

Even after this document exists, the following remain blocked until separately authorized:
- actual dual-token probe execution;
- snapshot persistence;
- fixture promotion;
- collector;
- runtime loop;
- bot;
- live data loop;
- wallet/API/order logic;
- trading signals;
- financial advice;
- real orders.
