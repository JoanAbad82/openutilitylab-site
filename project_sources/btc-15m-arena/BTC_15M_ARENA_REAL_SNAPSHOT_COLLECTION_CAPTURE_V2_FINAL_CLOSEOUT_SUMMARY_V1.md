# BTC 15m Arena — Real Snapshot Collection Capture V2 Final Closeout Summary V1

Date: 2026-06-13

Phase:
BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_CAPTURE_V2_FINAL_CLOSEOUT_SUMMARY_DOCS_ONLY_V2_ABSOLUTE_PATH_WRITE_REPAIR

Mode:
Docs-only final summary.

## Decision

PASS_SNAPSHOT_AND_CLOSEOUT_REPO_STATE_CONFIRMED

This document summarizes the final state after the Capture V2 real CLOB book snapshot persistence lane.

## Confirmed commits

Final HEAD / origin/main:
28028e855e9fba6574b86d85ec00ba27e2006fa4

Snapshot commit:
9770c232fd70ef835fdd1976e958bd7a5ff5ce1a

Snapshot commit parent:
0220d74149dc9cd6ef0698f478a7ff48294231fa

Latest closeout commit:
28028e855e9fba6574b86d85ec00ba27e2006fa4

## Confirmed artifacts

Snapshot artifact:
project_sources/btc-15m-arena/snapshots/clob-book-single-snapshot.btc-updown-15m-1781302500.20260612T222828Z.primary-token.json

Snapshot SHA256:
6e2a2cd17c218b02b07af29b04fd3282550c31cb3aa637d185ade203130ef5f3

Closeout artifact:
project_sources/btc-15m-arena/BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_CAPTURE_V2_SNAPSHOT_PERSISTENCE_CLOSEOUT_V1.md

Closeout SHA256:
fe31f88ed21126712c753608f8b060095408809da53f1e2386b999f1bfc719ff

## Snapshot identity

Source:
polymarket_public_clob_book

Slug:
btc-updown-15m-1781302500

Token ID:
112743633723950476641779511371607306492403155669532548779326573989452112198636

Condition ID:
0xfa4a636592a0a99d140f771b7aef39cbe7ec15790e26493c6465ce540a709e7d

Response status:
200

Parse status:
true

Temporal status at discovery:
IN_WINDOW

Derived window start UTC:
2026-06-12T22:15:00Z

Derived window end UTC:
2026-06-12T22:30:00Z

## Final repo-state review result

The final repo-state review V6 passed.

Confirmed repairs:
- explicit Git range construction using `${ExpectedSnapshotCommitParent}..HEAD`;
- safe line-by-line `git diff --name-status` parsing;
- safe line-by-line `git diff --numstat` parsing;
- schema-aware temporal validation using existing fields and slug-derived time window;
- classification of absent literal normalized temporal fields as notes, not blockers.

Confirmed final range:
0220d74149dc9cd6ef0698f478a7ff48294231fa..HEAD

Confirmed range scope:
- project_sources/btc-15m-arena/snapshots/clob-book-single-snapshot.btc-updown-15m-1781302500.20260612T222828Z.primary-token.json
- project_sources/btc-15m-arena/BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_CAPTURE_V2_SNAPSHOT_PERSISTENCE_CLOSEOUT_V1.md

Confirmed range numstat:
- snapshot artifact: 539 insertions, 0 deletions
- closeout artifact: 226 insertions, 0 deletions

## Absolute path write repair

The previous local final-summary docs-only attempt failed because `[System.IO.File]::WriteAllText()` received a relative target path and resolved it against the .NET process directory instead of the repository root.

This repaired phase writes the summary artifact with an absolute path under:
C:\openutilitylab-site

Prevention:
- Build target paths with `Join-Path $RepoRoot ...`.
- Use the absolute path for `WriteAllText`, `ReadAllText`, `Get-Item` and `Get-FileHash`.
- Continue comparing Git scope with normalized repository-relative paths.

## Explicit non-goals and non-events

No fixture promotion occurred.

No runtime integration occurred.

No route was modified in this lane.

No home or sitemap change occurred in this lane.

No wallet was introduced.

No private key handling was introduced.

No authenticated trading API was introduced.

No order creation, placement or execution was introduced.

No trading automation was introduced.

No collector, bot, polling loop or background live-data process was introduced.

No financial advice, prediction claim, guaranteed profit claim or real-time signal was introduced.

## Guardrails preserved

- No wallet.
- No private keys.
- No authenticated trading API.
- No real orders.
- No trading automation.
- No live trading.
- No financial advice.
- No guaranteed profit.
- No guaranteed prediction.
- Public read-only CLOB book snapshot only inside bounded capture phases.
- Snapshot persistence is not fixture promotion.
- Snapshot persistence is not runtime integration.

## Prevention rules retained

Do not use `condition_id` as CLOB `/book` `token_id`.

Do not reuse stale BTC 15m token IDs for fresh live capture without a fresh UTC validation.

Do not build Git ranges as `$ExpectedSnapshotCommitParent..HEAD` in PowerShell. Use `"${ExpectedSnapshotCommitParent}..HEAD"` or `"$($ExpectedSnapshotCommitParent)..HEAD"`.

Do not validate `git diff --name-status` by regex over a joined text block. Parse line by line as status/path.

Do not validate `git diff --numstat` by regex over a joined text block. Parse line by line as insertions/deletions/path.

Do not use relative filesystem paths with `[System.IO.File]::WriteAllText()` or `[System.IO.File]::ReadAllText()` in repo scripts. Use absolute paths rooted at `$RepoRoot`.

Do not treat absent literal fields such as `window_start_utc_normalized`, `window_end_utc_normalized` or `temporal_status` as blockers when the schema provides existing temporal fields and the slug-derived window is validated.

Do not classify guardrail phrases as positive capabilities:
- No trading automation.
- No real orders.
- No wallet.
- No orders.
- No authenticated trading API.

For new untracked files, do not rely on `git diff` alone. Use:
- `git status --short --untracked-files=all`
- `git ls-files --others --exclude-standard`

Do not use:
- `git add .`
- `git add -A`
- `git commit -am`

Use explicit file staging only in commit phases.

## Final status of this lane

Capture V2 real snapshot persistence is closed at repo-state level.

This summary is docs-only and does not authorize fixture promotion, runtime integration, collector/bot creation, wallet/API/order logic, or live-data automation.

## Next recommended phase

BTC_15M_ARENA_REAL_SNAPSHOT_COLLECTION_CAPTURE_V2_FINAL_CLOSEOUT_SUMMARY_DOCS_ONLY_COMMIT_PUSH_V1

Purpose:
- validate this summary artifact as the only untracked file;
- stage only this summary artifact;
- commit;
- push;
- confirm HEAD = origin/main;
- confirm working tree clean.

Still not authorized:
- fixture promotion;
- runtime integration;
- route changes;
- live collector;
- bot;
- wallet/API/order logic;
- trading automation.