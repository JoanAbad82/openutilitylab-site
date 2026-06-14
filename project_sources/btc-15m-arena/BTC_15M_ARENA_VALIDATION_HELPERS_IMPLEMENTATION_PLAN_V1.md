# BTC 15m Arena - Validation Helpers Implementation Plan V1

Status: docs-only implementation plan.
Phase: BTC_15M_ARENA_VALIDATION_HELPERS_IMPLEMENTATION_PLAN_DOCS_ONLY_V1.
This plan authorizes only planning. It does not authorize helper code implementation.

## 1. Purpose

BTC 15m Arena has accumulated repeated validation friction in PowerShell-driven microphases. The published Validation Helpers Contract V1 defines expected reusable behavior, but no helper code exists yet.

This plan defines the future implementation boundaries for reusable validation helpers before any helper code is created.

The goal is to reduce repeated operational failures around:
- parser continuation prompt `>>`;
- fragile PowerShell paste patterns;
- scalar collapse and `.Count` on PSCustomObject or null values;
- staged versus unstaged git status classification;
- untracked files not appearing in `git diff`;
- `Set-Content` line-ending rewrites;
- literal anchor false negatives;
- contextual guardrail false positives;
- null snippet builders;
- FinalUrl or ResponseUri empty values in public smoke checks.

## 2. Current closed baseline

The current baseline for this plan is:

- branch: main
- HEAD/origin/main: 1277a5d90e34a31833c68d9bf2005b27828b7b95
- last commit subject: Add BTC 15m Arena validation helpers contract
- contract artifact: project_sources/btc-15m-arena/BTC_15M_ARENA_VALIDATION_HELPERS_CONTRACT_V1.md
- contract sha256: b3ed3e9819dff07ca5921b10b86264f3a6a639ab4685dfe580086078cbb31132

The contract is closed and published. This plan is the next docs-only artifact. It does not create helpers yet.

## 3. Scope of this plan

Allowed in this phase:
- create this markdown plan only:
  project_sources/btc-15m-arena/BTC_15M_ARENA_VALIDATION_HELPERS_IMPLEMENTATION_PLAN_V1.md

Not allowed in this phase:
- create scripts/btc-15m-arena/validation-helpers.ps1
- create btc-15m-arena/validation-helpers.js
- edit btc-15m-arena/index.html
- edit btc-15m-arena/scenario-calculator.js
- edit calculator runtime
- edit LiveData docs or code
- edit collector
- edit bot
- edit fixtures
- edit package files
- call Gamma
- call CLOB
- call market data endpoints
- open wallet/API/order logic
- stage, commit, or push

## 4. Recommended future helper language and location

Recommended first helper language:
- PowerShell

Reason:
- the current workflow is executed by the user in PowerShell on Windows;
- the repeated failures are primarily PowerShell/parser/git-output/validator failures;
- a PowerShell helper library can be consumed by future phase runners without adding project runtime.

Recommended future code location, after this plan and a separate code precheck:
- scripts/btc-15m-arena/validation-helpers.ps1

Rejected as first step:
- btc-15m-arena/validation-helpers.js

Reason:
- JS helpers in the public route directory can be confused with runtime or browser code;
- the immediate need is operational validation in local PowerShell phases, not browser behavior.

## 5. Helper set planned for a future implementation phase

The future helper file should expose small reusable helpers. Names are provisional and may be adjusted during implementation precheck.

### 5.1 New-Btc15mValidationResult

Purpose:
- create a predictable result object.

Output fields:
- result
- phase
- mode
- issues
- warnings
- evidence
- flags
- nextRecommendedPhase

Rules:
- issues and warnings must always be arrays;
- evidence must be structured but printable;
- no field may depend on `.Count` of a nullable scalar;
- output must be stable enough for human review and future grep checks.

### 5.2 Get-Btc15mGitScopeSnapshot

Purpose:
- collect branch, HEAD, origin/main, subject, status, cached diff, tracked diff, untracked listing and clean flags.

Must distinguish:
- clean working tree;
- staged/cached diff;
- tracked unstaged diff;
- untracked files;
- staged status like `M  file`;
- unstaged status like ` M file`;
- new untracked status like `?? file`.

Rules:
- never infer untracked files from `git diff`;
- always call `git status --short --untracked-files=all`;
- always call `git ls-files --others --exclude-standard`;
- return arrays even for one item;
- trim empty output safely.

### 5.3 Test-Btc15mExactScope

Purpose:
- validate that the current dirty scope exactly matches allowed paths.

Inputs:
- allowedTrackedPaths
- allowedUntrackedPaths
- allowedCachedPaths
- expectedClean

Rules:
- must block unexpected files;
- must treat untracked files explicitly;
- must support docs-only phases where `git diff` is empty but untracked file exists;
- must not stage or modify anything.

### 5.4 Test-Btc15mCachedDiffScope

Purpose:
- after explicit stage in a future commit phase, validate cached scope only.

Rules:
- validate `git diff --cached --name-only`;
- validate `git diff --cached --stat`;
- validate `git diff --cached --numstat`;
- validate `git diff --cached --check`;
- validate absence of visible `^M` when relevant;
- never allow `git add .`, `git add -A`, or `git commit -am`.

### 5.5 Test-Btc15mAnchorEvidence

Purpose:
- validate required content anchors without relying only on exact literal text.

Anchor classes:
- PRIMARY_BLOCKING_ANCHOR
- SECONDARY_WARN_ANCHOR
- EQUIVALENT_TEXT_ACCEPTED
- FORMAT_COMPATIBILITY_NOTE

Rules:
- primary missing evidence blocks;
- secondary wording mismatch may warn if equivalent evidence exists;
- Markdown inline-code, Unicode punctuation, whitespace and equivalent wording can satisfy evidence when safety concept is present;
- validator output must show missing anchors and accepted equivalents separately.

### 5.6 Classify-Btc15mGuardrailTerm

Purpose:
- classify sensitive terms in route, docs, scripts and public smoke output.

Terms requiring contextual classification:
- wallet
- private keys
- authenticated trading API
- orders
- real orders
- order creation
- order placement
- order execution
- trading automation
- live trading
- live data
- financial advice
- guaranteed profit
- guaranteed prediction
- risk-free
- sure win
- signal
- connect wallet
- place order
- execute order
- createOrder
- placeOrder
- executeOrder
- connectWallet

Allowed classifications:
- NEGATED_GUARDRAIL
- DOCS_GUARDRAIL_TEXT
- FORBIDDEN_EXAMPLE
- WORD_SUBSTRING_FALSE_POSITIVE
- TECHNICAL_REFERENCE_ONLY
- POSITIVE_CAPABILITY
- CTA_OR_INSTRUCTION
- AMBIGUOUS_REQUIRES_REVIEW

Blocking classifications:
- POSITIVE_CAPABILITY
- CTA_OR_INSTRUCTION
- AMBIGUOUS_REQUIRES_REVIEW unless resolved in the same phase.

Non-blocking classifications:
- NEGATED_GUARDRAIL
- DOCS_GUARDRAIL_TEXT
- FORBIDDEN_EXAMPLE
- WORD_SUBSTRING_FALSE_POSITIVE
- TECHNICAL_REFERENCE_ONLY

Examples that must not block:
- No wallet.
- No private keys.
- No authenticated trading API.
- No orders of any kind are created or submitted.
- No real orders.
- No trading automation.
- No live data in this phase.
- Simulation only. Manual inputs. No wallet, no orders, no live data, no financial advice.
- Connect wallet listed only under forbidden examples.
- `let` inside `wallet`.

Examples that must block:
- Connect wallet.
- Place order.
- Execute order.
- Authenticated trading API available.
- Real orders enabled.
- Trading automation supported.
- Live trading mode.
- Guaranteed profit.
- Guaranteed prediction.
- Buy now.
- Sell now.
- Signal.

### 5.7 Get-Btc15mSnippet

Purpose:
- create null-safe snippets around sensitive hits.

Rules:
- never throw on missing term;
- never throw on empty text;
- never rely on object `.Count` without normalizing to array;
- include term, hit index, start, length and snippet;
- snippet must be safe for console output.

### 5.8 Test-Btc15mForbiddenRuntimePatterns

Purpose:
- detect actual runtime/API/trading patterns in target code.

Patterns for JS/runtime:
- fetch(
- XMLHttpRequest
- WebSocket
- EventSource
- localStorage
- privateKey
- apiKey
- createOrder(
- placeOrder(
- executeOrder(
- connectWallet(
- setInterval(
- setTimeout(

Rules:
- in documentation, these may be FORBIDDEN_EXAMPLE and not block;
- in runtime JS, these block unless explicitly authorized by a future phase;
- in public route HTML, wallet/order/trading CTA patterns block.

### 5.9 Test-Btc15mWriteSafety

Purpose:
- prevent accidental line-ending rewrites and encoding drift.

Rules:
- detect original EOL before rewriting tracked text files;
- prefer `[System.IO.File]::WriteAllText()` with `System.Text.UTF8Encoding(false)`;
- avoid `Set-Content` for tracked HTML/XML/MD unless encoding and EOL are controlled;
- validate diff stat, numstat and visible CR markers after write.

### 5.10 Normalize-Btc15mPublicSmokeResponse

Purpose:
- normalize public smoke results from PowerShell.

Rules:
- StatusCode 2xx plus expected content is primary evidence;
- FinalUrl or ResponseUri can be warning if empty;
- do not fail solely because ResponseUri is unavailable in PowerShell 7;
- classify URL mismatch separately from content failure;
- never use `$Home` variable name because it collides with `$HOME`.

### 5.11 New-Btc15mParserSafePhaseTemplate

Purpose:
- define safe PowerShell phase-runner patterns.

Rules:
- avoid long interactive functions pasted directly in console;
- avoid here-strings in pasted console blocks;
- avoid `@(` inline literals in pasted console blocks;
- avoid unnecessary `$()` subexpressions;
- avoid monolithic validators that repair, validate, stage and push in one block;
- if a large phase is needed, prefer a downloaded `.ps1` runner or short encoded command;
- if prompt `>>` appears, stop with Ctrl+C and do not continue manually.

## 6. Result contract for future helpers

Every future helper-driven phase should print a final section with:

- RESULT=PASS or RESULT=NO_PASS
- MODE=<phase mode>
- WRITE_EXECUTED=<true|false>
- STAGE_EXECUTED=<true|false>
- COMMIT_CREATED=<true|false>
- PUSH_EXECUTED=<true|false>
- FINAL_WORKING_TREE_CLEAN=<true|false>
- RUNTIME_TOUCHED=<true|false>
- CALCULATOR_TOUCHED=<true|false>
- LIVE_DATA_OPENED=<true|false>
- COLLECTOR_OPENED=<true|false>
- BOT_OPENED=<true|false>
- FIXTURES_OPENED=<true|false>
- WALLET_API_ORDER_LOGIC_OPENED=<true|false>
- MARKET_DATA_HTTP_REQUEST_COUNT=<number>
- GAMMA_REQUEST_COUNT=<number>
- CLOB_BOOK_REQUEST_COUNT=<number>
- NEXT_RECOMMENDED_PHASE=<phase name>

For docs-only local creation phases, acceptable final result:
- RESULT=PASS
- DOCS_ONLY_ARTIFACT_CREATED=true
- STAGE_EXECUTED=false
- COMMIT_CREATED=false
- PUSH_EXECUTED=false

## 7. Implementation sequence after this plan

The next steps must remain separate:

1. Commit/push this plan docs-only if local creation passes.
2. Post-commit review of this plan.
3. Open helper-code precheck read-only.
4. Create `scripts/btc-15m-arena/validation-helpers.ps1` in a local implementation phase.
5. Review output.
6. Commit/push helper code in a separate phase.
7. Only then begin migrating future phase runners to consume the helper library.

No step above authorizes LiveData, collector, bot, fixtures, wallet/API/order logic, trading automation or real order flow.

## 8. Acceptance criteria for this docs-only plan phase

This phase passes only if:
- baseline HEAD and origin/main match 1277a5d90e34a31833c68d9bf2005b27828b7b95;
- working tree is clean before writing;
- contract exists and hash matches expected sha256;
- target plan does not already exist;
- exactly one untracked file is created:
  project_sources/btc-15m-arena/BTC_15M_ARENA_VALIDATION_HELPERS_IMPLEMENTATION_PLAN_V1.md;
- no tracked files are modified;
- no cached/staged diff exists;
- no helper code file is created;
- no runtime/product/trading file is touched;
- no network requests are made;
- no stage, commit or push is executed.

## 9. Explicit non-goals

This plan does not:
- implement helper functions;
- create a PowerShell module;
- create browser/runtime JS;
- modify the BTC Arena calculator;
- modify fixtures;
- open LiveData;
- open collector;
- open bot;
- add wallet support;
- add API keys;
- add authenticated trading API;
- place or cancel orders;
- provide trading advice;
- provide real-time signals.

## 10. Next recommended phase

After local creation and validation of this docs-only plan:

BTC_15M_ARENA_VALIDATION_HELPERS_IMPLEMENTATION_PLAN_DOCS_ONLY_COMMIT_PUSH_V1

That future phase should:
- validate the plan as the only untracked file;
- stage explicitly only this plan;
- commit with a clear docs-only message;
- push to origin/main;
- confirm HEAD equals origin/main;
- confirm the working tree is clean.
