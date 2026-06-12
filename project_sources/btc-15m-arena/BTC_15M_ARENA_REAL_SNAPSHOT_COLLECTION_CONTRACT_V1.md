# BTC 15m Arena — Real Snapshot Collection Contract V1

Date: 2026-06-12

Microphase:
BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_CONTRACT_DOCS_ONLY_V1

Status:
DRAFTED_DOCS_ONLY

## 1. Purpose

This contract defines the allowed boundary for a future bounded one-shot real snapshot collection phase for BTC 15m Arena.

This document does not authorize execution. It prepares the contract only.

The goal of the future phase is to capture one bounded CLOB book snapshot for the already-targeted BTC 15m Arena research flow, normalize it into the existing static/paper-research pipeline, and preserve all product guardrails.

## 2. Explicit non-authorization

This contract does not authorize:

- live trading
- real orders
- order creation
- order placement
- order execution
- no order logic
- wallet connection
- private key use
- authenticated trading API use
- trading automation
- bot execution
- persistent collector execution
- background loop
- timer-based polling
- repeated capture
- financial advice
- profit guarantees
- prediction guarantees
- buy/sell/trade-now CTA

Any future phase that violates any item above must be blocked.

## 3. Current canonical repo paths

Current route:

- btc-15m-arena/index.html

Current runtime candidate:

- btc-15m-arena/scenario-calculator.js

Current public CLOB fixture candidate:

- btc-15m-arena/fixtures/clob-book-single-snapshot.v1.json

Current public static scenarios fixture:

- btc-15m-arena/fixtures/static-scenarios.v1.json

Current project source fixture directory:

- project_sources/btc-15m-arena/fixtures/

Current project source snapshot directory:

- project_sources/btc-15m-arena/snapshots/

Do not assume these legacy paths:

- btc-15m-arena/arena.js
- btc-15m-arena/fixtures/local-static-clob-book-snapshot.json

## 4. Future bounded one-shot snapshot boundary

A future implementation phase may be considered only if it remains bounded as follows:

- single run
- single selected market/token target
- one CLOB book request or one equivalent read-only book retrieval
- no interval
- no loop
- no retry loop unless explicitly bounded and logged
- no daemon
- no background collector
- no wallet
- no private key
- no authenticated trading API
- no order endpoint
- no order construction
- no order signing
- no order submission
- no bot logic

The future phase must print enough evidence to validate:

- source URL or source descriptor used
- market identity
- token identity
- timestamp
- bid/ask structure or normalized equivalent
- bid count
- ask count
- best bid if available
- best ask if available
- schema version
- output path
- final git status

## 5. Allowed future output locations

A future snapshot capture phase may write only to project source artifact locations unless a later contract explicitly authorizes public promotion.

Allowed future internal snapshot directory:

- project_sources/btc-15m-arena/snapshots/

Allowed future internal fixture directory:

- project_sources/btc-15m-arena/fixtures/

Not allowed in the first real snapshot capture phase:

- modifying btc-15m-arena/index.html
- modifying btc-15m-arena/scenario-calculator.js
- modifying public fixtures under btc-15m-arena/fixtures/
- modifying sitemap.xml
- modifying robots.txt
- adding package.json or package-lock.json unless a separate tooling phase authorizes it
- changing site runtime behavior
- deploying collector logic

## 6. Proposed future snapshot naming

Future internal raw/normalized snapshot file naming should be deterministic and include UTC timestamp plus target identity.

Recommended pattern:

project_sources/btc-15m-arena/snapshots/btc_15m_arena_clob_book_snapshot_<UTC_TIMESTAMP>_<MARKET_OR_SLUG>_<TOKEN_ID_OR_ALIAS>.json

If promoted into an internal fixture, recommended pattern:

project_sources/btc-15m-arena/fixtures/btc_15m_arena_clob_book_snapshot_<UTC_TIMESTAMP>.fixture.json

Public promotion must remain a separate phase.

## 7. Expected snapshot schema

The future snapshot artifact should include at minimum:

- schema_version
- artifact_kind
- capture_mode
- generated_at_utc
- source
- market
- token
- guardrails
- clob_book
- validation
- notes

Recommended clob_book shape:

```json
{
  "clob_book": {
    "bids": [],
    "asks": [],
    "best_bid": null,
    "best_ask": null,
    "bid_count": 0,
    "ask_count": 0
  }
}
```

If upstream data uses a different structure, the future phase must either normalize it or document the exact mapping.

## 8. Required validation markers

A future capture phase must validate and print:

* snapshot_json_parses
* schema_version_present
* generated_at_utc_present
* source_present
* market_identity_present
* token_identity_present
* bids_or_equivalent_present
* asks_or_equivalent_present
* bid_count_computed
* ask_count_computed
* best_bid_computed_or_null_explained
* best_ask_computed_or_null_explained
* no_wallet
* no_private_key
* no_authenticated_trading_api
* no_order_logic
* no_bot
* no_loop
* no_live_trading
* final_working_tree_expected

## 9. Existing debt markers to preserve

The closeout chain preserved these markers:

* fixture_bid_count
* fixture_ask_count

The future phase must preserve equivalent count semantics. It must not regress to a fixture/snapshot where bid/ask count interpretation is unknown.

## 10. Read-only source constraints

The future capture may use only public/read-only data access appropriate to a CLOB book inspection. It must not use authenticated trading credentials.

If an endpoint, library, or command requires authentication, signing, API key, wallet, or order permission, it is out of scope.

## 11. Bounded failure handling

The future capture phase must fail closed if:

* target market cannot be resolved
* token identity cannot be confirmed
* response is empty
* response is not valid JSON
* bids/asks or equivalent book sides cannot be mapped
* result would require a loop or repeated polling
* any order/wallet/auth capability appears in code or output
* write path is outside the authorized project_sources directories
* working tree is dirty before capture
* HEAD/origin are not synchronized

## 12. Commit boundary

This contract phase itself may be committed only in a separate commit/push phase unless the executing block explicitly includes commit/push validation.

A future snapshot capture phase should not automatically commit the snapshot unless a separate commit/push phase is authorized after output review.

## 13. Current decision

After repo path discovery repair, the project is eligible for a future bounded real snapshot implementation precheck, but not for capture yet.

Recommended next phase after this contract is reviewed:

BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_CONTRACT_DOCS_ONLY_COMMIT_PUSH_V1

After that, a separate read-only/pre-implementation phase may define the exact one-shot command.