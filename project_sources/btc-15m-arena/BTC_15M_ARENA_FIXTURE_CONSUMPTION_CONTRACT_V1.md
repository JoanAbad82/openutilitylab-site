# BTC 15m Arena — Fixture Consumption Contract V1

Phase: BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_CONSUMPTION_CONTRACT_DOCS_ONLY_V1
Date: 2026-06-12
Mode: docs-only contract.

## Purpose

This document defines the contract for consuming the published BTC 15m Arena CLOB book fixture in a future phase.
It does not execute fixture consumption, create a loader, create replay output, start a collector, start a bot, enable runtime live data, use wallet/API/order logic, or place orders.

## Input fixture

Input fixture path: project_sources/btc-15m-arena/fixtures/btc_15m_arena_clob_book_snapshot_20260611T210746Z.fixture.json
Fixture schema version: btc_15m_arena_clob_book_fixture_v1
Fixture kind: clob_book_single_snapshot_derived_fixture
Source capture timestamp UTC: 2026-06-11T21:07:46Z

The fixture is a static, versioned, read-only data artifact. It is not a signal, prediction, recommendation, or trading instruction.

## Source provenance required

Source snapshot path: project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json
Source snapshot commit: 1d69c2b1fd5e2452dfa9a012150ed288ff4ade2c
Source contract path: project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_CONTRACT_V1.md
Promotion contract path: project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_FIXTURE_PROMOTION_CONTRACT_V1.md
Existing static fixture path: project_sources/btc-15m-arena/fixtures/btc_15m_static_fixture_1780955100_20260608_215745_utc.json

The source snapshot contains CR characters and must remain untouched. Future consumption phases must not normalize or rewrite the source snapshot.

## Current consumption status

current_consumption_status: NO_RUNTIME_CONSUMER_CONFIRMED
current_replay_status: NOT_CREATED
current_loader_status: NOT_CREATED_OR_NOT_CONFIRMED
current_harness_status: NOT_CREATED_OR_NOT_CONFIRMED
current_collector_status: NOT_STARTED
current_bot_status: NOT_STARTED
current_runtime_live_data_status: NOT_ENABLED
current_wallet_status: NOT_USED
current_orders_status: NOT_PLACED

## Allowed future consumption scope

A future phase may inspect this fixture from disk in read-only mode.
A future phase may define a local loader/harness only after a separate precheck or implementation phase explicitly authorizes the files to modify.
A future phase may emit structured inspection output if the output remains static, local, deterministic, and simulation-only.

Allowed future input:
- the exact fixture path listed above;
- the fixture schema version listed above;
- the fixture kind listed above;
- the source capture timestamp listed above;
- parsed bids/asks and derived metrics already present inside the fixture.

Allowed future output shape:
- fixture identity summary;
- source provenance summary;
- bids_count and asks_count;
- best bid, best ask, spread and mid;
- guardrail summary;
- validation result;
- explanation that the fixture is static and not live data;
- no-trade/no-signal copy.

## Explicit replay boundary

Replay is not authorized by this contract.
This contract only defines the boundary for a future consumption decision.
If replay is needed later, it must be opened as a separate phase with its own precheck, file scope, acceptance criteria, and guardrails.

## Explicit loader boundary

Loader implementation is not authorized by this contract.
Any future loader must be local, deterministic, read-only, and must not make network requests.
Any future loader must avoid background loops and must not connect to external APIs.

## Guardrails

No wallet.
No private keys.
No authenticated trading API.
No real orders.
No order creation.
No order submission.
No order execution.
No trading automation.
No live trading.
No runtime live data.
No collector.
No bot.
No financial advice.
No profit guarantee.
No prediction guarantee.
No real-time signal.
No strategy claim.

## No trading claims

The fixture may be used only for static inspection and future simulation-oriented validation.
The fixture must not be described as evidence of edge, profitability, predictive accuracy, or executable opportunity.
Any output based on this fixture must use wording such as static fixture, read-only inspection, simulation-only, paper-only, and assumption-dependent.

## Files allowed in this phase

- project_sources/btc-15m-arena/BTC_15M_ARENA_FIXTURE_CONSUMPTION_CONTRACT_V1.md

## Files forbidden in this phase

- project_sources/btc-15m-arena/fixtures/btc_15m_arena_clob_book_snapshot_20260611T210746Z.fixture.json
- project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json
- project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_CONTRACT_V1.md
- project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_FIXTURE_PROMOTION_CONTRACT_V1.md
- project_sources/btc-15m-arena/fixtures/btc_15m_static_fixture_1780955100_20260608_215745_utc.json
- btc-15m-arena/index.html
- btc-15m-arena/scenario-calculator.js
- btc-15m-arena/fixtures/static-scenarios.v1.json
- index.html
- sitemap.xml
- styles.css
- robots.txt
- README.md
- scripts/
- src/
- public/
- dist/
- package.json
- package-lock.json
- other products in the repo.

## Future validator requirements

A future consumption precheck or loader phase must validate:
- HEAD and origin/main are synchronized before work;
- the working tree is clean before work;
- the input fixture exists and is tracked;
- the input fixture parses as JSON;
- raw timestamps are validated as ISO UTC strings before any object conversion;
- provenance matches the published fixture;
- best bid, best ask, spread and mid match the fixture;
- no network request is executed;
- no wallet/API/order logic is introduced;
- no output claims profit, prediction, signal or instruction;
- final working tree state is reported.

## Next phase

Recommended next phase after local docs-only creation and review:
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_CONSUMPTION_CONTRACT_DOCS_ONLY_REVIEW_READ_ONLY_V1

Recommended later phase after review PASS:
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_CONSUMPTION_CONTRACT_DOCS_ONLY_COMMIT_PUSH_V1
