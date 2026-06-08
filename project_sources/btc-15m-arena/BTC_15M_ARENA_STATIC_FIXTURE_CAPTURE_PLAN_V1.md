# BTC 15m Arena — Static Fixture Capture Plan V1

Status: docs-only plan.
Date: 2026-06-08.
Repository scope: Open Utility Lab / BTC 15m Arena.

## 1. Purpose

This document defines the controlled plan for a future manual static fixture capture phase.

The purpose is to create a normalized static JSON snapshot format for BTC 15m Arena replay and training work.

This plan does not capture data.
This plan does not call any endpoint.
This plan does not authorize runtime integration.
This plan does not authorize live UI integration.
This plan does not authorize polling.
This plan does not authorize WebSocket usage.
This plan does not authorize wallet, API, order, or bot logic.

## 2. Boundaries

Allowed in this docs-only phase:
- create this markdown plan;
- define fixture location;
- define fixture naming convention;
- define fixture schema;
- define validation rules;
- define future manual capture constraints;
- define future acceptance criteria.

Not allowed in this docs-only phase:
- fixture capture;
- fixture directory creation;
- fixture JSON creation;
- route edit;
- home edit;
- sitemap edit;
- CSS edit;
- JavaScript edit;
- package change;
- script/toolchain change;
- public smoke;
- network call;
- live data UI;
- polling loop;
- WebSocket stream;
- authenticated endpoint;
- wallet connection;
- private key handling;
- API key handling;
- order creation;
- order placement;
- order execution;
- bot or trading automation;
- financial advice;
- profit guarantee;
- prediction guarantee.

## 3. Relationship to existing documents

This plan depends on:

1. Live data source contract:
   `project_sources/btc-15m-arena/BTC_15M_ARENA_LIVE_DATA_SOURCE_CONTRACT_V2_NORMALIZED_GAMMA_CLOB_READ_ONLY.md`

2. Product specification:
   `project_sources/btc-15m-arena/BTC_15M_ARENA_PRODUCT_SPEC_AND_DECISION_MODEL_V1.md`

3. Static scenario calculator plan:
   `project_sources/btc-15m-arena/BTC_15M_ARENA_STATIC_SCENARIO_CALCULATOR_IMPLEMENTATION_PLAN_V1.md`

This document adds fixture-capture planning only. It does not supersede the contract or product spec.

## 4. Future fixture directory

Future fixture JSON files, if later authorized, should live under:

`project_sources/btc-15m-arena/fixtures/`

The directory should not be created by this docs-only plan phase.

A later manual capture phase may create the directory only if that phase explicitly authorizes fixture creation.

## 5. Future fixture naming convention

Recommended filename pattern:

`btc_15m_static_fixture_{candidate_timestamp}_{capture_yyyymmdd_hhmmss_utc}.json`

Example pattern only:

`btc_15m_static_fixture_1780950600_20260608_210000_utc.json`

Rules:
- lowercase filename;
- underscores only;
- timestamp included;
- capture UTC included;
- no spaces;
- no user-specific data;
- no account data;
- no wallet data;
- no order data.

## 6. Future fixture schema

A future fixture should be a single JSON object with these top-level fields:

- schema_version
- captured_at_utc
- source_mode
- market
- tokens
- books
- derived
- source_urls
- guardrails

### 6.1 schema_version

Expected value:

`btc_15m_static_fixture_v1`

### 6.2 captured_at_utc

ISO-8601 UTC timestamp for the manual capture time.

Example shape:

`2026-06-08T21:00:00Z`

### 6.3 source_mode

Expected value:

`manual_read_only_public_snapshot`

The value must not imply automation, polling, streaming, authenticated access, account state, wallet state, or order state.

### 6.4 market

Expected fields:

- slug
- candidate_timestamp
- condition_id
- question
- outcomes
- clob_token_ids
- start_time_utc
- end_time_utc
- status

Rules:
- `candidate_timestamp` must be divisible by 900.
- `outcomes` must contain Up and Down.
- `clob_token_ids` must map deterministically to Up and Down by outcome index.
- no account-specific field allowed.

### 6.5 tokens

Expected fields:

- up_token_id
- down_token_id
- mapping_rule

Expected mapping rule:

`Gamma market clobTokenIds map to CLOB asset_id by outcome index.`

### 6.6 books

Expected fields for each side:

- up
- down

Each side should include:
- best_bid
- best_ask
- spread
- bids_count
- asks_count
- top_bids
- top_asks

Depth arrays should be short and static. The future capture phase should define the exact max depth before writing fixture JSON.

### 6.7 derived

Expected fields:

- up_mid
- down_mid
- up_spread
- down_spread
- complementary_sum_best_asks
- complementary_sum_best_bids
- capture_quality_label
- warnings

All derived fields must be calculated from the captured static book data.

### 6.8 source_urls

Expected fields:

- gamma_event_url
- clob_up_book_url
- clob_down_book_url

Allowed public URL shapes for a future manual capture phase:

- `https://gamma-api.polymarket.com/events?slug=btc-updown-15m-{candidate_timestamp}`
- `https://clob.polymarket.com/book?token_id={clobTokenId}`

No authenticated endpoint is allowed.

### 6.9 guardrails

Expected values:
- read_only
- public_snapshot
- no_wallet
- no_orders
- no_authenticated_api
- no_trading_automation
- no_live_ui
- no_polling
- no_websocket
- no_financial_advice
- no_profit_guarantee
- no_prediction_guarantee

## 7. Future manual capture procedure

A later phase may authorize a manual capture only if all these conditions are true:

1. repository baseline is validated;
2. working tree state is validated;
3. fixture directory state is known;
4. target fixture filename is new;
5. market slug candidate is explicit;
6. Gamma public endpoint returns exactly the expected market shape;
7. outcomes and token mapping are validated;
8. CLOB public book endpoint returns bids and asks for both token ids;
9. fixture JSON is normalized;
10. fixture JSON is validated before any commit;
11. no route, home, sitemap, CSS, package, script, or runtime code is touched;
12. no stage, commit, or push occurs until a separate commit phase.

## 8. Future acceptance criteria

A future manual fixture capture phase may pass only if:

- exactly one fixture JSON file is created;
- the file path is under `project_sources/btc-15m-arena/fixtures/`;
- the fixture filename follows the naming convention;
- schema_version is present;
- captured_at_utc is present;
- source_mode equals `manual_read_only_public_snapshot`;
- market slug is present;
- candidate_timestamp is present and divisible by 900;
- condition_id is present;
- up_token_id is present;
- down_token_id is present;
- up and down book snapshots are present;
- best bid and best ask are present where available;
- spread fields are present;
- source_urls are present;
- guardrails are present;
- no account data exists;
- no wallet data exists;
- no order data exists;
- no authenticated field exists;
- no runtime route integration exists;
- no polling loop exists;
- no WebSocket exists;
- no bot exists.

## 9. Future validation rules

The later capture validator should check:

- JSON parse success;
- schema_version exact match;
- field presence;
- candidate timestamp alignment to 900 seconds;
- Up and Down mapping;
- token id non-empty;
- book side shape;
- numeric price ranges;
- spread non-negative when both bid and ask exist;
- source URL shape;
- absence of wallet/API/order/account fields;
- absence of runtime code;
- git scope exactness;
- staged diff empty unless commit phase explicitly begins.

## 10. Explicit non-goals

This fixture plan is not:

- a live trading system;
- a signal engine;
- a prediction engine;
- a wallet-connected app;
- an order execution system;
- an arbitrage bot;
- a market maker;
- a scraping loop;
- a polling system;
- a WebSocket stream;
- a financial advice product.

## 11. Separation of phases

Required sequence:

1. docs-only fixture capture plan;
2. docs-only plan commit/push;
3. manual read-only fixture capture precheck;
4. manual read-only fixture capture local creation;
5. fixture validation;
6. fixture commit/push;
7. replay integration plan;
8. replay implementation only after explicit authorization.

Do not combine these phases.

## 12. Next recommended microphase

After review of this local docs-only artifact, the next recommended phase is:

`BTC_15M_ARENA_STATIC_FIXTURE_CAPTURE_DOCS_ONLY_PLAN_COMMIT_PUSH_V1`

That phase should:
- validate this file as the only untracked change;
- validate content;
- stage only this file;
- commit;
- push;
- confirm `HEAD = origin/main`;
- confirm working tree clean.

## 13. Permanent guardrail

Static fixture capture must remain:
- manual;
- read-only;
- public endpoint only;
- normalized static JSON only;
- no wallet;
- no private keys;
- no API keys;
- no authenticated API;
- no account state;
- no order state;
- no bot;
- no polling loop;
- no live UI integration;
- no financial advice;
- no prediction or profit claim.