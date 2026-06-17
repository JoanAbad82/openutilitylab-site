# BTC 15m Arena - Bounded Live-Data Loop Contract V1

Status: docs-only contract.
Date: 2026-06-17.
Project: BTC 15m Arena.
Mode: read-only planning.

## 1. Purpose

This document defines the bounded live-data loop contract for a future phase.

The purpose is bounded read-only market-data loop planning.

It may be used to plan a later single-run or bounded loop that reads a fresh BTC Up/Down 15m market and its two CLOB book sides under strict request caps.

This document does not execute requests.
This document does not implement a loop.
This document does not create a collector.
This document does not create a runtime.
This document does not create a bot.

## 2. Non-purpose

This contract is not trading.
This contract is not financial advice.
This contract is not a trading signal.
This contract is not a prediction.
This contract is not live trading.
This contract is not automated trading.
This contract is not wallet integration.
This contract is not order logic.
This contract is not snapshot creation.
This contract is not fixture creation.
This contract is not replay generation.
This contract is not a collector output.
This contract is not a runtime output.
This contract is not a bot output.

## 3. Guardrails

No wallet.
No private keys.
No authenticated trading API.
No real orders.
No order creation.
No order placement.
No order execution.
No trading automation.
No live trading.
No trading signals.
No financial advice.
No profit claims.
No guaranteed profit.
No guaranteed prediction.

## 4. Endpoint templates for a future authorized phase

Gamma endpoint template:
https://gamma-api.polymarket.com/events?slug=<fresh_btc_updown_15m_slug>

CLOB book endpoint template:
https://clob.polymarket.com/book?token_id=<fresh_token_id>

These templates are documentation only in this phase.
No Gamma request is authorized by this document.
No CLOB book request is authorized by this document.

## 5. Request caps for a future authorized phase

Gamma requests per run:
1

CLOB book requests per tick:
2

Maximum ticks per run:
3

Maximum total market-data HTTP requests per run:
7

Calculation:
1 Gamma request plus 2 CLOB book requests per tick multiplied by 3 ticks equals 7 total market-data HTTP requests.

HTTP timeout:
10 seconds per request.

Minimum tick interval:
20 seconds.

The caps above are maximums for a future explicitly authorized execution phase. They are not authorization to execute in this docs-only phase.

## 6. Target selection policy

Target policy:
fresh_window_only_aligned_900_seconds_not_closed_not_reused

A future target must be:
- fresh;
- BTC Up/Down 15m;
- aligned to a 900 second window;
- not closed at selection;
- not archived at selection;
- eligible for order book inspection as a read-only public data source;
- resolved through public Gamma before CLOB book use;
- mapped to two outcomes before any book tick;
- mapped to two distinct token ids before any book tick.

A future target must not reuse:
- closed slug: btc-updown-15m-1781708400
- closed Up token id: 42082333147465454912145556211445121129676724086717569761807000971672053767352
- closed Down token id: 45319980697747047378266542514078429282204322526025589645289739305457177753107

Closed market data is retained only as technical endpoint evidence.
Closed market data is not a stable fixture.
Closed market data is not replay data.
Closed market data is not a future target.

## 7. Prerequisites before any future CLOB book tick

Before any future CLOB book tick:
- fresh market resolution must pass;
- outcomes must be mapped;
- dual token ids must be present;
- Up and Down token ids must be distinct;
- the target must not be closed;
- the closed V3 slug must not be reused;
- the closed V3 token ids must not be reused;
- request caps must be printed before requests;
- no wallet, order, auth, collector, runtime, bot or signal path may be active.

## 8. Retention policy

Default persistence:
none

Raw stdout artifact:
false by default.

Snapshot:
false by default.

Fixture:
false by default.

Collector:
false by default.

Runtime loop:
false by default.

Bot:
false by default.

Wallet API order logic:
false by default.

Signal and advice output:
false by default.

Docs-only summaries may be created only in a separate explicitly authorized docs-only phase.

## 9. Failure classification

A 404 on CLOB book for a stale or closed token should be classified first as:
stale_or_unavailable_token_book_not_old_uri_bug_unless_fresh_target_proves_otherwise

Network timeout should be classified as a non-product failure unless content proves otherwise.

Gamma parse failure should be separated from endpoint failure.

CLOB book parse failure should be separated from endpoint failure.

Target ambiguity blocks CLOB.

Multiple candidate markets block CLOB until a fresh target is selected.

Missing outcome mapping blocks CLOB.

Missing dual token ids block CLOB.

Reusing a closed slug blocks the phase.

Reusing closed token ids blocks the phase.

## 10. Future phase boundary

Closing this contract does not authorize execution.

A later execution phase must be separate and must:
- validate HEAD and origin/main;
- validate working tree clean;
- validate this contract;
- print request caps before any request;
- select a fresh target;
- not reuse closed slug or closed token ids;
- execute no more than the caps;
- persist nothing unless separately authorized;
- create no snapshot unless separately authorized;
- create no fixture unless separately authorized;
- create no collector;
- create no bot;
- create no wallet/API/order logic;
- emit no trading signal;
- provide no financial advice.

## 11. Prohibited strings and capabilities

The following are prohibited as product capabilities:
- wallet connection prompt capability text
- private keys
- authenticated trading API
- createOrder
- placeOrder
- executeOrder
- real-order capability text
- trading automation
- live-trading capability text
- signal capability text
- advice capability text
- guaranteed profit
- prediction guarantee claim text
- risk free claim text
- certainty claim text

These capability-family labels are documentation of exclusions only. They are not supported outputs, calls to action, or product capabilities.

## 12. Acceptance criteria for this docs-only phase

This docs-only phase passes only if:
- repo baseline is validated;
- working tree starts clean;
- closed summary artifact exists and is tracked;
- closed summary artifact SHA256 matches expected value;
- this contract file did not exist before;
- only this contract markdown is created;
- no market-data requests are executed;
- no public smoke requests are executed;
- no snapshot is created;
- no fixture is created;
- no collector is created;
- no runtime loop is created;
- no bot is created;
- no wallet/API/order logic is introduced;
- no signal or advice output is introduced;
- no stage is executed;
- no commit is executed;
- no push is executed.

## 13. Next recommended phase

If this docs-only contract phase passes, the next recommended phase is:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_LOOP_CONTRACT_DOCS_ONLY_REVIEW_OR_COMMIT_DECISION_V1

That next phase must decide whether to review the local artifact or open a separate controlled commit/push phase.