# BTC 15m Arena — Fixture Consumption Null Field Repair Decision V1

Phase:
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_CONSUMPTION_PRECHECK_CONTRACT_DOCS_ONLY_REPAIR_DECISION_V1_SCRIPT_REPAIR_ABSOLUTE_PATH_WRITE

Status:
Docs-only local decision document.

Date:
2026-06-12

## Purpose

This document records the repair decision after the fixture consumption precheck detected that two canonical fixture sections are null:

- `source_market_context`
- `source_target_resolution`

The decision is required before any future fixture consumption, loader, replay, collector, bot, runtime live data, wallet/API/order logic, or order-related work.

## Inputs reviewed

- Existing fixture consumption contract: `project_sources/btc-15m-arena/BTC_15M_ARENA_FIXTURE_CONSUMPTION_CONTRACT_V1.md`
- Published fixture: `project_sources/btc-15m-arena/fixtures/btc_15m_arena_clob_book_snapshot_20260611T210746Z.fixture.json`
- Source snapshot: `project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json`
- Source contract: `project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_CONTRACT_V1.md`
- Promotion contract: `project_sources/btc-15m-arena/BTC_15M_ARENA_CLOB_BOOK_SINGLE_SNAPSHOT_FIXTURE_PROMOTION_CONTRACT_V1.md`

## Confirmed fixture identity

- `fixture_identity.fixture_schema_version = btc_15m_arena_clob_book_fixture_v1`
- `fixture_identity.fixture_kind = clob_book_single_snapshot_derived_fixture`
- `source_snapshot_identity.schema_version = btc_15m_arena_clob_book_snapshot_v1`

Do not read fixture schema/kind from root fields. The correct fixture identity paths remain:

- `fixture_identity.fixture_schema_version`
- `fixture_identity.fixture_kind`

## Confirmed null-field condition

The published fixture contains the canonical keys but their values are not consumable:

- `source_market_context` is null in the fixture.
- `source_target_resolution` is null in the fixture.

Classification:

- `source_market_context::NULL_IN_FIXTURE_DERIVABLE_OR_RECOVERABLE_FROM_SOURCE_SNAPSHOT`
- `source_target_resolution::NULL_IN_FIXTURE_DERIVABLE_OR_RECOVERABLE_FROM_SOURCE_SNAPSHOT`

This is not classified as fixture corruption, repo failure, JSON parse failure, tracking failure, or runtime failure.

## Decision

For future consumption work, the canonical decision is:

1. Treat `source_market_context` and `source_target_resolution` as nullable in the published fixture V1.
2. Do not make a future loader fail solely because those two fixture fields are null if the source snapshot remains available and parseable.
3. For a future consumption output shape, derive or recover these two sections from the source snapshot under an explicit read-only or docs-approved repair/consumption phase.
4. Keep the fixture immutable until a dedicated fixture-repair phase is explicitly authorized.
5. Do not silently drop the fields from output. If not recovered, mark them as `DERIVABLE_FROM_SOURCE_SNAPSHOT_PENDING` or equivalent explicit status.

Preferred path:

- `source_market_context`: derive from source snapshot market/window/slug/condition/token context where available.
- `source_target_resolution`: derive from source snapshot target/resolution/token/outcome context where available.

Rejected paths:

- Do not create a loader that ignores these fields without status.
- Do not modify the published fixture in this decision phase.
- Do not execute fixture consumption in this decision phase.
- Do not open live data, collector, bot, wallet/API/order logic, or orders.

## Future validator requirements

Future validators must distinguish:

- key present
- non-null value
- consumable object/value
- nullable but recoverable from source snapshot
- nullable and not recoverable
- optional-by-contract
- contract mismatch
- promotion omission

Required future checks:

- validate `fixture_identity.fixture_schema_version`
- validate `fixture_identity.fixture_kind`
- validate `source_snapshot_identity.schema_version`
- validate source snapshot exists and is parseable before attempting recovery
- validate recovered `source_market_context` and `source_target_resolution` are labeled as derived/recovered
- validate outputs remain simulation-only and paper-only
- validate no wallet, no private keys, no authenticated trading API, no orders, no trading automation, no live trading, no runtime live data, no collector, no bot

## Guardrails

- No wallet.
- No private keys.
- No authenticated trading API.
- No real orders.
- No order creation.
- No order submission.
- No order execution.
- No trading automation.
- No live trading.
- No runtime live data.
- No collector.
- No bot.
- No financial advice.
- No profit guarantee.
- No prediction guarantee.
- No real-time signal.

## Scope of this document

This document is docs-only. It does not modify fixtures, execute fixture consumption, create a loader, create replay output, start a collector, start a bot, enable runtime live data, use wallet/API/order logic, or submit orders.

## ParserError prevention

A prior attempt failed because the Markdown document was built as an array of double-quoted PowerShell strings containing inline-code backticks.

PowerShell treats backtick as an escape character. Markdown inline-code backticks inside double-quoted strings can therefore break string parsing and produce a ParserError before execution.

This repaired phase uses a single-quoted here-string literal for the Markdown body. Future Markdown-generating PowerShell phases should use one of:

- single-quoted here-string literals
- single-quoted literal lines
- Markdown without inline-code backticks
- controlled string formatting outside Markdown literals

Do not use double-quoted array strings containing Markdown backticks.

## Absolute path write prevention

A later attempt reached the write step but used a relative path in `[System.IO.File]::WriteAllText`. The .NET call resolved the relative path against `C:\Windows\System32` instead of the repository root.

Future PowerShell phases that use .NET file APIs must:

- resolve `$RepoRoot = (Resolve-Path -LiteralPath $Repo).ProviderPath`
- convert Git paths to repository-absolute file paths
- use absolute paths for `[System.IO.File]::WriteAllText`
- use absolute paths for `[System.IO.File]::ReadAllText`
- never create or repair paths under `C:\Windows\System32`

This document was written with an absolute path under `C:\openutilitylab-site`.

## Next recommended phase

BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_CONSUMPTION_PRECHECK_CONTRACT_DOCS_ONLY_REPAIR_DECISION_REVIEW_READ_ONLY_V1

The next phase should review this decision document, validate its anchors and guardrails, confirm that only this docs-only file is untracked, and still avoid stage, commit and push unless explicitly authorized in a later commit/push phase.