# BTC 15m Arena - Live Data Read-Only Bounded Endpoint Probe Contract V1

Status: docs-only bounded endpoint probe contract. No requests are executed in this phase.

Repair microphase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_ENDPOINT_PROBE_CONTRACT_DOCS_ONLY_V2_SENSITIVE_CONTEXT_REPAIR

Original creation microphase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_ENDPOINT_PROBE_CONTRACT_DOCS_ONLY_V1

Baseline:
- expected branch: main
- expected HEAD: 9a0450cebc97ce5744659a18f81c77a5eae1e2f5
- expected origin/main: 9a0450cebc97ce5744659a18f81c77a5eae1e2f5
- expected subject: Add BTC 15m Arena endpoint request budget contract
- source contract: project_sources/btc-15m-arena/BTC_15M_ARENA_LIVE_DATA_READ_ONLY_ENDPOINT_REQUEST_BUDGET_CONTRACT_V1.md
- source contract sha256: 491dc79298b65dd9c9b0652fbcff4bdd29de2e0d9ad5fe009882559da1b3279d

Contract purpose:
This document defines a future bounded probe contract boundary only. It does not perform the future probe. It does not authorize a direct probe without a later explicitly approved execution phase.

Current phase request counters:
- CURRENT_PHASE_ENDPOINT_PROBE_EXECUTED: false
- CURRENT_PHASE_MARKET_DATA_HTTP_REQUEST_COUNT: 0
- CURRENT_PHASE_GAMMA_REQUEST_COUNT: 0
- CURRENT_PHASE_CLOB_BOOK_REQUEST_COUNT: 0
- CURRENT_PHASE_PUBLIC_SMOKE_REQUEST_COUNT: 0
- CURRENT_PHASE_TOTAL_REQUEST_COUNT: 0

Future candidate request budget:
- future candidate only; Gamma public event-or-market resolution maximum: 7 requests.
- future candidate only; CLOB public book lookup maximum: 1 request after unique token resolution.
- future candidate only; public page or route smoke maximum: 3 requests if needed.
- future candidate only; total maximum for a later separately authorized bounded probe: 11 requests.
- no future candidate request is executed by this contract phase.
- no market-data HTTP request is executed by this contract phase.
- no Gamma request is executed by this contract phase.
- no CLOB book request is executed by this contract phase.

Candidate endpoint families:
1. Gamma public event-or-market resolution by deterministic BTC 15m slug.
2. CLOB public book lookup by resolved token id.
3. Public page or route smoke if needed.

Candidate timeout and retry:
- timeout candidate per future request: 10 seconds.
- retry candidate: 0.
- no polling is authorized.
- no background task is authorized.
- no loop is authorized.

Target resolution requirements:
- target resolution must be deterministic from a BTC 15m slug or equivalent public unauthenticated identifier.
- CLOB book lookup must not occur unless a single token id is uniquely resolved first.
- no dual-token CLOB lookup is authorized by this contract.
- no snapshot capture is authorized by this contract.
- no fixture creation is authorized by this contract.

Abort conditions:
1. Abort if auth, wallet, API key, private key, account state, or order action is required.
2. Abort if target resolution is not unique before any CLOB book lookup.
3. Abort if any endpoint would require POST, signature, WebSocket, stream, loop, polling, or background task.
4. Abort if response evidence cannot be recorded without storing private, user, or account data.
5. Abort if any order creation, order placement, order submission, or order execution is requested.
6. Abort if any wallet, private key, API key, authenticated trading API, or account state is requested.

Evidence requirements for a later separately authorized probe:
1. HTTP status for each future request.
2. Public unauthenticated resolved slug, event, market, condition, and token identifiers only when available.
3. Request count by endpoint family.
4. Evidence must include explicit ZERO flags confirming no wallet, no auth, no orders, no runtime, no collector, and no bot.
5. A later separate PASS or NO_PASS decision is required before any storage; no fixture promotion, no collector, no bot, and no runtime phase are authorized by this contract.

Explicit non-authorizations:
- No endpoint probe is authorized in this phase.
- No market-data HTTP request is authorized in this phase.
- No Gamma request is authorized in this phase.
- No CLOB book request is authorized in this phase.
- No public smoke request is authorized in this phase.
- No runtime LiveData is authorized in this phase.
- No live data runtime is authorized in this phase.
- No collector is authorized in this phase.
- No bot is authorized in this phase.
- No fixture is authorized in this phase.
- No fixture promotion is authorized in this phase.
- No snapshot capture is authorized in this phase.
- No descriptor write is authorized in this phase.
- No Polymarket integration is authorized in this phase.
- No wallet integration is authorized in this phase.
- No wallet API order logic is authorized in this phase.
- No private keys are authorized in this phase.
- No API keys are authorized in this phase.
- No authenticated trading API is authorized in this phase.
- No order creation is authorized in this phase.
- No order placement is authorized in this phase.
- No order submission is authorized in this phase.
- No order execution is authorized in this phase.
- No orders of any kind are created or submitted in this phase.
- No trading automation is authorized in this phase.
- No live trading is authorized in this phase.
- No trading advice or financial advice is authorized in this phase.
- No profit claims are authorized in this phase.
- No guaranteed profit is authorized in this phase.
- No guaranteed prediction is authorized in this phase.
- No wallet, no collector, no bot, no fixture, no fixture promotion, and no runtime phase are authorized by this contract.

Forbidden direct next steps:
- Direct Gamma public GET without a later separately authorized execution phase is not authorized.
- Direct CLOB book GET without a later separately authorized execution phase is not authorized.
- Direct endpoint probe without a later separately authorized execution phase is not authorized.
- Direct snapshot capture without a later separately authorized phase is not authorized.
- Direct fixture creation without a later separately authorized phase is not authorized.
- Direct runtime LiveData, collector, or bot without a later separately authorized phase is not authorized.

Contract decision:
If this repaired contract is reviewed with zero issues, the next safe phase is a read-only review of this contract before any commit or later execution decision.

Next recommended phase:
BTC_15M_ARENA_LIVE_DATA_READ_ONLY_BOUNDED_ENDPOINT_PROBE_CONTRACT_DOCS_ONLY_V2_REPAIR_REVIEW_V1

Final boundary:
This contract is not a probe. This contract is not a request. This contract is not runtime. This contract is only a docs-only boundary for a possible future bounded probe.
