# BTC 15m Arena — Fixture Consumption Local Review Contract V1

Date: 2026-06-12

## Microphase

BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_SINGLE_SNAPSHOT_FIXTURE_CONSUMPTION_CONTRACT_DOCS_ONLY_V1

## Mode

Docs-only contract. This document records the validated local fixture/snapshot review contract after the sorted level array classification pass.

## Scope

This contract is limited to documentation. It does not execute fixture consumption and does not create any runtime loader, replay harness, collector, bot, live data path, wallet integration, authenticated trading API integration, order creation, order submission, or order execution.

## Canonical inputs reviewed

- Fixture: project_sources/btc-15m-arena/fixtures/btc_15m_arena_clob_book_snapshot_20260611T210746Z.fixture.json
- Source snapshot: project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_20260611T210746Z_btc-updown-15m-1781211600_primary_token_id.json
- Null-field decision: project_sources/btc-15m-arena/BTC_15M_ARENA_FIXTURE_CONSUMPTION_NULL_FIELD_REPAIR_DECISION_V1.md
- Existing fixture consumption contract: project_sources/btc-15m-arena/BTC_15M_ARENA_FIXTURE_CONSUMPTION_CONTRACT_V1.md

## Validated fixture identity

- fixture_schema_version: btc_15m_arena_clob_book_fixture_v1
- fixture_kind: clob_book_single_snapshot_derived_fixture
- source_snapshot_schema_version: btc_15m_arena_clob_book_snapshot_v1

## Local review outcome accepted

The local review V2 classified sorted_bids and sorted_asks as price-size level arrays, not booleans.

Accepted classifications:

- fixture.clob_book_normalized.sorted_bids::SORTED_LEVEL_ARRAY_DESCENDING_BIDS
- fixture.clob_book_normalized.sorted_asks::SORTED_LEVEL_ARRAY_ASCENDING_ASKS
- snapshot.clob_book_normalized.sorted_bids::SORTED_LEVEL_ARRAY_DESCENDING_BIDS
- snapshot.clob_book_normalized.sorted_asks::SORTED_LEVEL_ARRAY_ASCENDING_ASKS
- local_review_v1_issues::VALIDATOR_FALSE_NEGATIVE_BOOLEAN_ASSUMPTION_ON_SORTED_LEVEL_ARRAYS

## Counts and best-level contract

- sorted_bids count: 88
- sorted_asks count: 11
- best_bid_price: 0.88
- best_ask_price: 0.89
- spread: 0.01
- mid: 0.885

Contract expectations:

- Bids must be represented as an array/list of levels with price and size.
- Asks must be represented as an array/list of levels with price and size.
- Bid levels must be descending by price.
- Ask levels must be ascending by price.
- First bid level must match best_bid_price.
- First ask level must match best_ask_price.
- Fixture and source snapshot level arrays must be equivalent for the reviewed canonical pair.

## Null-field contract

The fields source_market_context and source_target_resolution may remain null inside the derived fixture when they are derivable or recoverable from the source snapshot and surrounding source artifacts. This is not a fixture-consumption blocker when the decision document and source snapshot remain available.

Accepted classifications:

- source_market_context::NULL_IN_FIXTURE_ACCEPTED_DERIVABLE_FROM_SOURCE_SNAPSHOT
- source_target_resolution::NULL_IN_FIXTURE_ACCEPTED_DERIVABLE_FROM_SOURCE_SNAPSHOT

## Guardrails

- No wallet.
- No private keys.
- No authenticated trading API.
- No real orders.
- No order creation, submission, or execution.
- No trading automation.
- No live trading.
- No runtime live data in this docs-only phase.
- No collector.
- No bot.
- No financial advice.
- No profit guarantee.
- No prediction guarantee.
- No real-time signal.

## Runtime exclusions

This contract does not authorize:

- fixture loader creation
- fixture replay creation
- fixture consumption execution
- runtime live data
- collector start
- bot start
- API keys
- private keys
- wallet state
- createOrder/placeOrder/executeOrder logic
- background polling
- trading signal generation

## Future implementation gate

Before any future fixture consumption implementation, a separate read-only precheck must validate the target file, allowed scope, expected fixture path, expected snapshot path, no wallet/API/order logic, no live data, no collector, no bot, and a clean repository baseline.

The next safe phase after committing this docs-only contract is a commit/push review for this document only, or a read-only implementation precheck if this document is deliberately kept local.

## PowerShell validation notes

- Do not treat sorted_bids or sorted_asks as booleans.
- Validate them as arrays/lists of price-size levels.
- Validate first bid/ask against best_bid_price/best_ask_price.
- Validate bid order descending and ask order ascending.
- Validate fixture/snapshot equivalence with explicit count and mismatch_count.
- Do not use literal substring checks for sensitive terms without context.
- Do not use git diff alone to detect new untracked docs-only files.
- Use git status --short --untracked-files=all and git ls-files --others --exclude-standard for untracked scope.

## Result

This docs-only contract records that the local sorted-level review issue is resolved and that the canonical fixture/snapshot pair is ready for a future explicitly scoped fixture-consumption implementation precheck. It does not implement that consumption.
