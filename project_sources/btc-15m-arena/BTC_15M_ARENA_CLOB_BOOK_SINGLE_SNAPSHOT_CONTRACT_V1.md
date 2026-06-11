# BTC 15m Arena — CLOB Book Single Snapshot Contract V1

Date: 2026-06-11  
Mode: docs-only contract for one validated read-only CLOB book snapshot.  
Repository baseline: 0bdcd39a3ec36eda38658b8a7e77a8efcacd86d2  
Snapshot commit: 0bdcd39a3ec36eda38658b8a7e77a8efcacd86d2  
Snapshot path: project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json

## 1. Purpose

This document defines the contract for the single validated BTC 15m Arena CLOB book snapshot committed in 0bdcd39.

The snapshot is evidence that a bounded read-only pipeline reached an active BTC 15m market token and captured a non-empty public CLOB book once.

This document does not authorize runtime integration, live data polling, fixture promotion, replay generation, collector startup, bot behavior, wallet access, authenticated trading API usage, private keys, order placement, or trading automation.

## 2. Snapshot identity

Required identity fields:

- schema_version: btc_15m_arena_clob_book_snapshot_v1
- capture_mode: read_only_single_book_snapshot
- snapshot_path: project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json
- capture_timestamp_utc: 2026-06-11T21:07:46Z
- committed_at_head: 0bdcd39a3ec36eda38658b8a7e77a8efcacd86d2
- latest_commit_subject: Add BTC 15m Arena validated CLOB book snapshot

The schema version for this artifact is:

```text
btc_15m_arena_clob_book_snapshot_v1
```

The capture mode for this artifact is:

```text
read_only_single_book_snapshot
```

Any future consumer must reject this snapshot if either field differs.

## 3. Validated classification

Required classification fields:

* classification: valid_non_empty_book
* snapshot_valid: True

The only accepted classification for this committed artifact is:

```text
valid_non_empty_book
```

A future fixture, replay, or parser must not infer broader validity from this value. It only means that the captured book was parseable and non-empty at capture time.

## 4. Required normalized book shape

The snapshot must preserve a normalized CLOB book section containing at least:

* bids_count
* asks_count
* normalized bids collection
* normalized asks collection

Validated values for this committed snapshot:

* bids_count: 88
* asks_count: 11

Acceptance invariant:

```text
bids_count > 0
asks_count > 0
```

If either side is empty, the snapshot cannot be used under this contract as a valid non-empty CLOB book sample.

## 5. Required derived metrics

The snapshot must preserve derived metrics sufficient for execution-risk research:

* best_bid_price
* best_ask_price
* spread
* mid

Validated values for this committed snapshot:

* best_bid_price: 0.88
* best_ask_price: 0.89
* spread: 0.01
* mid: 0.885

Acceptance invariants:

```text
best_bid_price < best_ask_price
spread = best_ask_price - best_bid_price
mid = (best_bid_price + best_ask_price) / 2
```

These values are observational. They are not predictions, signals, trading instructions, or financial advice.

## 6. Scope audit requirements

The snapshot must contain a scope_audit section proving that the capture phase remained bounded.

Validated scope audit values:

* gamma_requests_executed: 2
* clob_book_requests_executed: 1
* markets_by_token_requests_executed: 0
* snapshot_file_created: true
* fixture_created: false
* replay_executed: false
* collector_started: false
* bot_started: false
* runtime_live_data_enabled: false
* wallet_used: false
* orders_placed: false
* stage_commit_push_executed in snapshot payload: false

Contract interpretation:

* The capture phase created a snapshot file locally.
* The later commit/push phase versioned the file.
* The snapshot payload itself must still report that it did not perform stage/commit/push.
* No fixture, replay, collector, bot, runtime live data, wallet or order logic was created by the capture.

## 7. What this snapshot is allowed to prove

This artifact may be used to prove:

1. Public Gamma discovery can resolve an active BTC 15m market context under bounded conditions.
2. A public CLOB `/book` request can return a parseable non-empty book for the selected active market token.
3. The repository contains one committed read-only snapshot with explicit scope audit metadata.
4. Best bid, best ask, spread and mid can be derived from the normalized book sample.
5. The project can now define fixture/replay contracts from a validated source artifact, if explicitly authorized later.

## 8. What this snapshot is not allowed to prove

This artifact must not be used to claim:

1. A stable live data feed exists.
2. A collector exists.
3. A replay harness exists.
4. A bot exists.
5. Runtime live data is enabled.
6. Order execution is possible.
7. Wallet integration is present.
8. Authenticated trading API access is present.
9. Any profitable strategy exists.
10. Any prediction or guaranteed outcome exists.
11. Any trading recommendation has been generated.

## 9. Fixture and replay status

Current status:

* fixture promotion: not authorized
* replay generation: not authorized
* replay execution: not authorized
* collector: not started
* bot: not started
* runtime live data: not enabled

Historical fixture directories may exist in the repository, but they are not part of this snapshot contract unless a future phase explicitly promotes this snapshot or derives a fixture from it.

A future fixture promotion phase must verify:

* exact source snapshot path
* exact source commit hash
* schema_version
* capture_mode
* classification
* snapshot_valid
* bids_count and asks_count
* derived metrics
* no wallet
* no orders
* no runtime live data
* no mutation of the original snapshot

## 10. Guardrails

Permanent guardrails for this contract:

* read-only snapshot only
* no wallet
* no private keys
* no authenticated trading API
* no orders
* no real trading
* no trading automation
* no financial advice
* no profitability claims
* no guaranteed prediction
* no live data loop
* no collector
* no bot
* no runtime integration

Any later phase that needs to cross one of these boundaries must be opened as a separate explicitly authorized phase and must update project documentation before implementation.

## 11. Failure modes for future consumers

A future parser, fixture promoter, or replay precheck must fail closed if:

* the snapshot file is missing
* the snapshot is not tracked at the expected commit
* schema_version differs from `btc_15m_arena_clob_book_snapshot_v1`
* capture_mode differs from `read_only_single_book_snapshot`
* classification differs from `valid_non_empty_book`
* snapshot_valid is not true
* bids_count <= 0
* asks_count <= 0
* best bid/ask/spread/mid cannot be parsed
* best_bid_price >= best_ask_price
* spread is negative
* scope audit indicates fixture/replay/collector/bot/runtime/wallet/orders
* the source snapshot is modified in-place
* fixture promotion is attempted without a separate authorized phase

## 12. Absolute-path repair note

This contract was written in the repair phase using an absolute repository path.

Reason:

```text
PowerShell Set-Location does not guarantee that .NET file APIs receive the intended repository-relative path.
```

Required future prevention:

```text
Use absolute paths for [System.IO.File]::WriteAllText and similar .NET file APIs.
Keep repo-relative paths only for Git pathspecs and documentation.
```

This prevents accidental writes under locations such as:

```text
C:\Windows\System32\project_sources\...
```

## 13. Recommended next phase

The safest next phase after this docs-only repair is:

```text
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_ACTIVE_MARKET_TOKEN_REFRESH_BOUNDED_SINGLE_SNAPSHOT_CONTRACT_DOCS_COMMIT_PUSH_V1
```

Only after this contract is committed, a later separate precheck may be opened:

```text
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_PROMOTION_PRECHECK_READ_ONLY_V1
```

The project should not open collector, bot, runtime live data, wallet/API private integration, or order logic from this phase.