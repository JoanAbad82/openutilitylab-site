# BTC 15m Arena - Live Data Read-Only Endpoint Request Budget Contract V1

Status: docs-only endpoint/request-budget contract. No requests are executed in this phase.

Phase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_ENDPOINT_REQUEST_BUDGET_CONTRACT_DOCS_ONLY_V2_SENSITIVE_CONTEXT_REPAIR

Baseline:
- branch: main
- baseline commit: 0f54049f0966a277459537a67d8a99d97023e62a
- historical commit subject only: "Add BTC 15m Arena live data boundary closure"; this is not an authorization for live data runtime.

Source boundary artifacts:
- boundary contract: project_sources/btc-15m-arena/BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDARY_CONTRACT_AND_HELPER_ADOPTION_V1.md
- boundary contract sha256: 7dc3db317ffdc1f275989acb09ee71fac10b94464dc2d4b6fae72cdc44ef18b2
- closure document: project_sources/btc-15m-arena/BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDARY_CONTRACT_CLOSURE_V1.md
- closure sha256: bd1ab7bdbf95f6d0322982369b060d3e61203f24d72efa210d9e5ca4909c9576

## 1. Contract purpose

This contract formalizes a future request-budget plan before any future request.

This contract is documentation only.

This contract is not a probe.

This contract is not a runtime.

This contract is not an implementation.

The current phase request budget is zero.

## 2. Explicit current-phase non-authorizations

No endpoint probes are authorized in this phase.

No market-data HTTP requests are authorized in this phase.

No Gamma requests are authorized in this phase.

No CLOB book requests are authorized in this phase.

No runtime LiveData is authorized in this phase.

No live data runtime is authorized in this phase.

No collectors are authorized in this phase.

No bots are authorized in this phase.

No fixtures are authorized in this phase.

No fixture promotion is authorized in this phase.

No Polymarket integration is authorized in this phase.

No wallet integration is authorized in this phase.

No wallet/API/order logic is authorized in this phase.

No private keys are authorized in this phase.

No API keys are authorized in this phase.

No authenticated trading API is authorized in this phase.

No order creation is authorized in this phase.

No order placement is authorized in this phase.

No order submission is authorized in this phase.

No order execution is authorized in this phase.

No orders of any kind are created or submitted in this phase.

No trading automation is authorized in this phase.

No live trading is authorized in this phase.

No trading advice or financial advice is authorized in this phase.

No profit claims are authorized in this phase.

No guaranteed profit is authorized in this phase.

No guaranteed prediction is authorized in this phase.

## 3. Current-phase request budget

PLAN_STATUS: TEXTUAL_PLAN_ONLY_NO_REQUESTS

PLAN_CURRENT_PHASE_REQUEST_BUDGET_TOTAL: 0

PLAN_CURRENT_PHASE_MARKET_DATA_HTTP_REQUEST_COUNT: 0

PLAN_CURRENT_PHASE_GAMMA_REQUEST_COUNT: 0

PLAN_CURRENT_PHASE_CLOB_BOOK_REQUEST_COUNT: 0

PLAN_CURRENT_PHASE_ENDPOINT_PROBE_EXECUTED: false

## 4. Candidate endpoint family 1 - Gamma public event or market resolution

candidate_family_1: Gamma public event_or_market resolution by deterministic BTC 15m slug

Purpose:
Future candidate only; no Gamma requests are authorized or executed in this phase. A later separately authorized phase may use a bounded slug window to resolve a current or future BTC 15m event, market, outcomes, condition id, and clob token ids.

Future request-budget candidate:
Future candidate only; no Gamma requests are authorized or executed in this phase. Candidate maximum for a later separately authorized phase: 7 Gamma public GET requests.

Auth:
none.

Write behavior:
none.

Storage behavior:
No fixture, no snapshot, and no descriptor are authorized in this phase. A later phase must explicitly authorize any storage behavior.

Important limit:
No Gamma request budget is executed by this contract. This contract only documents a candidate budget for a future phase.

## 5. Candidate endpoint family 2 - CLOB public book lookup

candidate_family_2: CLOB public book lookup by resolved token id

Purpose:
Future candidate only; no CLOB book requests are authorized or executed in this phase. A later separately authorized phase may read top-of-book/depth for one validated token only after target resolution uniquely resolves a token id.

Future request-budget candidate:
Future candidate only; no CLOB book requests are authorized or executed in this phase. Candidate maximum for a later separately authorized first probe: 1 CLOB book GET for one token after unique target resolution.

Dual-token budget:
Future candidate only; no dual-token CLOB requests are authorized in this phase. Dual-token lookup requires a separate later authorization.

Auth:
none.

Write behavior:
none.

Storage behavior:
No snapshot and no fixture are authorized in this phase. A later phase must explicitly authorize any storage behavior.

Important limit:
No CLOB request budget is executed by this contract. This contract only documents a candidate budget for a future phase.

## 6. Candidate endpoint family 3 - Public page or route smoke

candidate_family_3: Public page/route smoke if needed

Purpose:
Future candidate only; no market-data HTTP requests are authorized in this phase. A later separately authorized phase may validate public Open Utility Lab surfaces only.

Future request-budget candidate:
Future candidate only; no public smoke requests are authorized or executed in this phase. Candidate maximum for a later separately authorized phase: 3 HTTP GET requests to canonical public Open Utility Lab surfaces.

Auth:
none.

Important limit:
No market-data requests are authorized by this candidate family.

## 7. Future bounded probe candidate

future_phase_minimum_name_candidate:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_ENDPOINT_PROBE_PRECHECK_NO_WRITE_V1

future_phase_gamma_budget_candidate:
Future candidate only; no Gamma requests are authorized or executed in this phase. Candidate maximum for a later separately authorized phase: 7.

future_phase_clob_budget_candidate:
Future candidate only; no CLOB book requests are authorized or executed in this phase. Candidate maximum before unique target resolution: 0.

future_phase_first_clob_budget_after_resolution_candidate:
Future candidate only; no CLOB book requests are authorized or executed in this phase. Candidate maximum for a later separately authorized phase after unique token resolution: 1.

future_phase_dual_token_budget_candidate:
Future candidate only; no dual-token CLOB requests are authorized in this phase. Separate authorization required.

future_phase_timeout_candidate_seconds:
10.

future_phase_retry_candidate:
0 retries unless separately authorized.

future_phase_auth_candidate:
none.

future_phase_headers_candidate:
No private headers, no Poly API auth, and no secrets are authorized in this phase.

future_phase_write_candidate:
No writes are authorized in this phase. A later phase must explicitly authorize any descriptor or snapshot artifact.

future_phase_loop_candidate:
No loops, no collector, no bot, and no polling are authorized in this phase.

## 8. Target resolution requirements before any future CLOB request

A future phase must satisfy all of the following before any later separately authorized CLOB request:

1. deterministic slug window calculated locally;
2. exactly one current or future usable Gamma market candidate;
3. active market status or explicit state classification;
4. valid condition id if present;
5. valid outcome names;
6. valid clob token ids;
7. explicit token side selection before CLOB;
8. no stale historical target reused as current target;
9. no request exceeds declared budget;
10. no wallet, API, or order fields involved.

## 9. Abort conditions for a future request phase

Abort if the working tree is not clean.

Abort if HEAD and origin/main are not synchronized.

Abort if boundary contract hash mismatch occurs.

Abort if closure document hash mismatch occurs.

Abort if endpoint/request-budget contract hash mismatch occurs after publication.

Abort if current surface contains fetch/API/wallet/order runtime; no wallet/API/order runtime is authorized.

Abort if any request would require auth, private key, API key, wallet, or trading API; no such requirement is authorized.

Abort if request budget is not explicit.

Abort if endpoint family is not listed before execution.

Abort if more than one usable market candidate exists without disambiguation.

Abort if no validated clob token id exists before CLOB.

Abort if any write, snapshot, fixture, or descriptor is requested; no fixture or descriptor write is authorized in this phase.

Abort if any collector is requested; no collector is authorized.

Abort if any bot is requested; no bot is authorized.

Abort if any polling, retry storm, loop, or background task is requested; no polling, loop, or background task is authorized.

## 10. Evidence required for a future probe

A future request phase must report:

- request count by endpoint family;
- exact requested URLs with secrets redacted if any, although secrets are not expected;
- status codes;
- response shape summary;
- target candidate count;
- clob token id validation;
- budget consumed versus budget allowed;
- no writes, no stage, no commit, and no push unless separately authorized.

## 11. Surface and product guardrails

BTC 15m Arena remains a simulation-only, paper-research, manual/static product surface.

Allowed language:
- simulation-only;
- read-only;
- paper research;
- decision training;
- execution-risk awareness;
- request budget required before any future request.

Forbidden example only: "guaranteed profit"; this wording is not authorized.

Forbidden example only: "guaranteed prediction"; this wording is not authorized.

Forbidden example only: "risk-free"; this wording is not authorized.

Forbidden example only: "sure win"; this wording is not authorized.

Forbidden example only: "signal"; this wording is not authorized.

Forbidden example only: "buy now"; this wording is not authorized.

Forbidden example only: "sell now"; this wording is not authorized.

Forbidden example only: "trade now"; this wording is not authorized.

Forbidden example only: "connect wallet"; this wording is not authorized.

Forbidden example only: "place order"; this wording is not authorized.

Forbidden example only: "execute order"; this wording is not authorized.

Forbidden example only: "trading automation supported"; this wording is not authorized.

Forbidden example only: "live trading mode"; this wording is not authorized.

Forbidden example only: "authenticated trading API available"; this wording is not authorized.

## 12. What this contract permits

This contract permits only documentation of a future endpoint/request-budget plan.

This contract permits a later review and commit/push of this document if validation passes.

This contract permits a later separately authorized read-only precheck phase to decide whether a bounded endpoint probe should be opened.

## 13. What this contract does not authorize

No endpoint probes are authorized by this contract.

No market-data HTTP requests are authorized by this contract.

No Gamma requests are authorized by this contract.

No CLOB book requests are authorized by this contract.

No live data runtime is authorized by this contract.

No collectors are authorized by this contract.

No bots are authorized by this contract.

No fixtures are authorized by this contract.

No fixture promotion is authorized by this contract.

No Polymarket integration is authorized by this contract.

No wallet/API/order logic is authorized by this contract.

No trading advice or financial advice is authorized by this contract.

## 14. Review criteria for this docs-only phase

This docs-only phase can pass locally only if:

- branch is main;
- HEAD equals origin/main;
- HEAD equals 0f54049f0966a277459537a67d8a99d97023e62a;
- working tree before repair contains only the expected untracked contract file;
- boundary contract hash matches expected value;
- closure document hash matches expected value;
- helper hash matches expected value;
- only this markdown file is rewritten;
- no route, calculator, helper, contract, home, sitemap, CSS, package, script, source, dist, or other product file is modified;
- no stage is executed;
- no commit is created;
- no push is executed;
- no endpoint probe is executed;
- no market-data request is executed;
- no Gamma request is executed;
- no CLOB book request is executed;
- no runtime LiveData is opened.

## 15. Next phase

If this local docs-only repair passes validation, the recommended next phase is:

BTC_15M_ARENA_LIVE_DATA_READ_ONLY_ENDPOINT_REQUEST_BUDGET_CONTRACT_DOCS_ONLY_V2_REPAIR_REVIEW_V1

That next phase must remain read-only unless a later commit/push phase is explicitly opened.