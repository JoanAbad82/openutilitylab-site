# BTC 15m Arena — CLOB Book Single Snapshot Fixture Promotion Contract V1

Date: 2026-06-12  
Generated at UTC: 2026-06-11T22:50:21Z  
Mode: docs-only contract for a future fixture promotion.  
Repository baseline: ded57209d2228b489db9a4957a9935bf04544a80  
Source snapshot path: project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json  
Source snapshot commit: ded57209d2228b489db9a4957a9935bf04544a80  
Source contract path: project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_CONTRACT_V1.md  
Source contract commit: ded57209d2228b489db9a4957a9935bf04544a80  
Candidate fixture path: project_sources/btc-15m-arena/fixtures/btc_15m_arena_clob_book_snapshot_20260611T210746Z.fixture.json  
Existing historical fixture path: project_sources/btc-15m-arena/fixtures/btc_15m_static_fixture_1780955100_20260608_215745_utc.json

## 1. Purpose

This document defines the contract for a future, separate promotion of one validated CLOB book snapshot into a derived fixture artifact.

This phase does not create the fixture JSON.

This phase does not execute replay, collector, bot, runtime live data, wallet access, private API access or orders.

The purpose of this contract is to fix provenance, file paths, invariants, allowed transformations, forbidden transformations and validation criteria before any fixture JSON is created.

## 2. Source artifacts

The future fixture promotion may only use this source snapshot:

```text
project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json
```

The source snapshot is tied to this commit:

```text
ded57209d2228b489db9a4957a9935bf04544a80
```

The future fixture promotion must also preserve this source contract:

```text
project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_CONTRACT_V1.md
```

The source contract is tied to this commit:

```text
ded57209d2228b489db9a4957a9935bf04544a80
```

The future promotion must fail closed if either source artifact is missing, untracked, modified, or not at the expected commit.

## 3. Candidate fixture path

The only candidate path authorized by this contract for a later promotion phase is:

```text
project_sources/btc-15m-arena/fixtures/btc_15m_arena_clob_book_snapshot_20260611T210746Z.fixture.json
```

The path must not be shortened or replaced by an ambiguous timestamp. The full timestamp `20260611T210746Z` is required.

The future promotion must fail closed if that path already exists before creation.

## 4. Existing fixture inventory

A historical static fixture already exists:

```text
project_sources/btc-15m-arena/fixtures/btc_15m_static_fixture_1780955100_20260608_215745_utc.json
```

Classification:

```text
historical_static_fixture_preexisting
```

The existing fixture is not an error, but it must not be overwritten, renamed, moved, deleted, merged into the new fixture, or treated as the same artifact as the future CLOB-derived fixture.

A future fixture promotion must list fixture inventory before writing and must prove that the candidate fixture path is absent.

## 5. Required source snapshot invariants

The source snapshot must satisfy all of the following:

```text
schema_version=btc_15m_arena_clob_book_snapshot_v1
capture_mode=read_only_single_book_snapshot
classification=valid_non_empty_book
snapshot_valid=True
bids_count=88
asks_count=11
best_bid_price=0.88
best_ask_price=0.89
spread=0.01
mid=0.885
```

Scope audit invariants:

```text
gamma_requests_executed=2
clob_book_requests_executed=1
fixture_created=False
replay_executed=False
collector_started=False
bot_started=False
runtime_live_data_enabled=False
wallet_used=False
orders_placed=False
```

The future fixture must not invent stronger claims than the source snapshot supports.

## 6. Required source contract invariants

The source contract must contain anchors for:

```text
BTC 15m Arena — CLOB Book Single Snapshot Contract V1
btc_15m_arena_clob_book_snapshot_v1
read_only_single_book_snapshot
valid_non_empty_book
bids_count: 88
asks_count: 11
best_bid_price: 0.88
best_ask_price: 0.89
spread: 0.01
mid: 0.885
fixture promotion: not authorized
replay generation: not authorized
collector: not started
bot: not started
runtime live data: not enabled
no wallet
no orders
no authenticated trading API
no trading automation
```

The future fixture promotion must fail if the source contract is missing these anchors or contains positive trading, order, wallet, prediction, or profit claims.

## 7. Allowed future transformations

A later fixture creation phase may perform only these transformations:

1. Read the source snapshot.
2. Create a new fixture JSON at the candidate path.
3. Preserve source provenance fields.
4. Preserve the normalized book sample or a documented fixture subset derived from it.
5. Preserve derived metrics:
   - best bid
   - best ask
   - spread
   - mid
6. Preserve scope audit metadata proving that the source was read-only.
7. Add fixture-specific metadata such as:
   - fixture_schema_version
   - fixture_kind
   - source_snapshot_path
   - source_snapshot_commit
   - source_contract_path
   - source_contract_commit
   - created_at_utc
8. Normalize line endings in the derived fixture only if explicitly documented.

The source snapshot itself must remain untouched.

## 8. Forbidden future transformations

A later fixture creation phase must not:

1. Modify the source snapshot in place.
2. Modify the source contract in place.
3. Overwrite any existing fixture.
4. Rename existing fixtures.
5. Delete existing fixtures.
6. Call Gamma.
7. Call CLOB.
8. Call Polymarket APIs.
9. Fetch live data.
10. Execute replay.
11. Start collector.
12. Start bot.
13. Enable runtime live data.
14. Use wallet.
15. Use private keys.
16. Use authenticated trading API.
17. Place orders.
18. Add private API/order logic.
19. Claim profitability.
20. Claim prediction quality.
21. Generate trading recommendations.

## 9. Required future fixture metadata

A future fixture JSON must include provenance equivalent to:

```text
fixture_schema_version=btc_15m_arena_clob_book_fixture_v1
fixture_kind=clob_book_single_snapshot_derived_fixture
source_snapshot_path=project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json
source_snapshot_commit=ded57209d2228b489db9a4957a9935bf04544a80
source_contract_path=project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_CONTRACT_V1.md
source_contract_commit=ded57209d2228b489db9a4957a9935bf04544a80
source_capture_timestamp_utc=2026-06-11T21:07:46Z
source_schema_version=btc_15m_arena_clob_book_snapshot_v1
source_capture_mode=read_only_single_book_snapshot
source_classification=valid_non_empty_book
source_snapshot_valid=True
```

It must also preserve or explicitly derive:

```text
bids_count=88
asks_count=11
best_bid_price=0.88
best_ask_price=0.89
spread=0.01
mid=0.885
```

## 10. Required future validation

A future fixture creation phase must validate:

1. HEAD and origin/main baseline.
2. Working tree clean before writing.
3. Source snapshot tracked and unchanged.
4. Source contract tracked and unchanged.
5. Fixture directory inventory.
6. Historical fixture still present and not modified.
7. Candidate fixture path absent before writing.
8. No network calls.
9. No replay.
10. No collector.
11. No bot.
12. No runtime live data.
13. No wallet.
14. No orders.
15. Only the candidate fixture path appears as new untracked file after writing.
16. No stage, commit, or push in the local creation phase.

## 11. Commit discipline

This contract does not authorize fixture JSON creation and does not authorize commit/push.

The expected next phase after this docs-only contract is a separate commit/push phase for this contract only, if this phase passes.

Only after the contract is committed may a future local fixture creation phase be opened.

## 12. Guardrails

Permanent guardrails:

```text
No wallet.
No private keys.
No authenticated trading API.
No real orders.
No trading automation.
No live trading.
No runtime live data.
No collector.
No bot.
No replay execution in this phase.
No financial advice.
No guaranteed profit.
No guaranteed prediction.
```

The fixture exists only for deterministic research, parser validation, fixture/replay design and execution-risk study. It is not a signal, a prediction, a trading instruction, or proof of edge.

## 13. Recommended next phases

If this docs-only phase passes, the next phase should be:

```text
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_PROMOTION_CONTRACT_DOCS_ONLY_COMMIT_PUSH_V1
```

Only after that commit/push phase passes may the project open:

```text
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_PROMOTION_LOCAL_CREATE_V1
```

The local create phase must still avoid replay, collector, bot, runtime live data, wallet, private API, and orders.