# BTC 15m Arena - Live Data Read-Only Boundary Contract and Validation Helper Adoption V1

Status: docs-only boundary contract. No runtime implementation in this phase.

Date: 2026-06-15.

Repository:
- C:\openutilitylab-site

Baseline commit:
- ebe45f1de2ee323b567d4bc9ca2c5f2cb460f564
- Add BTC 15m Arena validation helpers

## 1. Purpose

This document defines the LiveData boundary for BTC 15m Arena before any market-data request is authorized.

The purpose is to separate:
- documentation and boundary design;
- future bounded public market-data read-only checks;
- fixture history;
- runtime implementation;
- collector behavior;
- bot behavior;
- wallet, authenticated API, or order logic.

This contract is intentionally conservative. It does not authorize a request, capture, collector, bot, runtime LiveData, fixture promotion, wallet integration, API-key usage, or order logic.

## 2. Status of this phase

This phase is docs-only.

Allowed in this phase:
- create this boundary contract;
- define candidate endpoint families without calling them;
- define future request budget requirements;
- define future timeout requirements;
- define future response schema expectations;
- define helper adoption requirements;
- define guardrail classification requirements.

Not allowed in this phase:
- no market-data HTTP request;
- no Gamma request;
- no CLOB book request;
- no public API probe;
- no bounded single snapshot;
- no capture;
- no fixture creation;
- no fixture promotion;
- no replay loader;
- no runtime LiveData;
- no repeated loop;
- no collector;
- no bot;
- no wallet;
- no private keys;
- no API keys;
- no authenticated trading API;
- no order creation;
- no order placement;
- no order submission;
- no order execution;
- no trading automation;
- no live trading;
- no financial advice;
- no profit claims;
- no guaranteed prediction;
- no real-time trading signal.

## 3. Current safe baseline

The current product baseline remains:
- static calculator;
- simulation-only;
- manual inputs;
- deterministic local fixture capability already separated from LiveData;
- no wallet;
- no authenticated trading API;
- no real orders;
- no runtime LiveData;
- no collector;
- no bot.

The current public route already contains negative guardrails such as:
- No wallet.
- No authenticated trading API.
- No real orders.
- No trading automation in this shell.
- No live data in this route shell.
- No financial advice.

These are valid negative guardrails, not positive capabilities.

## 4. Candidate endpoint families for future phases

This contract may name candidate endpoint families, but it does not call them.

Candidate family A - Gamma market discovery:
- Purpose: discover or classify public BTC 15m market metadata.
- Future use, if separately authorized: bounded read-only market/event/token discovery.
- This contract does not authorize any Gamma request.

Candidate family B - CLOB book read:
- Purpose: inspect public order-book depth for a resolved token.
- Future use, if separately authorized: bounded single read-only book request.
- This contract does not authorize any CLOB request.

Candidate family C - public reference pages or static metadata:
- Purpose: cross-check labels, market identity, or contract assumptions.
- Future use, if separately authorized: read-only metadata validation.
- This contract does not authorize browsing or scraping.

Endpoint URLs, methods, query parameters, and request bodies must be revalidated in a future pre-request phase before any call.

## 5. Request budget required before any future request

Before any future phase can execute a real request, that phase must define:
- exact endpoint family;
- exact URL or URL construction rule;
- HTTP method;
- maximum request count;
- timeout seconds;
- retry policy;
- no retry loop;
- no scheduler;
- no persistence unless separately authorized;
- expected response status;
- expected response schema;
- acceptable error classes;
- abort conditions;
- evidence to print in output;
- final request count.

Default future budget until changed by explicit phase:
- Gamma requests: 0
- CLOB book requests: 0
- market-data HTTP requests: 0

A future bounded request phase may only override this after a separate precheck and explicit authorization.

## 6. Timeout and retry policy

No request is authorized by this document.

Future request phases must use bounded timeouts and no unbounded retries.

Required future constraints:
- timeout must be explicit;
- retries must be zero or explicitly bounded;
- no background loop;
- no scheduler;
- no polling;
- no collector behavior;
- no live trading or signal loop.

## 7. Response schema expectations for future phases

Future phases must define response schema before consuming data.

Minimum schema expectations for a future public market metadata response:
- source family;
- requested URL or descriptor;
- request timestamp;
- response status;
- parsed identity fields;
- relevant market or token fields;
- explicit unknown/null handling;
- no wallet fields;
- no private key fields;
- no authenticated account fields;
- no order fields.

Minimum schema expectations for a future public CLOB book response:
- source family;
- token_id or equivalent public identifier;
- bids collection if present;
- asks collection if present;
- best bid if derivable;
- best ask if derivable;
- spread if derivable;
- depth/size fields if present;
- parse warnings if shape differs;
- no order creation;
- no order submission;
- no trading instruction.

## 8. Validation helper adoption

Future validators should adopt the existing BTC 15m namespaced helper API.

Required helper functions:
- Normalize-Btc15mArray
- Get-Btc15mSafeCount
- New-Btc15mValidationResult
- Get-Btc15mSnippet
- Classify-Btc15mGuardrailTerm
- Get-Btc15mGitScopeSnapshot
- Test-Btc15mExactScope
- Test-Btc15mAnchorEvidence
- Normalize-Btc15mPublicSmokeResponse
- New-Btc15mParserSafePhaseTemplate

Do not require obsolete generic helper names such as:
- Normalize-Array
- Get-SafeCount
- Test-GitClean
- Test-ExpectedBranch
- Test-HeadOriginSync

Validator rule:
- helper namespaced functions are the canonical helper contract for BTC 15m Arena phases.

## 9. Guardrail classification rules

Sensitive terms must be classified by context, not by literal presence only.

Allowed negative guardrails:
- No wallet.
- No private keys.
- No authenticated trading API.
- No real orders.
- No order creation.
- No order placement.
- No order submission.
- No order execution.
- No trading automation.
- No live trading.
- No runtime LiveData.
- No collector.
- No bot.
- No financial advice.
- No profit claims.
- No guaranteed prediction.

Blocking positive capabilities:
- authenticated trading API available;
- connect wallet;
- place order;
- execute order;
- real orders enabled;
- trading automation supported;
- live trading mode;
- live data runtime active;
- guaranteed profit;
- guaranteed prediction;
- risk-free profit;
- sure-win strategy;
- auto hedge;
- auto arbitrage.

Each sensitive hit must print a snippet and classification:
- NEGATED_GUARDRAIL
- POSITIVE_CAPABILITY_OR_CLAIM
- AMBIGUOUS_REQUIRES_REVIEW

Only NEGATED_GUARDRAIL may pass automatically.

## 10. Historical documents are not authorization

Existing documents may contain LiveData, Gamma, CLOB, snapshot, fixture, collector, bot, or order vocabulary.

This does not authorize reopening historical scripts or flows.

Future phases must distinguish:
- historical reference;
- active contract;
- blocked runtime;
- blocked collector;
- blocked bot;
- blocked wallet/API/order logic.

## 11. Component boundary matrix

endpoint_discovery:
- status: docs-only boundary allowed now;
- future request requires separate bounded pre-request phase.

single_snapshot:
- status: blocked now;
- future snapshot requires separate authorization and request budget.

fixture_promotion:
- status: blocked now;
- reason: fixture promotion must not be mixed with LiveData boundary.

replay:
- status: historical/static only;
- reason: no live replay loader is authorized by this contract.

collector:
- status: blocked;
- reason: no loop, scheduler, repeated capture, persistence, or background process.

bot:
- status: blocked;
- reason: no strategy execution, automation, or live signal loop.

runtime_livedata:
- status: blocked;
- reason: this contract is not a runtime implementation.

wallet_api_orders:
- status: blocked;
- reason: no wallet, API keys, authenticated trading API, order creation, submission, or execution.

validation_helper_adoption:
- status: allowed for future validators;
- reason: helper may be referenced by future phase scripts and validators.

## 12. Allowed next phase after this contract

The next immediate phase after this local docs-only contract should be read-only review of this contract.

Recommended next phase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDARY_CONTRACT_AND_HELPER_ADOPTION_DOCS_ONLY_REVIEW_V1

That review must validate:
- target file exists;
- target file is untracked or modified exactly as expected;
- no staged changes;
- no tracked runtime diff;
- no route changes;
- no calculator changes;
- no helper rewrite;
- no request count;
- no Gamma request;
- no CLOB request;
- no market-data HTTP request;
- required anchors present;
- positive capability claims absent as active capabilities;
- guardrails are contextually negative;
- final git state matches docs-only local write.

Commit/push must be a later separate microfase if review passes.

## 13. Explicit non-authorization statement

This contract does not authorize:
- market-data HTTP request;
- Gamma request;
- CLOB book request;
- endpoint probe;
- snapshot capture;
- fixture creation;
- fixture promotion;
- replay loader;
- runtime LiveData;
- repeated loop;
- collector;
- bot;
- strategy automation;
- wallet;
- private keys;
- API keys;
- authenticated trading API;
- order creation;
- order placement;
- order submission;
- order execution;
- financial advice;
- profit guarantee;
- prediction guarantee.

## 14. Closure criteria for this docs-only phase

This phase can pass only if:
- exactly one docs-only file is created;
- no files are staged;
- no commit is created;
- no push is executed;
- no request is executed;
- no runtime file is modified;
- no route file is modified;
- no calculator file is modified;
- no helper file is modified;
- no fixture file is modified;
- target markdown is LF-only;
- target markdown has no CR characters;
- target markdown contains required guardrails;
- final git status shows only the expected docs-only target.
