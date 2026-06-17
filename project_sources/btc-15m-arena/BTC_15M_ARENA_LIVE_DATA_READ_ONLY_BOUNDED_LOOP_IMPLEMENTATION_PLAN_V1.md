# BTC 15m Arena - Bounded Loop Implementation Plan V1

Docs-only implementation plan. No runtime implementation in this phase.

## 1. Purpose

This document plans a future bounded read-only market-data loop for BTC 15m Arena.

The future loop, if separately authorized, may read one fresh BTC Up/Down 15m market and its two CLOB book sides under strict request caps.

This plan does not execute requests.
This plan does not implement a loop.
This plan does not create a collector.
This plan does not create a runtime.
This plan does not create a bot.
This plan does not create a snapshot.
This plan does not create a fixture.
This plan does not create a public live-data feature.

## 2. Non-purpose

This plan is not trading.
This plan is not financial advice.
This plan is not a trading signal.
This plan is not a prediction.
This plan is not live trading.
This plan is not automated trading.
This plan is not wallet integration.
This plan is not authenticated trading API integration.
This plan is not order logic.
This plan is not snapshot creation.
This plan is not fixture creation.
This plan is not replay generation.
This plan is not a collector output.
This plan is not a runtime output.
This plan is not a bot output.

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

Any future implementation must keep every guardrail visible in terminal output, docs output, and any public or local user-facing text.

## 4. Current closed baseline evidence

The most recent fresh V3 dual-token evidence is closed and retained only as endpoint evidence.

Closed slug:
btc-updown-15m-1781708400

Closed Up token id:
42082333147465454912145556211445121129676724086717569761807000971672053767352

Closed Down token id:
45319980697747047378266542514078429282204322526025589645289739305457177753107

Closed market data is not a fixture.
Closed market data is not replay data.
Closed market data is not a future target.
Closed market data must not be reused as the live target.

## 5. Endpoint templates for a future separately authorized phase

Gamma endpoint template:
https://gamma-api.polymarket.com/events?slug=<fresh_btc_updown_15m_slug>

CLOB book endpoint template:
https://clob.polymarket.com/book?token_id=<fresh_token_id>

Only public read-only GET requests may be considered in a later phase.

No POST.
No signatures.
No auth headers.
No API keys.
No private keys.
No account state.
No wallet state.
No order endpoints.
No WebSocket.
No EventSource.
No background stream.

## 6. Target policy

Target policy:
fresh_window_only_aligned_900_seconds_not_closed_not_reused

A future target resolver must:
1. compute a current or next BTC Up/Down 15m candidate slug from a UTC 900-second aligned timestamp;
2. use only a fresh window candidate;
3. reject closed markets;
4. reject stale or reused slugs;
5. reject the closed V3 slug listed above;
6. reject the closed V3 token ids listed above;
7. reject ambiguous Gamma shapes;
8. print target selection evidence before any CLOB book request.

If a token book is stale or unavailable, classify it as:
stale_or_unavailable_token_book_not_old_uri_bug_unless_fresh_target_proves_otherwise

## 7. Request budget for a future separately authorized phase

Gamma requests per run:
1

CLOB book requests per tick:
2

Maximum ticks per run:
3

Maximum total market-data HTTP requests per run:
7

HTTP timeout:
10 seconds per request

Minimum tick interval:
20 seconds

The request budget must be printed before any request.

A later implementation must stop immediately if the budget would be exceeded.

## 8. Future loop shape

A future implementation, if separately authorized, should be a single bounded run, not a daemon.

Proposed sequence:

1. Preflight:
   - validate repo baseline;
   - validate guardrails;
   - validate no wallet/API/order path;
   - validate no collector/runtime/bot is active;
   - validate request caps;
   - validate target policy.

2. Resolve fresh market:
   - build fresh BTC 15m slug;
   - execute at most 1 Gamma request;
   - parse event and market candidate;
   - extract exactly two CLOB token ids when available;
   - reject closed/stale/reused target.

3. Bounded ticks:
   - execute at most 3 ticks;
   - each tick executes at most 2 CLOB book GET requests;
   - one book request for Up token;
   - one book request for Down token;
   - minimum interval 20 seconds between ticks;
   - timeout 10 seconds per request.

4. Per tick output:
   - UTC timestamp;
   - slug;
   - token side;
   - best bid;
   - best ask;
   - bid size at top;
   - ask size at top;
   - spread;
   - midpoint;
   - bid count;
   - ask count;
   - complement coherence checks;
   - request counters.

5. Close:
   - print total Gamma requests;
   - print total CLOB book requests;
   - print total market-data HTTP requests;
   - print zero wallet/API/order logic;
   - print zero runtime/collector/bot if no persistent process was created;
   - print no trading signals and no financial advice.

## 9. Output policy

Allowed future output:
- read-only market-data observations;
- request counters;
- timing counters;
- endpoint status;
- parsing status;
- target freshness status;
- book depth summary;
- complement coherence summary;
- warnings about stale or unavailable tokens;
- neutral technical summary.

Disallowed future output:
- direct trading instruction;
- real-time signal;
- immediate buy-action CTA wording;
- immediate sell-action CTA wording;
- immediate trade-action CTA wording;
- wallet-connection prompt wording;
- order-placement prompt wording;
- order-execution prompt wording;
- expected-profit guarantee wording;
- prediction-guarantee wording;
- no-risk claim wording;
- certain-win claim wording;
- order-submission recommendation wording;
- automated execution instruction wording;
- account/API connection prompt wording.

## 10. Persistence policy

Default persistence:
none

Raw stdout artifact:
false by default

Snapshot:
false by default

Fixture:
false by default

Collector:
false by default

Runtime loop:
false by default

Bot:
false by default

Wallet API order logic:
false by default

Signal and advice output:
false by default

Any persistence, snapshot, fixture, collector, runtime, bot, or docs summary requires a separate explicit phase.

## 11. Candidate implementation surface for a later phase

This plan does not authorize implementation.

A later implementation precheck must decide the exact path before writing code.

Candidate minimal local runner path, subject to later precheck:
scripts/btc-15m-arena/run_btc_15m_bounded_loop_read_only.ps1

Candidate docs output path, only if a separate docs-only phase authorizes it:
project_sources/btc-15m-arena/BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_LOOP_EXECUTION_SUMMARY_V1.md

The public route must not be changed by the first loop runner implementation.

The first loop runner implementation must not touch:
- btc-15m-arena/index.html
- btc-15m-arena/scenario-calculator.js
- index.html
- sitemap.xml
- styles.css
- robots.txt
- package.json
- package-lock.json
- other products in the repository.

## 12. Validation requirements for a later implementation precheck

A later implementation precheck must confirm:

- HEAD equals origin/main;
- working tree is clean;
- this plan is tracked;
- the bounded loop contract is tracked;
- the fresh V3 evidence summary is tracked;
- request caps are present;
- endpoint templates are present;
- closed slug and token ids are blocked;
- no runtime runner already exists unless expected;
- no wallet/API/order logic exists;
- no trading signals are introduced;
- no financial advice is introduced;
- no profit claims are introduced;
- no guaranteed prediction capability is introduced.

## 13. Validation requirements for a later implementation

A later implementation must prove:

- dirty scope is exact;
- no files outside allowed paths are touched;
- no package files are touched;
- no public route changes are made unless explicitly authorized;
- no other product is touched;
- no ^M or line-ending pollution is introduced;
- runtime/code scan finds no wallet/API/order logic;
- runtime/code scan finds no privateKey or apiKey;
- runtime/code scan finds no createOrder, placeOrder, or executeOrder;
- runtime/code scan finds no connectWallet;
- runtime/code scan finds no WebSocket/EventSource stream;
- any fetch or Invoke-WebRequest use is bounded and read-only;
- request counters are hard capped;
- timeout is enforced;
- tick count is hard capped;
- target freshness is enforced.

## 14. PASS criteria for this docs-only plan phase

This phase may pass only if:

- the repository starts at the expected baseline;
- the working tree starts clean;
- the contract artifact is tracked and matches expected hash;
- the fresh V3 summary artifact is tracked and matches expected hash;
- this plan file did not already exist;
- only this plan file is created;
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

## 15. Next recommended phase

If this docs-only plan passes locally, the next phase should be:

BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_LOOP_IMPLEMENTATION_PLAN_DOCS_ONLY_REVIEW_OR_COMMIT_DECISION_V1

That phase should decide whether to review, repair, or commit/push this plan.

Closing this plan does not authorize execution.