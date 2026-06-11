# BTC 15m Arena — Repeatable CLOB Book Capture Contract V1

Date: 2026-06-11

Microphase:
BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_CONTRACT_DOCS_ONLY_V1

Mode:
Docs-only contract.

## 1. Purpose

This document defines the minimum contract for any future repeatable public CLOB `/book` capture used by BTC 15m Arena.

The contract exists because the project already proved that a single public CLOB book snapshot can be captured and reviewed, but that snapshot was deliberately classified as temporary local review evidence and then removed.

The next capture must not happen until naming, retention, validation, cleanup, fixture/replay gates and guardrails are explicit.

## 2. Current baseline

Expected baseline for this contract phase:

- repo: `C:\openutilitylab-site`
- branch: `main`
- HEAD: `4003fb4`
- origin/main: `4003fb4`
- working tree: clean before contract creation
- previous CLOB snapshot: removed and absent
- snapshots directory: no residual JSON snapshots expected
- fixture/replay artifacts: pre-existing static artifacts only; not CLOB promotion

## 3. Non-goals

This contract does not authorize:

- a new Gamma request;
- a new CLOB request;
- a new snapshot capture;
- repeated capture;
- polling;
- historical collection;
- live data loop;
- runtime/UI integration;
- fixture promotion;
- replay generation;
- bot behavior;
- wallet/API/order logic;
- trading automation;
- financial advice;
- prediction;
- profitability claims.

## 4. Capture mode allowed by future phases

The only future capture mode allowed by this contract is:

`single_shot_repeatable_read_only`

Meaning:

1. one explicit future phase;
2. one target market/outcome/token context;
3. no background loop;
4. no bot;
5. no runtime/UI integration;
6. no wallet;
7. no orders;
8. no authenticated Polymarket headers;
9. no durable fixture or replay promotion unless a later policy gate explicitly authorizes it.

## 5. Endpoint and auth policy

Allowed future CLOB endpoint class:

- public CLOB book read-only endpoint.

Auth policy:

- auth: none
- Poly headers: none
- wallet: none
- private keys: none
- API keys: none
- passphrases: none
- order credentials: none

Any capture that requires authenticated trading credentials is out of scope.

## 6. Token resolution policy

Future capture may use either:

1. a known token_id already validated by prior read-only discovery, or
2. a separate explicitly authorized token-resolution phase.

Token resolution must remain read-only.

If Gamma is used in a future phase, the phase must declare:

- why Gamma is needed;
- expected request count;
- no auth;
- no wallet;
- no orders;
- no loop;
- no runtime integration.

## 7. Naming policy

Future snapshot names must use the following pattern:

`btc_15m_clob_book_snapshot_<market_slug>_<YYYYMMDD_HHMMSS_utc>.json`

Required:

- prefix: `btc_15m_clob_book_snapshot_`
- market slug segment: required
- UTC capture timestamp segment: required
- suffix: `_utc.json`
- timezone: UTC

Forbidden:

- `_uc.json`
- local-time timestamps without UTC label
- filenames without market slug
- filenames without capture time
- ambiguous names such as `snapshot.json`
- overwriting an existing snapshot file

The historical `_uc.json` suffix was a naming defect. It was not a data defect, but future phases must not repeat it.

## 8. Storage policy

Future temporary raw CLOB snapshots may only be placed under:

`project_sources\btc-15m-arena\snapshots\`

The snapshots directory is for temporary review artifacts unless a separate retention gate changes classification.

No snapshot may be written into:

- `btc-15m-arena\fixtures\`
- `project_sources\btc-15m-arena\fixtures\`
- route runtime folders;
- public assets;
- root directory;
- other project directories.

## 9. Retention classes

### 9.1 TEMPORARY_LOCAL_REVIEW_ARTIFACT

Default class for raw CLOB snapshots.

Rules:

- commit allowed: false
- fixture allowed: false
- replay allowed: false
- runtime integration allowed: false
- cleanup required: true
- default action after review: exact-path local removal

### 9.2 DURABLE_EVIDENCE_DOCS_ONLY

Class for documentation that summarizes evidence without preserving the raw transient market-data snapshot.

Rules:

- commit allowed: true
- fixture allowed: false
- replay allowed: false
- runtime integration allowed: false
- cleanup required: false

### 9.3 STATIC_FIXTURE_CANDIDATE

Not the default.

Only available after a separate explicit fixture policy and normalization gate.

Rules:

- commit allowed by default: false
- fixture allowed: only after explicit fixture gate
- replay allowed: only after explicit replay gate
- normalization required: true
- provenance required: true
- stale-data warning required: true

## 10. Cleanup rule

Every future raw CLOB snapshot must end in one of these explicit decisions:

1. remove locally by exact path after review;
2. retain temporarily with a documented reason and a scheduled next cleanup phase;
3. open a separate retention/fixture policy gate.

Forbidden cleanup methods:

- `git clean`
- wildcards
- directory-wide deletion
- deleting multiple files without enumeration
- deleting fixture/replay artifacts while cleaning a raw snapshot
- deleting unreviewed files

Preferred cleanup method:

`Remove-Item -LiteralPath <exact_snapshot_path> -Force`

Only after:

- baseline validated;
- exact untracked file set validated;
- snapshot path validated;
- no tracked diff;
- no staged diff.

## 11. Staleness policy

A CLOB book snapshot is point-in-time evidence only.

It must not be used as:

- historical proof;
- strategy proof;
- profitability proof;
- real-time trading signal;
- execution recommendation;
- live runtime input;
- bot input;
- order-placement input.

Do not compare a stale snapshot with current UI prices unless a new explicit capture phase is opened.

A snapshot from a 15m market window is stale for execution as soon as the market state has moved. It remains useful only as documented evidence or as a future fixture candidate after a separate policy gate.

## 12. Required metadata for future snapshot JSON

Every future raw snapshot must include:

- phase
- source
- auth
- poly_headers
- market_slug
- market_timestamp
- outcome
- token_id
- capture_time_utc
- http_status
- request_count_clob_book
- gamma_call_count
- bids_count
- asks_count
- best_bid_observed
- best_ask_observed
- observed_spread
- book
- guardrails

The `book.asset_id` must match the expected token_id.

The actual number of bids and asks in `book` must match recorded counts.

Computed best bid, best ask and spread must be reproducible from the book arrays.

## 13. Required guardrails in future snapshots

Every future snapshot must include a guardrails object with true values for:

- no_wallet
- no_orders
- no_bot
- no_loop
- no_authenticated_api
- no_poly_headers
- no_fixture_promotion
- no_commit
- no_push
- no_runtime_integration
- no_live_data_loop
- no_trading_automation

Missing or false guardrails must fail the review.

## 14. Validation gates for future capture review

A future capture review must validate:

1. baseline git;
2. expected branch;
3. expected HEAD;
4. HEAD equals origin/main;
5. no tracked diff before capture unless explicitly authorized;
6. no staged diff before capture;
7. controlled untracked set;
8. snapshot filename uses `_utc.json`;
9. JSON parse succeeds;
10. HTTP status is 200;
11. source is public CLOB book;
12. auth is none;
13. Poly headers are none;
14. token_id matches expected target;
15. book.asset_id matches token_id;
16. bids and asks arrays exist;
17. recorded counts match actual counts;
18. best bid and best ask compute correctly;
19. spread is non-negative;
20. crossed book is rejected unless explicitly classified;
21. secret/auth scan passes;
22. fixture promotion remains false;
23. replay generation remains false;
24. runtime integration remains false;
25. no wallet/API/order/bot/loop behavior exists.

## 15. Secret and auth material scan

Future snapshot text must fail review if it contains any likely credential/auth material, including:

- POLY_API_KEY
- POLY_SECRET
- POLY_PASSPHRASE
- privateKey
- apiKey
- password
- authorization header text
- bearer token text
- x-api-key header text

This list is intentionally conservative.

## 16. Fixture promotion gate

Raw CLOB snapshots must not be promoted to fixture by default.

A separate fixture gate is required before any promotion.

That gate must answer:

- why this snapshot should become a fixture;
- whether it should be normalized;
- whether raw market data should be reduced;
- whether staleness is clearly documented;
- whether book shape is stable enough;
- whether replay can consume it deterministically;
- whether committing it is acceptable.

Until that gate passes:

- commit raw snapshot: false
- fixture promotion: false
- replay source: false

## 17. Replay generation gate

Replay generation from CLOB data is forbidden until a separate replay contract exists.

The replay gate must define:

- input shape;
- expected output shape;
- deterministic replay rules;
- handling of stale prices;
- no live execution interpretation;
- no trading advice;
- no wallet/API/order logic.

## 18. Runtime integration gate

No raw or reviewed CLOB snapshot may be connected to public runtime/UI without a separate implementation phase.

Runtime integration requires a different contract because it changes the product surface from local evidence/review into user-facing behavior.

This contract does not authorize runtime integration.

## 19. Loop and collector policy

No loop or collector is authorized by this contract.

A future collector would require a separate contract covering:

- request cadence;
- rate limits;
- retention duration;
- storage location;
- deduplication;
- stale-data handling;
- failure recovery;
- public/private boundary;
- whether data is committed or local only;
- no trading automation;
- no wallet/API/order logic.

## 20. PowerShell validator prevention

Future PowerShell validators must follow these rules:

- wrap command outputs with `@(...)`;
- wrap `Get-ChildItem` results with `@(...)`;
- use `@($Items).Count` for possibly-empty or scalar outputs;
- do not assume helper returns always have `.Count`;
- avoid `$script:` accumulators in pasted interactive blocks unless explicitly initialized and self-tested;
- avoid variable names that collide with built-ins, such as HOME, Host, PID, Error, Args, Input, Matches;
- do not paste terminal prompts like `PS C:\...>` into executable blocks;
- do not use `git add .`;
- do not use `git add -A`;
- do not use `git clean`;
- do not use wildcards for cleanup;
- use exact literal paths for deletion;
- use single quotes or escaped dollar signs when documenting literal PowerShell variables inside strings.

Example safe literal string:

- use single quotes for text containing `$Value`;
- avoid double-quoted strings such as `"Use @($Value).Count..."` unless `$Value` is intentionally defined.

## 21. Existing fixture/replay artifacts

The following known fixture/replay artifacts may exist and are classified as pre-existing static/replay artifacts, not CLOB snapshot promotion:

- `project_sources\btc-15m-arena\fixtures\btc_15m_static_fixture_1780955100_20260608_215745_utc.json`
- `btc-15m-arena\fixtures\static-scenarios.v1.json`

They must not be touched by future CLOB snapshot cleanup phases.

## 22. Future phase sequence

After this docs-only contract is created locally, the next phase should be:

`BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_CONTRACT_DOCS_ONLY_COMMIT_PUSH_V1`

Only after the contract is committed and pushed should the project consider:

`BTC_15M_ARENA_LIVE_DATA_SOURCE_CLOB_BOOK_REPEATABLE_CAPTURE_PRECHECK_READ_ONLY_V1`

Only after that precheck passes should a new single-shot capture be considered.

## 23. Closing decision

This contract formalizes the rule:

Do not capture another CLOB snapshot yet.

First close the contract. Then precheck the next capture. Then capture only if the precheck authorizes it.

The capture must remain read-only, explicit, single-shot, temporary by default and disconnected from wallet, orders, bots, runtime and fixture/replay promotion.