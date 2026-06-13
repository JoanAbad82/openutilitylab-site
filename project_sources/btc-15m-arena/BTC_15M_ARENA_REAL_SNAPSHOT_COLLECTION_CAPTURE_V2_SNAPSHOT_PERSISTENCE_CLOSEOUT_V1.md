# BTC 15m Arena — Real Snapshot Collection Capture V2 Snapshot Persistence Closeout V1

Date: 2026-06-12

Microphase:
BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_BOUNDED_SINGLE_SNAPSHOT_CAPTURE_V2_SNAPSHOT_PERSISTENCE_CLOSEOUT_DOCS_ONLY_V1

Mode:
Docs-only closeout.

## Result

The real CLOB snapshot capture/persistence lane is closed at repository level for this bounded artifact.

Post-commit review decision:
PASS_SNAPSHOT_COMMIT_CONFIRMED

Current commit:
9770c232fd70ef835fdd1976e958bd7a5ff5ce1a

Previous baseline:
0220d74149dc9cd6ef0698f478a7ff48294231fa

Commit message:
Add BTC 15m Arena fresh CLOB snapshot

Commit scope:
single_snapshot_artifact_only

## Snapshot artifact

Path:
project_sources/btc-15m-arena/snapshots/clob-book-single-snapshot.btc-updown-15m-1781302500.20260612T222828Z.primary-token.json

SHA256:
6e2a2cd17c218b02b07af29b04fd3282550c31cb3aa637d185ade203130ef5f3

Status:
Tracked in Git and present in the expected commit tree.

Lines added by snapshot commit:
539 insertions

## Captured market context

Slug:
btc-updown-15m-1781302500

Selected outcome:
Up

Token id:
112743633723950476641779511371607306492403155669532548779326573989452112198636

Condition id:
0xfa4a636592a0a99d140f771b7aef39cbe7ec15790e26493c6465ce540a709e7d

Window start UTC:
2026-06-12T22:15:00Z

Window end UTC:
2026-06-12T22:30:00Z

Temporal status at discovery:
IN_WINDOW

## CLOB response

Source:
polymarket_public_clob_book

Endpoint:
https://clob.polymarket.com/book?token_id=112743633723950476641779511371607306492403155669532548779326573989452112198636

HTTP status:
200

Response parse ok:
True

Response body SHA256:
419ba7f3751550b1a91a6780e1ad09960b982b7eb5607b186ba06f405eb3dc6d

Book asset id:
112743633723950476641779511371607306492403155669532548779326573989452112198636

Book market:
0xfa4a636592a0a99d140f771b7aef39cbe7ec15790e26493c6465ce540a709e7d

Minimum order size:
5

Tick size:
0.001

Bid count:
115

Ask count:
2

Raw bids present:
true

Raw asks present:
true

## Request budget recorded inside the snapshot

HTTP request count:
2

Gamma request count:
1

CLOB book request count:
1

Important:
The closeout phase itself made no Polymarket, Gamma or CLOB requests. These counts are historical metadata recorded inside the persisted snapshot artifact.

## Guardrails preserved

The snapshot metadata preserves the following guardrails as true:

- no wallet
- no orders
- no private keys
- no authenticated trading API
- no runtime touch
- no fixture promotion
- no collector
- no bot
- no loop
- no trading automation
- no financial advice

## Files confirmed unchanged during the capture/persistence lane closeout

Contract:
project_sources/btc-15m-arena/BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_CONTRACT_V1.md
SHA256:
73b061f826bea47ed9eea95e65b466bdf04748bed183d9774087c528b33a3abf

Fixture:
btc-15m-arena/fixtures/clob-book-single-snapshot.v1.json
SHA256:
e2cf76b5bc02f1ce057b6819eead13a92e3715de3ade57210d7aee982596e6b2

Route:
btc-15m-arena/index.html
SHA256:
928c983fa8ed52da5621459c251b3ee553e7b30f108587a46717cc4f97a77eef

Scenario JS:
btc-15m-arena/scenario-calculator.js
SHA256:
dc69d19e74adddab136295c5fd82f5d4f3ee1ca54a02169ae75b724ce2bcef93

## What this closes

This closeout closes:

1. Fresh active BTC 15m market/token discovery for a bounded single snapshot.
2. Correct use of CLOB token_id instead of condition_id.
3. Bounded CLOB /book request with status 200.
4. Local snapshot persistence.
5. Path separator normalization issues in validators.
6. PowerShell DateTime normalization issues for UTC window validation.
7. Commit/push of a single historical snapshot artifact.
8. Post-commit review confirming the committed artifact and clean repository state.

## What remains explicitly not done

The following remain not authorized and not performed by this lane:

- fixture promotion
- runtime consumption of the snapshot
- route changes
- scenario calculator changes
- live data integration
- collector loops
- bots
- background polling
- wallet connection
- authenticated trading API
- API keys
- private keys
- create/place/execute order logic
- financial advice
- trading signals
- profit/prediction claims

## Operational prevention rules retained

1. Do not use condition_id as CLOB /book token_id.
2. Do not reuse stale BTC 15m tokens for new live captures without a fresh UTC-bounded discovery phase.
3. Treat PowerShell ConvertFrom-Json ISO timestamps as potentially DateTime objects and normalize them to UTC string format before comparison.
4. Normalize PowerShell paths from backslash to Git slash format before comparing scopes.
5. For untracked artifacts, git diff can be empty. Always inspect:
   - git status --short --untracked-files=all
   - git ls-files --others --exclude-standard
6. A snapshot commit is not fixture promotion.
7. A committed snapshot is not runtime integration.
8. Do not open collector, bot, fixture promotion or runtime integration without a separate precheck.
9. Do not use git add ., git add -A or git commit -am.
10. Stage only explicit paths in future commit phases.
11. If a validation output says Do not commit, the next phase must be review/repair, not commit/push.

## Recommended next phase

BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_BOUNDED_SINGLE_SNAPSHOT_CAPTURE_V2_SNAPSHOT_PERSISTENCE_CLOSEOUT_DOCS_ONLY_COMMIT_PUSH_V1

Purpose:
- validate this docs-only closeout artifact;
- stage only this markdown file;
- commit and push it;
- confirm HEAD/origin sync and clean working tree.

Still not recommended directly:
- fixture promotion
- runtime integration
- collector
- bot
- live data
- wallet/API/order logic